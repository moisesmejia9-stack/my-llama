


Review Chapter 3 section Building a GenAI container image to build the docker image:

==========================================================================================

Recommended updated workflow
1) Authenticate and download the model

Current Hugging Face docs prefer the hf CLI. A modern flow is:

pip install -U "huggingface_hub[cli]"
hf auth login

Then download the file:

mkdir -p models

hf download TheBloke/Llama-2-7B-Chat-GGUF \
  llama-2-7b-chat.Q4_K_M.gguf \
  --local-dir ./models


==========================================================================================

Create app.py

import os
from flask import Flask, request, jsonify
from llama_cpp import Llama

MODEL_PATH = os.getenv("MODEL_PATH", "./models/llama-2-7b-chat.Q4_K_M.gguf")
N_CTX = int(os.getenv("N_CTX", "2048"))
N_THREADS = int(os.getenv("N_THREADS", "4"))

app = Flask(__name__)

llm = Llama(
    model_path=MODEL_PATH,
    n_ctx=N_CTX,
    n_threads=N_THREADS,
    verbose=False,
    # Uncomment if you later add GPU offload support:
    # n_gpu_layers=-1,
)

@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"})

@app.post("/predict")
def predict():
    data = request.get_json(silent=True) or {}

    system_message = data.get("sys_msg", "You are a helpful assistant.")
    user_prompt = data.get("prompt")
    max_tokens = int(data.get("max_tokens", 256))
    temperature = float(data.get("temperature", 0.2))

    if not user_prompt:
        return jsonify({"error": "Missing required field: prompt"}), 400

    response = llm.create_chat_completion(
        messages=[
            {"role": "system", "content": system_message},
            {"role": "user", "content": user_prompt},
        ],
        max_tokens=max_tokens,
        temperature=temperature,
    )

    content = response["choices"][0]["message"]["content"]
    return jsonify({"response": content})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)


==========================================================================================

Create Dockerfile;

FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MODEL_PATH=/app/models/llama-2-7b-chat.Q4_K_M.gguf \
    N_CTX=2048 \
    N_THREADS=4

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY models ./models

EXPOSE 5000

CMD ["python", "app.py"]

==========================================================================================

Create a requirements.txt

flask==3.1.0
llama-cpp-python==0.3.16

==========================================================================================


