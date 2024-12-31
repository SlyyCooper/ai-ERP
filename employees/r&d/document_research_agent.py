#!/usr/bin/env python3
"""
RAG-based Tangent Agent with Local Documents
============================================

A single Python script that integrates GPT-Researcher-style
RAG (Retrieval-Augmented Generation) with the Tangent framework,
and allows users to place documents in a 'my-docs' directory
(in the same location as this script) for ingestion into a local FAISS
vector database. The agent can then answer multi-turn user questions
based on these documents.

Requirements:
-------------
- Python 3.10+
- pip install openai faiss-cpu tiktoken
- Tangent library code must be available (the "tangent" folder).
- An environment variable OPENAI_API_KEY with your key for embeddings.
- You can add .txt, .md, .csv, or .pdf files under ./my-docs.

Usage:
------
$ python rag_tangent.py

On first run, it builds and saves a local FAISS index (local_docs.index.*).
Subsequent runs load that index if no new documents are added.

Then it enters a REPL loop. You can ask questions about content
found in "my-docs". If none is found, it won't be able to provide doc-based answers.

"""

import os
import sys
import glob
import json
import faiss
import tiktoken

import openai
from dataclasses import dataclass, field
from typing import List, Dict, Optional

# We import from tangent
from tangent import tangent, Agent
from tangent.types import Result
from tangent.repl import run_tangent_loop

##############################################################################
# Step 1: DocumentLoader (like GPT Researcher)
##############################################################################

class DocumentLoader:
    """
    Basic doc loader that walks ./my-docs, reading .txt, .md, .csv, or .pdf (text only).
    For PDFs, tries PyMuPDF if installed. This is a minimal approach similar to GPT-Researcher.
    """
    def __init__(self, path: str):
        self.path = path
        self.encoding = "utf-8"

    def load(self) -> List[Dict[str, str]]:
        """
        Return a list of docs with structure:
          [
            {
              "raw_content": <string>,
              "url": <filename>,
            },
            ...
          ]
        """
        docs = []
        if not os.path.isdir(self.path):
            print(f"[WARN] my-docs folder '{self.path}' not found. Returning empty list.")
            return docs

        filepaths = glob.glob(os.path.join(self.path, "**/*.*"), recursive=True)
        for fp in filepaths:
            ext = os.path.splitext(fp)[1].lower()
            if ext in [".txt", ".md", ".csv"]:
                try:
                    with open(fp, "r", encoding=self.encoding) as f:
                        text = f.read()
                    if text.strip():
                        docs.append({
                            "raw_content": text,
                            "url": os.path.basename(fp)
                        })
                except Exception as e:
                    print(f"[ERROR] Failed to load {fp}: {e}")
            elif ext == ".pdf":
                try:
                    import fitz  # PyMuPDF
                    doc = fitz.open(fp)
                    text_parts = []
                    for page in doc:
                        text_parts.append(page.get_text())
                    doc.close()
                    text = "\n".join(text_parts)
                    if text.strip():
                        docs.append({
                            "raw_content": text,
                            "url": os.path.basename(fp)
                        })
                except ImportError:
                    print(f"[WARN] PyMuPDF not installed, skipping PDF '{fp}'.")
                except Exception as e:
                    print(f"[ERROR] Failed to load PDF {fp}: {e}")

        print(f"[INFO] Loaded {len(docs)} documents from '{self.path}'.")
        return docs


##############################################################################
# Step 2: A simple local vector store using FAISS
##############################################################################

@dataclass
class LocalVectorStore:
    """
    Minimal FAISS index for doc embeddings. We'll store chunk embeddings
    for better retrieval. "doc_meta" keeps track of each chunk's text and source.
    """
    dimension: int
    index_path: str
    index: faiss.IndexFlatIP = field(default=None)
    doc_meta: List[Dict] = field(default_factory=list)

    def __post_init__(self):
        if os.path.exists(self.index_path):
            self._load_index()
        else:
            self.index = faiss.IndexFlatIP(self.dimension)
            print(f"[INFO] Created new FAISS index (dim={self.dimension}).")

    def _load_index(self):
        print(f"[INFO] Loading existing FAISS index from {self.index_path} ...")
        self.index = faiss.read_index(self.index_path + ".faiss")
        with open(self.index_path + ".meta.json", "r", encoding="utf-8") as f:
            self.doc_meta = json.load(f)
        print(f"[INFO] Loaded doc meta with length = {len(self.doc_meta)}")

    def add_embeddings(self, embeddings: List[List[float]], metas: List[Dict]):
        if not embeddings:
            return
        import numpy as np
        arr = np.array(embeddings, dtype="float32")
        self.index.add(arr)
        self.doc_meta.extend(metas)

    def save(self):
        faiss.write_index(self.index, self.index_path + ".faiss")
        with open(self.index_path + ".meta.json", "w", encoding="utf-8") as f:
            json.dump(self.doc_meta, f, indent=2)
        print("[INFO] Vector store saved to disk.")

    def search(self, embedding: List[float], k: int = 3) -> List[Dict]:
        import numpy as np
        vec = np.array([embedding], dtype="float32")
        distances, idxs = self.index.search(vec, k)
        results = []
        for dist, i in zip(distances[0], idxs[0]):
            if i < 0 or i >= len(self.doc_meta):
                continue
            results.append({
                "score": float(dist),
                "text": self.doc_meta[i]["text_chunk"],
                "source": self.doc_meta[i]["source"],
            })
        return results


