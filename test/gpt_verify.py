from openai import OpenAI

APIM_KEY = ""
APIM_URL = ""
MODEL_NAME = ""

client = OpenAI(
    base_url=APIM_URL,
    api_key="omit",
    default_headers={
        "Ocp-Apim-Subscription-Key": APIM_KEY,
    },
)


# --- Responses API ---
def create_response(prompt: str, model: str = MODEL_NAME):
    """
    Create a response using the OpenAI Responses API via Azure API Management.

    Args:
        prompt (str): The prompt to send to the model.
        model (str): The model deployment name to use.
    """

    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
    )

    print(response.choices[0].message.content)

# --- Main Script ---
if __name__ == "__main__":
    # Example usage of create_response
    prompt = "Hello, how are you?"
    create_response(prompt)