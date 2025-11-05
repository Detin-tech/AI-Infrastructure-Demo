from fastapi import FastAPI, HTTPException, Header
import torch
from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
import os
import psutil
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM Worker Service", description="Distributed LLM Inference Worker")

# Get configuration from environment
WORKER_ID = os.getenv("WORKER_ID", "1")
MODEL_NAME = os.getenv("MODEL_NAME", "gpt2")
API_KEY = os.getenv("API_KEY", "")

# Global variables for model and tokenizer
model = None
tokenizer = None

@app.on_event("startup")
async def load_model():
    global model, tokenizer
    logger.info(f"Worker {WORKER_ID}: Loading model {MODEL_NAME}...")
    try:
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
        model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
        logger.info(f"Worker {WORKER_ID}: Model loaded successfully")
    except Exception as e:
        logger.error(f"Worker {WORKER_ID}: Failed to load model: {str(e)}")
        raise

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "worker_id": WORKER_ID,
        "model": MODEL_NAME,
        "gpu_available": torch.cuda.is_available(),
        "gpu_count": torch.cuda.device_count() if torch.cuda.is_available() else 0
    }

@app.get("/metrics")
async def get_metrics():
    """Return system metrics"""
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    
    return {
        "worker_id": WORKER_ID,
        "cpu_percent": cpu_percent,
        "memory_total_gb": round(memory.total / (1024**3), 2),
        "memory_used_gb": round(memory.used / (1024**3), 2),
        "memory_percent": memory.percent,
        "gpu_available": torch.cuda.is_available(),
        "gpu_count": torch.cuda.device_count() if torch.cuda.is_available() else 0
    }

def verify_api_key(x_api_key: str = Header(None)):
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

@app.post("/generate")
async def generate_text(prompt: dict, x_api_key: str = Header(None)):
    """Generate text from prompt"""
    verify_api_key(x_api_key)
    
    if "text" not in prompt:
        raise HTTPException(status_code=400, detail="Missing 'text' in request body")
    
    start_time = time.time()
    
    try:
        inputs = tokenizer.encode(prompt["text"], return_tensors="pt")
        
        # Generate with configurable parameters
        max_length = prompt.get("max_length", 100)
        temperature = prompt.get("temperature", 0.7)
        
        with torch.no_grad():
            outputs = model.generate(
                inputs, 
                max_length=max_length, 
                temperature=temperature,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id
            )
        
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        end_time = time.time()
        
        return {
            "worker_id": WORKER_ID,
            "generated_text": generated_text,
            "input_length": len(inputs[0]),
            "output_length": len(outputs[0]),
            "processing_time_seconds": round(end_time - start_time, 3),
            "model": MODEL_NAME
        }
    except Exception as e:
        logger.error(f"Error during text generation: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {
        "message": f"LLM Worker {WORKER_ID} is running",
        "model": MODEL_NAME,
        "docs": "/docs"
    }