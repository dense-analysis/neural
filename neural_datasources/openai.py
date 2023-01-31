"""
A Neural datasource for loading generated text via OpenAI.
"""
import json
import sys
import os
import urllib.request

API_ENDPOINT = 'https://api.openai.com/v1/completions'

OPENAI_DATA_HEADER = 'data: '
OPENAI_DONE = '[DONE]'


def get_openai_completion(
    api_key: str,
    prompt: str,
    temperature: float,
) -> None:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    data = {
        "model": "text-davinci-003",
        "prompt": prompt,
        "temperature": temperature,
        "max_tokens": 1024,
        "top_p": 1,
        "frequency_penalty": 0.3,
        "presence_penalty": 0.3,
        "stream": True,
    }
    req = urllib.request.Request(
        API_ENDPOINT,
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST",
    )

    buffer = b''

    with urllib.request.urlopen(req) as response:
        while True:
            line_bytes = response.readline()

            if not line_bytes:
                break

            line = line_bytes.decode("utf-8", errors="replace")

            if line.startswith(OPENAI_DATA_HEADER):
                line_data = line[len(OPENAI_DATA_HEADER):-1]

                if line_data == OPENAI_DONE:
                    pass
                else:
                    openai_obj = json.loads(line_data)

                    print(openai_obj["choices"][0]["text"], end="")

    print()


def main() -> None:
    api_key = os.environ.get("NEURAL_OPENAPI_KEY")

    if not api_key:
        sys.exit("NEURAL_OPENAPI_KEY is not defined.")

    input_data = json.loads(sys.stdin.readline())

    get_openai_completion(
        api_key,
        input_data["prompt"],
        input_data["temperature"],
    )

if __name__ == "__main__":  # pragma: no cover
    main()  # pragma: no cover
