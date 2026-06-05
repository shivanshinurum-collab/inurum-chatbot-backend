import faiss
import pickle
import ollama
import numpy as np

index = faiss.read_index(
    "inurum.index"
)

with open(
    "chunks.pkl",
    "rb"
) as f:
    chunks = pickle.load(f)

print("Inurum AI Assistant Ready")


while True:

    question = input("\nYou: ")

    if question.lower() == "exit":
        break

    query_embedding = ollama.embed(
        model="nomic-embed-text",
        input=question
    )["embeddings"][0]

    query_embedding = np.array(
        [query_embedding],
        dtype=np.float32
    )

    faiss.normalize_L2(
        query_embedding
    )

    distances, indices = index.search(
        query_embedding,
        3
    )

    context = ""

    for idx in indices[0]:
        context += chunks[idx]
        context += "\n\n"

    print("\nContext Retrieved:")
    print(context)    
    prompt = f"""
You are the official AI assistant of Inurum Technologies.

Rules:
- Answer only from provided context.
- Never make up information.
- If answer not available say:
  "I don't know based on the available company data."

Context:
{context}

Question:
{question}

Answer:
"""

    response = ollama.chat(
        model="llama3",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    print(
        "\nBot:",
        response["message"]["content"]
    )