##############################################################################
# Step 3: RAG logic: chunking docs, embedding them, building store
##############################################################################

def chunk_text(text: str, chunk_size=600, chunk_overlap=100) -> List[str]:
    """
    We chunk by tokens using tiktoken. We'll aim for 600 tokens with 100 overlap.
    """
    enc = tiktoken.get_encoding("cl100k_base")
    tokens = enc.encode(text)
    chunks = []
    i = 0
    while i < len(tokens):
        chunk = tokens[i : i + chunk_size]
        chunk_str = enc.decode(chunk)
        chunks.append(chunk_str)
        i += chunk_size - chunk_overlap
    return chunks

def ensure_vectorstore_build() -> LocalVectorStore:
    """
    1) Load docs from ./my-docs
    2) Chunk
    3) Embed
    4) Save to local FAISS
    5) Return store
    """
    store_path = "local_docs.index"
    dimension = 1536  # for text-embedding-3-small

    store = LocalVectorStore(dimension=dimension, index_path=store_path)
    if len(store.doc_meta) > 0 and store.index.ntotal > 0:
        print("[INFO] Existing vector store found. Using it.")
        return store

    print("[INFO] Building vector store from ./my-docs ...")
    loader = DocumentLoader("./my-docs")
    docs = loader.load()
    if not docs:
        print("[WARN] No docs in ./my-docs. Store will be empty.")
        return store

    client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY", ""))
    if not client.api_key:
        print("[ERROR] No OPENAI_API_KEY. Cannot embed.")
        return store

    all_embeddings = []
    all_metas = []

    for d in docs:
        text = d["raw_content"]
        source = d["url"]
        chunked = chunk_text(text)
        for ch in chunked:
            try:
                embres = client.embeddings.create(
                    model="text-embedding-3-small",
                    input=ch
                )
                embedding = embres.data[0].embedding
                all_embeddings.append(embedding)
                all_metas.append({
                    "text_chunk": ch,
                    "source": source
                })
            except Exception as e:
                print(f"[ERROR] Embedding error on chunk from {source}: {e}")

    store.add_embeddings(all_embeddings, all_metas)
    store.save()
    print(f"[INFO] Store built with {len(all_metas)} chunks.")
    return store

##############################################################################
# Step 4: The "search_local_docs" function the Agent can call
##############################################################################

def search_local_docs(query: str, top_k: int = 3) -> Result:
    """
    Agent-exposed function to embed the user query, search the local FAISS store,
    and return top matches.
    """
    try:
        store = ensure_vectorstore_build()
        if store.index is None or store.index.ntotal == 0:
            return Result(
                value="No documents found in vector store. Place docs in ./my-docs.",
                context_variables={}
            )
            
        client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY", ""))
        if not client.api_key:
            return Result(value="No OPENAI_API_KEY. Cannot embed queries.", context_variables={})

        embres = client.embeddings.create(
            model="text-embedding-3-small",
            input=query
        )
        q_embed = embres.data[0].embedding

        results = store.search(q_embed, k=top_k)
        if not results:
            return Result(value="No relevant docs found.", context_variables={})
        out = ""
        for i, r in enumerate(results):
            out += f"\n---\n[Rank {i+1} | Score={r['score']:.3f} | Source={r['source']}]\n"
            out += r["text"]
        return Result(value=out.strip())
    except Exception as e:
        return Result(value=f"Error in RAG search: {e}")

##############################################################################
# Step 5: Tangent Agent that uses 'search_local_docs' for doc-based Q&A
##############################################################################

rag_agent = Agent(
    name="LocalRAGAgent",
    instructions=(
        "You are a multi-turn agent that can answer user questions by retrieving relevant info "
        "from local documents in './my-docs'. Use 'search_local_docs' whenever you need context "
        "from the user's docs. If the user asks for info not present in the docs, say you don't have it."
    ),
    functions=[search_local_docs]
)

##############################################################################
# Step 6: Main entrypoint - run a REPL with this agent
##############################################################################

def main():
    """
    Start the tangent REPL with the RAG-based agent.
    """
    print("\n==== Local Document RAG Agent ====")
    print("Place your documents in the 'my-docs' folder, then run this script.")
    print("We'll embed them on the first run to create a local FAISS store.\n")
    run_tangent_loop(
        starting_agent=rag_agent,
        context_variables={}, 
        stream=False, 
        debug=False
    )

if __name__ == "__main__":
    main()
