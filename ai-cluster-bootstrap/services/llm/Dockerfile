FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY services/llm/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY services/llm/ .

# Expose port
EXPOSE 8000

# Run the application
CMD ["python", "app.py"]