from anthropic import Anthropic

APIM_KEY = ""
APIM_URL = ""
MODEL_NAME = ""

client = Anthropic(
    base_url=APIM_URL,
    default_headers={
        "Ocp-Apim-Subscription-Key": APIM_KEY,
        "anthropic-version": "2023-06-01",
        "X-Api-Key": "omit",
    },   
)

# --- Message API ---
def create_message(prompt: str, model: str = MODEL_NAME):
    """
    Create a message using the Anthropic API via Azure API Management.

    Args:
        prompt (str): The prompt to send to the model.
        model (str): The model name to use.
    """

    response = client.messages.create(
        model=model,
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}],

    )

    print(response.content[0].text)


# --- Web Search ---
def web_search(query: str, model: str = MODEL_NAME):
    """
    Perform a web search using the Anthropic API via Azure API Management.

    Args:
        query (str): The search query.
        model (str): The model name to use.
    """

    tools = [
        {
            "type": "web_search_20250305",
            "name": "web_search"
        }
    ]

    message_list = [
        {
            "role": "user",
            "content": query
        }
    ]

    response = client.messages.create(
        model=model,
        messages=message_list,
        max_tokens=1024,
        temperature=0.7,
        stream=False,
        tools=tools,
        tool_choice={
            "type": "auto"
        }
    )

    sources = {}
    answer_parts = []

    for block in response.content:
        if block.type != "text":
            continue

        citation_numbers = []
        for citation in getattr(block, "citations", None) or []:
            if citation.url not in sources:
                sources[citation.url] = {
                    "number": len(sources) + 1,
                    "title": citation.title,
                }
            citation_numbers.append(sources[citation.url]["number"])

        markers = "".join(f"[{number}]" for number in citation_numbers)
        answer_parts.append(f"{block.text}{markers}")

    print("".join(answer_parts))

    if sources:
        print("\nSources:")
        for url, source in sources.items():
            print(f"[{source['number']}] {source['title']}\n    {url}")

# --- Main Script ---
if __name__ == "__main__":
    # Example usage of create_message
    prompt = "Hello, how are you?"
    create_message(prompt)

    # Example usage of web_search
    query = "What is the weather in Tokyo today?"
    web_search(query)