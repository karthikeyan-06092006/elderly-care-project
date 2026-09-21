from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional
from groq import Groq
from app.config import settings

router = APIRouter(prefix="/api/ai", tags=["Bilingual Conversational AI"])

class ChatMessage(BaseModel):
    role: str  # 'user' | 'assistant' | 'system'
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    language: Optional[str] = "en"  # "en" or "bn"
    patient_name: Optional[str] = "Grandparent"

SYSTEM_PROMPT_EN = """You are a warm, gentle, and empathetic conversational companion designed specifically for an elderly person who may experience mild dementia or memory loss.
Guidelines:
- Keep answers very short, comforting, clear, and easy to understand (1-3 sentences).
- Always be polite, respectful, patient, and encouraging.
- Never show frustration or argue. Validate their feelings.
- Encourage them gently to drink water, rest, or enjoy memory games."""

SYSTEM_PROMPT_BN = """আপনি ডিমেনশিয়া বা স্মৃতিভ্রংশে আক্রান্ত বয়স্ক ব্যক্তির জন্য তৈরি করা একজন অত্যন্ত স্নেহশীল, নম্র ও সহানুভূতিশীল সহকারী।
নিয়মাবলী:
- উত্তরগুলি খুবই সংক্ষিপ্ত, সহজ, মিষ্টি ও স্পষ্ট ভাষায় রাখুন (১-৩ বাক্য)।
- সম্মানজনক ও মধুর আচরণ বজায় রাখুন।
- রোগীকে জল খেতে, বিশ্রাম নিতে ও শান্ত মনে খেলা করতে উৎসাহিত করুন।
- সর্বদা বাংলায় উত্তর দিন।"""

# Offline bilingual intent responses fallback
OFFLINE_RESPONSES = {
    "bn": {
        "hello": "নমস্কার! কেমন আছেন আপনি? আমি আপনার সাথে গল্প করতে সর্বদা প্রস্তুত।",
        "time": "এখন সময় বেশ সুন্দর। আপনি কি একটু জল খেয়েছেন?",
        "medicine": "আপনার ওষুধ খাওয়ার সময় হলে যত্নশীল ব্যক্তিকে মনে করিয়ে দিন বা অ্যাপের অ্যালার্ম দেখুন।",
        "game": "মস্তিষ্ক সতেজ রাখতে আমাদের মেমোরি গেম খেলুন, এটি খুব আনন্দদায়ক!",
        "default": "আমি আপনার কথা শুনতে পাচ্ছি। আপনি কেমন বোধ করছেন আমাকে বলুন।"
    },
    "en": {
        "hello": "Hello! How are you feeling today? I am always happy to chat with you.",
        "time": "It is a wonderful day. Have you had a glass of water recently?",
        "medicine": "Please check your daily reminders for medications, or ask your caregiver.",
        "game": "Playing our memory game is a great way to keep your mind sharp and active!",
        "default": "I am right here listening to you. Tell me more about how you feel today."
    }
}

def get_offline_response(user_msg: str, lang: str) -> str:
    msg = user_msg.lower()
    lang_dict = OFFLINE_RESPONSES.get(lang, OFFLINE_RESPONSES["en"])
    
    if any(w in msg for w in ["hello", "hi", "নমস্কার", "কেমন", "হ্যালো"]):
        return lang_dict["hello"]
    elif any(w in msg for w in ["medicine", "pill", "ওষুধ", "ঔষধ"]):
        return lang_dict["medicine"]
    elif any(w in msg for w in ["game", "play", "খেলা", "গেম"]):
        return lang_dict["game"]
    elif any(w in msg for w in ["time", "clock", "সময়", "বেলা"]):
        return lang_dict["time"]
    else:
        return lang_dict["default"]

@router.post("/chat")
def chat_with_companion(req: ChatRequest):
    lang = req.language if req.language in ["en", "bn"] else "en"
    sys_prompt = SYSTEM_PROMPT_BN if lang == "bn" else SYSTEM_PROMPT_EN

    # Try Groq API if key is available
    if settings.GROQ_API_KEY:
        try:
            client = Groq(api_key=settings.GROQ_API_KEY)
            groq_messages = [{"role": "system", "content": sys_prompt}]
            for m in req.messages[-6:]:  # Keep recent context
                groq_messages.append({"role": m.role, "content": m.content})
            
            completion = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=groq_messages,
                temperature=0.6,
                max_tokens=150
            )
            reply = completion.choices[0].message.content
            return {
                "reply": reply,
                "language": lang,
                "mode": "online_groq"
            }
        except Exception as e:
            print(f"[Groq API Error]: {e}, falling back to local intent responder.")

    # Fallback to local offline intent engine
    last_user_msg = req.messages[-1].content if req.messages else ""
    offline_reply = get_offline_response(last_user_msg, lang)
    return {
        "reply": offline_reply,
        "language": lang,
        "mode": "offline_rule_engine"
    }
