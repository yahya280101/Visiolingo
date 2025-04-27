import os
import io
import tempfile
import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
from dotenv import load_dotenv
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain
from pydub import AudioSegment
from pydub.playback import play

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=api_key)

llm = ChatOpenAI(
    openai_api_key=api_key,
    model="gpt-4o"
)
memory = ConversationBufferMemory()
conversation = ConversationChain(
    llm=llm,
    memory=memory,
    verbose=False
)

def record_until_silence(threshold=800, silence_duration=4, samplerate=44100):
    """Record audio and stop after silence is detected."""
    print("🎙️ Start speaking...")
    recording = []
    silent_chunks = 0
    chunk_size = int(0.2 * samplerate)  # 200ms chunks

    stream = sd.InputStream(samplerate=samplerate, channels=1, dtype='int16')
    with stream:
        while True:
            audio_chunk, _ = stream.read(chunk_size)
            audio_chunk = np.squeeze(audio_chunk)
            recording.append(audio_chunk)

            # Check if chunk is silent
            if np.abs(audio_chunk).mean() < threshold:
                silent_chunks += 1
            else:
                silent_chunks = 0

            # If silence has been detected for enough chunks, stop recording
            if silent_chunks * 0.2 >= silence_duration:
                break

    print("✅ Finished recording.")
    final_recording = np.concatenate(recording, axis=0)
    return final_recording, samplerate

def save_wav(recording, samplerate):
    temp_wav = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    wav.write(temp_wav.name, samplerate, recording)
    return temp_wav.name

def transcribe_audio(file_path):
    with open(file_path, "rb") as f:
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=f,
            response_format="text"
        )
    return transcript

def text_to_speech_and_play(text):
    response = client.audio.speech.create(
        model="tts-1",
        voice="nova",
        input=text
    )
    audio_bytes = io.BytesIO(response.content)
    audio = AudioSegment.from_file(audio_bytes, format="mp3")
    play(audio)

def main():
    print("\n🗣️ Say 'stop' or 'bye' to end the conversation.\n")
    while True:
        recording, samplerate = record_until_silence()

        temp_wav_path = save_wav(recording, samplerate)

        user_text = transcribe_audio(temp_wav_path)
        print(f"👤 You said: {user_text}")

        if user_text.lower() in ["stop.", "bye.", "exit.", "quit."]:
            print("👋 Ending conversation. Goodbye!")
            break

        bot_reply = conversation.predict(input=user_text)
        print(f"🤖 Bot: {bot_reply}")

        text_to_speech_and_play(bot_reply)

if __name__ == "__main__":
    main()
