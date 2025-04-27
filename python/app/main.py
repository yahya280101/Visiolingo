import os
import io
import json
import tempfile
import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
from pydub import AudioSegment
from pydub.playback import play
from dotenv import load_dotenv

from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain
from langchain.prompts import (
    SystemMessagePromptTemplate,
    HumanMessagePromptTemplate,
    MessagesPlaceholder,
    ChatPromptTemplate,
)

from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles


from app.scenario_generator import generate_place_background_and_person
from app.scenario_generator    import generate_image_from_description, generate_avatar

load_dotenv()
API_KEY = os.getenv("OPENAI_API_KEY")

app = FastAPI(
    title="Visiolingo Server",
    description="API documentation for the Visiolingo Server.",
    version="0.0.1",
)

ASSETS_DIR = os.path.join(os.path.dirname(__file__), 'assets')
VIDEO_DIR = os.path.join(ASSETS_DIR, 'video')
IMAGE_DIR = os.path.join(ASSETS_DIR, 'image')
AUDIO_DIR = os.path.join(ASSETS_DIR, 'audio')
os.makedirs(AUDIO_DIR, exist_ok=True)

# Expose /assets/* for static files
app.mount("/assets", StaticFiles(directory=ASSETS_DIR), name="assets")


# ——————————————————————————————————————————————————————————————————

@app.post("/uploadAudio")
async def upload_audio(file: UploadFile = File(...)):
    # only allow m4a
    if not file.filename.lower().endswith(".m4a"):
        raise HTTPException(400, "Only .m4a uploads accepted")

    dest = os.path.join(AUDIO_DIR, 'recording')
    try:
        contents = await file.read()
        with open(dest, "wb") as out_f:
            out_f.write(contents)
    except Exception as e:
        raise HTTPException(500, f"Could not save file: {e}")

    return JSONResponse({
        "status": "ok",
        "filename": "recording",
        "saved_path": dest
    })
    #return video


@app.get("/")
async def read_root():
    return {"message": "Welcome to FastAPI!"}

@app.get("/video")
async def generate_video():
    #return video
    return 

@app.post("/hello")
async def generate_image(prefs: dict):
    #generate image

    try:
        language = prefs["language"]
        level    = prefs["level"]
        name     = prefs["name"]
    except KeyError as e:
        raise HTTPException(400, f"Missing field {e.args[0]}")
        
    scenario = generate_place_background_and_person(language, level, name)

    print("\n🎬 Scenario:")
    print(f"Place: {scenario['place']}")
    print(f"Place: {scenario['level']}")
    print(f"Place: {scenario['name']}")
    print(f"Place: {scenario['language']}")
    print(f"Background: {scenario['background']}")
    print(f"Person to talk to: {scenario['person_to_talk_to']}")
    print(f"Goal: {scenario['goal']}")

    image_name = 'background.png'
    image_path = os.path.join(IMAGE_DIR, image_name)

    bg_path = generate_image_from_description(scenario["background"], image_path)

    if not os.path.exists(image_path):
        raise HTTPException(status_code=404, detail="Intro video not found")
    
    return FileResponse(
        image_path,
        media_type="image/png",
        filename="background.png"
    )

