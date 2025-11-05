"""
Model management utilities for LLM workers
"""

import os
from typing import Dict, List
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

SUPPORTED_MODELS = {
    "gpt2": {
        "description": "Small GPT-2 model",
        "default": True
    },
    "gpt2-medium": {
        "description": "Medium GPT-2 model"
    },
    "EleutherAI/gpt-j-6B": {
        "description": "GPT-J 6B parameters"
    },
    "facebook/opt-350m": {
        "description": "OPT model with 350M parameters"
    }
}

class ModelManager:
    def __init__(self):
        self.models_dir = os.path.join(os.getcwd(), "models")
        os.makedirs(self.models_dir, exist_ok=True)
        self.loaded_models = {}
    
    def list_available_models(self) -> Dict[str, Dict]:
        """List all supported models"""
        return SUPPORTED_MODELS
    
    def download_model(self, model_name: str) -> bool:
        """Download a model if not already present"""
        try:
            # Check if model is already downloaded
            model_path = os.path.join(self.models_dir, model_name.replace('/', '_'))
            
            if os.path.exists(model_path):
                return True
            
            # Download model and tokenizer
            print(f"Downloading {model_name}...")
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModelForCausalLM.from_pretrained(model_name)
            
            # Save locally
            tokenizer.save_pretrained(model_path)
            model.save_pretrained(model_path)
            
            print(f"Model {model_name} downloaded successfully")
            return True
            
        except Exception as e:
            print(f"Failed to download {model_name}: {str(e)}")
            return False
    
    def load_model(self, model_name: str) -> tuple:
        """Load model and tokenizer into memory"""
        if model_name in self.loaded_models:
            return self.loaded_models[model_name]
        
        try:
            model_path = os.path.join(self.models_dir, model_name.replace('/', '_'))
            
            if not os.path.exists(model_path):
                # Try to load directly from HuggingFace
                print(f"Loading {model_name} from HuggingFace...")
                tokenizer = AutoTokenizer.from_pretrained(model_name)
                model = AutoModelForCausalLM.from_pretrained(model_name)
            else:
                # Load from local storage
                print(f"Loading {model_name} from local storage...")
                tokenizer = AutoTokenizer.from_pretrained(model_path)
                model = AutoModelForCausalLM.from_pretrained(model_path)
            
            # Store in memory
            self.loaded_models[model_name] = (model, tokenizer)
            
            return model, tokenizer
            
        except Exception as e:
            print(f"Failed to load {model_name}: {str(e)}")
            raise

# Global model manager instance
model_manager = ModelManager()