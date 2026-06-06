import re
import faiss
import pickle
import ollama
import numpy as np

DATA_FILE = "inurum_full_data.txt"


def load_sections(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r"(\[[A-Z0-9_]+\][\s\S]*?)(?=\n\[[A-Z0-9_]+\]|\Z)"

    sections = re.findall(pattern, content)

    return [section.strip() for section in sections]


chunks = load_sections(DATA_FILE)

print(f"Total Sections: {len(chunks)}")

embeddings = []

for chunk in chunks:

    response = ollama.embed(
        model="nomic-embed-text",
        input=chunk
    )

    embeddings.append(
        response["embeddings"][0]
    )

embeddings = np.array(
    embeddings,
    dtype=np.float32
)

faiss.normalize_L2(embeddings)

dimension = embeddings.shape[1]

index = faiss.IndexFlatIP(
    dimension
)

index.add(
    embeddings
)

faiss.write_index(
    index,
    "inurum.index"
)

with open(
    "chunks.pkl",
    "wb"
) as f:
    pickle.dump(
        chunks,
        f
    )

print("FAISS Index Created Successfully")