# ——————————————————————————————————————————————————————————————————
def build_conversation_chain(scenario: dict):
    """
    Create a ConversationChain seeded with the scenario via a system prompt,
    with the scenario values already bound into the prompt.
    """

    system_tmpl = """
    You are a friendly, supportive language tutor helping a user named {name} practice {language}.
    The user's proficiency level is {level}.

    Always strictly rely on the provided scenario:
    - Place: {place}
    - Background: {background}
    - Person to talk to: {person_to_talk_to}
    - User’s goal: {goal}

    Instructions:
    - Initiate the conversation naturally in {language}.
    - Greet the user personally by using their name {name} when appropriate.
    - Speak according to the user's language level: {level}.
    - The user must always speak second. You must start every dialogue.
    - Keep the dialogue natural, immersive, and aligned with the scenario.
    - If the user makes a mistake, correct it kindly and briefly in {language}, and continue the conversation.
    - Stay in character based on the scenario at all times.
    - Encourage the user to use new words, expressions, and help them reach their goal.

    Your primary aim is to make the practice fun, realistic, and confidence-building.
    """.strip()

    system_msg = SystemMessagePromptTemplate.from_template(system_tmpl)

    history   = MessagesPlaceholder(variable_name="history")
    human_msg = HumanMessagePromptTemplate.from_template("{input}")
    prompt    = ChatPromptTemplate.from_messages([system_msg, history, human_msg])

    prompt_with_scenario = prompt.partial(
        language=scenario["language"],
        place=scenario["place"],
        level=scenario["level"],
        name=scenario["name"],
        background=scenario["background"],
        person_to_talk_to=scenario["person_to_talk_to"],
        goal=scenario["goal"],
    )

    llm = ChatOpenAI(openai_api_key=API_KEY, model="gpt-4o")
    memory = ConversationBufferMemory(return_messages=True)

    return ConversationChain(
        llm=llm,
        prompt=prompt_with_scenario,
        memory=memory,
        verbose=False,
    )

def record_until_silence(threshold=800, silence_duration=4, samplerate=44100):
    print("🎙️ Start speaking…")
    recording = []
    silent_chunks = 0
    chunk_size = int(0.2 * samplerate)

    with sd.InputStream(samplerate=samplerate, channels=1, dtype='int16') as stream:
        while True:
            chunk, _ = stream.read(chunk_size)
            chunk = np.squeeze(chunk)
            recording.append(chunk)

            if np.abs(chunk).mean() < threshold:
                silent_chunks += 1
            else:
                silent_chunks = 0

            if silent_chunks * 0.2 >= silence_duration:
                break

    print("✅ Finished recording.")
    return np.concatenate(recording, axis=0), samplerate

def save_wav(recording, samplerate):
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    wav.write(tmp.name, samplerate, recording)
    return tmp.name

def transcribe_audio(path, client):
    with open(path, "rb") as f:
        return client.audio.transcriptions.create(
            model="whisper-1", file=f, response_format="text"
        )

def text_to_speech_and_play(text, client):
    resp = client.audio.speech.create(model="tts-1", voice="nova", input=text)
    audio = AudioSegment.from_file(io.BytesIO(resp.content), format="mp3")
    play(audio)

def main():
    client = OpenAI(api_key=API_KEY)

    language, level, name = input("🌍 give me the language, your name and the level").split(",")
    scenario = generate_place_background_and_person(language, level, name)

    print("\n🎬 Scenario:")
    print(f"Place: {scenario['place']}")
    print(f"Place: {scenario['level']}")
    print(f"Place: {scenario['name']}")
    print(f"Place: {scenario['language']}")
    print(f"Background: {scenario['background']}")
    print(f"Person to talk to: {scenario['person_to_talk_to']}")
    print(f"Goal: {scenario['goal']}")

    bg_path   = generate_image_from_description(scenario["background"])
    avatar_p  = generate_avatar(scenario["person_to_talk_to"], scenario["background"])

    with open("scenario.json", "w") as f:
        json.dump({**scenario, "language": language,
                   "background_image": bg_path,
                   "avatar_image": avatar_p}, f, indent=2)
    print("✅ Scenario + images saved.\n")

    conversation = build_conversation_chain(scenario)

    print("🗣️ Say 'stop' or 'bye' to end.\n")

    bot_reply = conversation.predict(input="Start the conversation.")
    print(f"🤖 Bot: {bot_reply}")
    text_to_speech_and_play(bot_reply, client)

    while True:
        rec, sr = record_until_silence()
        wav_path = save_wav(rec, sr)
        user_text = transcribe_audio(wav_path, client)
        print(f"👤 You said: {user_text}")

        if user_text.strip().lower() in {"stop", "bye", "exit", "quit"}:
            print("👋 Goodbye!")
            break

        bot_reply = conversation.predict(
            input=user_text,
        )
        print(f"🤖 Bot: {bot_reply}")
        text_to_speech_and_play(bot_reply, client)

if __name__ == "__main__":
    main()