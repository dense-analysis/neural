"""
A Neural datasource for loading generated text via Anthropic Claude.
"""
import json
import platform
import ssl
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional, Union

API_ENDPOINT = 'https://api.anthropic.com/v1/complete'

ANTHROPIC_DATA_HEADER = 'data: '
ANTHROPIC_DONE = '[DONE]'


class Config:
    """The sanitised configuration."""

    def __init__(
        self,
        api_key: str,
        model: str,
        temperature: float,
        top_p: float,
        max_tokens: int,
    ) -> None:
        self.api_key = api_key
        self.model = model
        self.temperature = temperature
        self.top_p = top_p
        self.max_tokens = max_tokens


def get_claude_completion(
    config: Config,
    prompt: Union[str, List[Dict[str, str]]],
) -> None:
    headers = {
        "Content-Type": "application/json",
        "x-api-key": config.api_key,
        "anthropic-version": "2023-06-01",
    }
    data = {
        "model": config.model,
        "prompt": (
            prompt
            if isinstance(prompt, str)
            else ''.join([msg.get("content", "") for msg in prompt])
        ),
        "temperature": config.temperature,
        "top_p": config.top_p,
        "max_tokens_to_sample": config.max_tokens,
        "stream": True,
    }

    req = urllib.request.Request(
        API_ENDPOINT,
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    role: Optional[str] = None

    context = (
        ssl._create_unverified_context()  # type: ignore
        if platform.system() == "Darwin" else
        None
    )

    with urllib.request.urlopen(req, context=context) as response:
        while True:
            line_bytes = response.readline()

            if not line_bytes:
                break

            line = line_bytes.decode("utf-8", errors="replace")
            line_data = (
                line[len(ANTHROPIC_DATA_HEADER):-1]
                if line.startswith(ANTHROPIC_DATA_HEADER) else None
            )

            if line_data and line_data != ANTHROPIC_DONE:
                chunk = json.loads(line_data)

                if "completion" in chunk:
                    print(chunk["completion"], end="", flush=True)

    print()


def load_config(raw_config: Dict[str, Any]) -> Config:
    if not isinstance(raw_config, dict):  # type: ignore
        raise ValueError("anthropic config is not a dictionary")

    api_key = raw_config.get('api_key')
    if not isinstance(api_key, str) or not api_key:  # type: ignore
        raise ValueError("anthropic.api_key is not defined")

    model = raw_config.get('model')
    if not isinstance(model, str) or not model:
        raise ValueError("anthropic.model is not defined")

    temperature = raw_config.get('temperature', 0.2)
    if not isinstance(temperature, (int, float)):
        raise ValueError("anthropic.temperature is invalid")

    top_p = raw_config.get('top_p', 1)
    if not isinstance(top_p, (int, float)):
        raise ValueError("anthropic.top_p is invalid")

    max_tokens = raw_config.get('max_tokens', 1024)
    if not isinstance(max_tokens, int):
        raise ValueError("anthropic.max_tokens is invalid")

    return Config(
        api_key=api_key,
        model=model,
        temperature=temperature,
        top_p=top_p,
        max_tokens=max_tokens,
    )


def get_error_message(error: urllib.error.HTTPError) -> str:
    message = error.read().decode('utf-8', errors='ignore')

    try:
        message = json.loads(message)['error']['message']
    except Exception:
        pass

    return message


def main() -> None:
    input_data = json.loads(sys.stdin.readline())

    try:
        config = load_config(input_data["config"])
    except ValueError as err:
        sys.exit(str(err))

    try:
        get_claude_completion(config, input_data["prompt"])
    except urllib.error.HTTPError as error:
        if error.code in (400, 401):
            message = get_error_message(error)
            sys.exit('Neural error: Anthropic request failure: ' + message)
        elif error.code == 429:
            sys.exit('Neural error: Anthropic request limit reached!')
        else:
            raise


if __name__ == "__main__":  # pragma: no cover
    main()  # pragma: no cover
