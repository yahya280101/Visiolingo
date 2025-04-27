import base64
import os
import json
from dotenv import load_dotenv
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

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

def generate_place_background_and_person(language, level, name):
    """LLM generates a random place, background description (visual), and person to talk to."""

    system_prompt = (
        f"You are a creative language tutor helping a user named {name} practice {language}.\n"
        f"The user's current proficiency level is {level}.\n"
        "Create a realistic language practice scenario, culturally linked to regions where the language is spoken.\n"
        "Scenario and language difficulty must match the user's level:\n"
        "- For beginners: simple, everyday situations with easy vocabulary.\n"
        "- For intermediate learners: moderately complex tasks using practical vocabulary.\n"
        "- For advanced learners: complex, nuanced scenarios requiring detailed discussion.\n"
        "Rules:\n"
        "- Pick a culturally appropriate place (1-3 words)\n"
        "- Write a vivid background description (sights, sounds, smells, feelings)\n"
        "- Choose a realistic person the user will talk to (cashier, waiter, officer, etc.)\n"
        "- Adjust the complexity of the background description and conversation based on the level.\n"
        "- Include a simple goal for the user (1 sentence)\n"
        "- Output EXACTLY this format:\n"
        "{\n"
        '  "language": "[language]",\n'
        '  "level": "[level]",\n'
        '  "name": "[name]",\n'
        '  "place": "[place]",\n'
        '  "background": "[background description]",\n'
        '  "person_to_talk_to": "[role]",\n'
        '  "goal": "[goal]"\n'
        "}\n"
    )

    response = conversation.predict(input=system_prompt)
    print("response", response)
    scenario = json.loads(response.replace("'", '"'))
    return scenario

def generate_image_from_description(description, filename="background.png"):
    """Use gpt-image-1 to generate a background."""
    prompt = (
        f"{description}. "
        "Imagine standing inside the scene, 360° natural surroundings. "
        "Photorealistic style, natural lighting, realistic colors. "
        "Wide-angle, open foreground. "
        "Do not show any humans, people, shadows of people, or human-like figures in the scene."
    )
    result = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        n=1,
        quality="low",
        size="1536x1024",
    )

    image_base64 = result.data[0].b64_json
    image_bytes = base64.b64decode(image_base64)

    with open(filename, "wb") as f:
        f.write(image_bytes)

    print(f"✅ Background image saved to {filename}")
    return filename

def generate_avatar(person_description, background_description, filename="avatar.png"):
    """Use gpt-image-1 to generate a realistic avatar matching the scene."""
    avatar_prompt = (
        f"A realistic professional portrait of a {person_description}, appropriate to this setting: {background_description}. "
        "Close-up, shoulders and head only. Neutral expression. Soft natural lighting. "
        "No background, transparent background preferred (or plain white if needed)."
    )

    result = client.images.generate(
        model="gpt-image-1",
        prompt=avatar_prompt,
        n=1,
        size="1024x1024",
        quality="low"
    )

    image_base64 = result.data[0].b64_json
    image_bytes = base64.b64decode(image_base64)

    with open(filename, "wb") as f:
        f.write(image_bytes)

    print(f"✅ Avatar image saved to {filename}")
    return filename

def main():
    language = input("🌍 Which language are you practicing? (e.g., German, French, Spanish): ")

    scenario = generate_place_background_and_person(language)

    print("\n🎬 Scenario:")
    print(f"Place: {scenario['place']}")
    print(f"Background Description: {scenario['background']}")
    print(f"Person to talk to: {scenario['person_to_talk_to']}")
    print(f"Goal: {scenario['goal']}")

    background_image_path = generate_image_from_description(scenario['background'])
    avatar_image_path = generate_avatar(
        person_description=scenario['person_to_talk_to'],
        background_description=scenario['background']
    )

    with open("scenario.json", "w") as f:
        json.dump({
            "language": language,
            "place": scenario['place'],
            "background": scenario['background'],
            "person_to_talk_to": scenario['person_to_talk_to'],
            "goal": scenario['goal'],
            "background_image_path": background_image_path,
            "avatar_image_path": avatar_image_path,
        }, f, indent=2)

    print("\n✅ Scenario and images saved. Ready to practice!")

if __name__ == "__main__":
    main()