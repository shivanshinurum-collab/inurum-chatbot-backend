import faiss
import pickle
import ollama
import numpy as np

from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import StreamingHttpResponse


index = faiss.read_index(
    "company/inurum.index"
)
with open(
    'company/chunks.pkl',
    'rb'
)as f :
    chunks = pickle.load(f)


@api_view(['GET'])
def home(request):
    return Response({
        'message': 'Welcome to the company page!',
        'status': 'success',
    })


@api_view(['POST'])
def chatBot(request):
    question = request.data.get('question', "")

    if not question:
        return Response({
            'message': 'Question is required',
            'status': 'error',
        })

    # ----- Tumhara RAG code same rahega -----

    query_embedding = ollama.embed(
        model="nomic-embed-text",
        input=question
    )["embeddings"][0]

    query_embedding = np.array(
        [query_embedding],
        dtype=np.float32
    )

    faiss.normalize_L2(query_embedding)

    distance, indices = index.search(
        query_embedding,
        3
    )

    context = ""

    for idx in indices[0]:
        context += chunks[idx]
        context += "\n\n"

    prompt = f"""
    You are the official AI assistant of Inurum Technologies.
    Rules:
    - Answer only from provided context.
    - Never make up information.

    Context:{context}
    Question:{question}
    Answer:
    """

    def generate():
        try:
            stream = ollama.chat(
                model='llama3',
                messages=[{
                    'role': 'user',
                    'content': prompt
                }],
                stream=True
            )

            for chunk in stream:
                yield chunk['message']['content']
        except Exception as e:
            yield f"\n[Backend Error: {str(e)}]"

    return StreamingHttpResponse(
        generate(),
        content_type='text/plain'
    )



# @api_view(['POST'])
# def chatBot(request):
#     question = request.data.get('question',"")

#     if not question:
#         return Response({
#             'message': 'Question is required',
#             'status': 'error',
#         })
    
#     query_embedding = ollama.embed(
#         model = "nomic-embed-text",
#         input=question
#     )["embeddings"][0]

#     query_embedding = np.array(
#         [query_embedding],
#         dtype=np.float32
#     )

#     faiss.normalize_L2(
#         query_embedding
#     )

#     distance ,indices = index.search(
#         query_embedding,
#         3
#     )

#     context = ""

#     for idx in indices[0]:
#         context += chunks[idx]
#         context += '\n\n'

#     prompt = f"""
#     You are the official AI assistant of Inurum Technologies.
#     Rules:
#     - Answer only from provided context.
#     - Never make up information.
#     - If answer not available say:
#     I don't know based on the available company data.

#     Context:{context}
#     Question:{question}
#     Answer:
#     """
        
#     response = ollama.chat(
#         model = 'llama3',
#         messages=[{
#             'role' : 'user',
#             'content':prompt
#         }]
#     )
        
#     answer = response["message"]['content']

#     return Response({
#         "success": True,
#         "question": question,
#         "answer": answer,
#         "context": context
#     })
 





