"""
A Neural datasource for loading generated text via OpenAI.
"""
import json
import sys
import urllib.error
from typing import Any, Dict
import urllib.request

API_ENDPOINT = 'https://api.openai.com/v1/completions'

OPENAI_DATA_HEADER = 'data: '
OPENAI_DONE = '[DONE]'


class Config:
    """
    The sanitised configuration.
    """
    def __init__(
        self,
        api_key: str,
        temperature: float,
    ):
        self.api_key = api_key
        self.temperature = temperature



def get_openai_completion(config: Config, prompt: str) -> None:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {config.api_key}"
    }
    data = {
        "model": "text-davinci-003",
        "prompt": prompt,
        "temperature": config.temperature,
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

                    print(openai_obj["choices"][0]["text"], end="", flush=True)

    print()


def load_config(raw_config: Dict[str, Any]) -> Config:
    if not isinstance(raw_config, dict):  # type: ignore
        raise ValueError("openai config is not a dictionary")

    api_key = raw_config.get('api_key')

    if not isinstance(api_key, str) or not api_key:  # type: ignore
        raise ValueError("openai.api_key is not defined")

    temperature = raw_config.get('temperature', 0)

    if not isinstance(temperature, (int, float)):
        raise ValueError("openai.temperature is invalid")

    return Config(
        api_key=api_key,
        temperature=temperature,
    )


def main() -> None:
    input_data = json.loads(sys.stdin.readline())

    try:
        config = load_config(input_data["config"])
    except ValueError as err:
        sys.exit(str(err))

    try:
        get_openai_completion(config, input_data["prompt"])
    except urllib.error.URLError as error:
        if isinstance(error, urllib.error.HTTPError) and error.code == 429:
            sys.exit("Neural error: OpenAI request limit reached!")
        else:
            raise

if __name__ == "__main__":  # pragma: no cover
    main()  # pragma: no cover
