import os
import gradio as gr

MODEL_PATH = os.getenv("MODEL_PATH", "/model")


def chat_fn(message, history):
    history = history or []
    return f"You said: {message}\n\nModel path: {MODEL_PATH}\n\nReplace this with real model inference."


app = gr.ChatInterface(
    fn=chat_fn,
    title="Llama 3 Chat on EKS",
    description="Starter chatbot UI running on Amazon EKS"
)

app.launch(server_name="0.0.0.0", server_port=7860)
