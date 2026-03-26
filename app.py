


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
