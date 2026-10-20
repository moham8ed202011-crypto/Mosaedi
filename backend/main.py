import os
import time
from datetime import date
from typing import Optional
import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()
app = FastAPI(title="Mosaedi AI API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict to your app/domain before production.
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Demo-only in-memory quota. Replace with durable DB and authenticated user IDs for production.
usage = {}
DAILY_LIMIT = int(os.getenv("DAILY_MESSAGE_LIMIT", "40"))

class ChatRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    messages: list[dict] = Field(min_length=1, max_length=40)

class ChatResponse(BaseModel):
    text: str
    provider: str
    remaining_demo_quota: int

def count_and_check(user_id: str) -> int:
    key = f"{date.today().isoformat()}:{user_id}"
    count = usage.get(key, 0)
    if count >= DAILY_LIMIT:
        raise HTTPException(status_code=429, detail="انتهت الحصة التجريبية اليومية لهذا الحساب.")
    usage[key] = count + 1
    return DAILY_LIMIT - usage[key]

async def gemini_reply(messages: list[dict]) -> str:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not configured")
    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    # Convert chat history to Gemini contents format.
    contents = []
    for m in messages:
        role = "model" if m.get("role") == "assistant" else "user"
        content = str(m.get("content", "")).strip()
        if content:
            contents.append({"role": role, "parts": [{"text": content}]})
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(url, params={"key": api_key}, json={"contents": contents})
    if resp.status_code >= 400:
        raise RuntimeError(f"Gemini error {resp.status_code}: {resp.text[:300]}")
    data = resp.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]

async def fallback_reply(messages: list[dict]) -> str:
    base = os.getenv("FALLBACK_BASE_URL", "").strip().rstrip("/")
    key = os.getenv("FALLBACK_API_KEY", "").strip()
    model = os.getenv("FALLBACK_MODEL", "").strip()
    if not (base and key and model):
        raise RuntimeError("Fallback provider is not configured")
    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            f"{base}/chat/completions",
            headers={"Authorization": f"Bearer {key}"},
            json={"model": model, "messages": messages, "temperature": 0.7},
        )
    if resp.status_code >= 400:
        raise RuntimeError(f"Fallback error {resp.status_code}: {resp.text[:300]}")
    return resp.json()["choices"][0]["message"]["content"]

@app.get("/health")
async def health():
    return {"ok": True, "service": "Mosaedi AI API"}

@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    remaining = count_and_check(req.user_id)
    # Try primary provider, then optional fallback. Do not loop endlessly.
    try:
        answer = await gemini_reply(req.messages)
        provider = "Gemini"
    except Exception as primary_error:
        try:
            answer = await fallback_reply(req.messages)
            provider = "Fallback"
        except Exception:
            raise HTTPException(
                status_code=503,
                detail="تعذر الاتصال بمزودي الذكاء الاصطناعي. تحقق من إعداد المفاتيح والحصص والاتصال.",
            )
    return ChatResponse(text=answer, provider=provider, remaining_demo_quota=remaining)
