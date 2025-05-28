"""
A Neural datasource for ChatGPT conversations.
"""
import json
import platform
import ssl
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional, Union

API_ENDPOINT = 'https://api.openai.com/v1/chat/completions'

OPENAI_DATA_HEADER = 'data: '
OPENAI_DONE = '[DONE]'


class Config:
    """
    The sanitised configuration.
    """
    def __init__(
        self,
        api_key: str,
        model: str,
        temperature: float,
        top_p: float,
        max_tokens: int,
        presence_penalty: float,
        frequency_penalty: float,
    ):
        self.api_key = api_key
        self.model = model
        self.temperature = temperature
        self.top_p = top_p
        self.max_tokens = max_tokens
        self.presence_penalty = presence_penalty
        self.frequency_penalty = frequency_penalty


def get_chatgpt_completion(
    config: Config,
    prompt: Union[str, List[Dict[str, str]]],
) -> None:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {config.api_key}"
    }
    data = {
        "model": config.model,
        "messages": (
            [{"role": "user", "content": prompt}]
            if isinstance(prompt, str) else
            prompt
        ),
        "temperature": config.temperature,
        "max_tokens": config.max_tokens,
        "top_p": 1,
        "presence_penalty": config.presence_penalty,
        "frequency_penalty": config.frequency_penalty,
        "stream": True,
    }

    req = urllib.request.Request(
        API_ENDPOINT,
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    role: Optional[str] = None

    # Disable SSL certificate verification on macOS.
    # This is bad for security, and we need to deal with SSL errors better.
    #
    # This is the error:
    # urllib.error.URLError: <urlopen error [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:997)>  # noqa
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
                line[len(OPENAI_DATA_HEADER):-1]
                if line.startswith(OPENAI_DATA_HEADER) else
                None
            )

            if line_data and line_data != OPENAI_DONE:
                delta = json.loads(line_data)["choices"][0]["delta"]
                # The role is typically in the first delta only.
                role = delta.get("role", role)

                if role == "assistant" and "content" in delta:
                    print(delta["content"], end="", flush=True)

    print()


def load_config(raw_config: Dict[str, Any]) -> Config:
    # TODO: Add range validation for request parameters.
    if not isinstance(raw_config, dict):  # type: ignore
        raise ValueError("chatgpt config is not a dictionary")

    api_key = raw_config.get('api_key')

    if not isinstance(api_key, str) or not api_key:  # type: ignore
        raise ValueError("chatgpt.api_key is not defined")

    model = raw_config.get('model')

    if not isinstance(model, str) or not model:
        raise ValueError("chatgpt.model is not defined")

    temperature = raw_config.get('temperature', 0.2)

    if not isinstance(temperature, (int, float)):
        raise ValueError("chatgpt.temperature is invalid")

    top_p = raw_config.get('top_p', 1)

    if not isinstance(top_p, (int, float)):
        raise ValueError("chatgpt.top_p is invalid")

    max_tokens = raw_config.get('max_tokens', 1024)

    if not isinstance(max_tokens, (int)):
        raise ValueError("chatgpt.max_tokens is invalid")

    presence_penalty = raw_config.get('presence_penalty', 0)

    if not isinstance(presence_penalty, (int, float)):
        raise ValueError("chatgpt.presence_penalty is invalid")

    frequency_penalty = raw_config.get('frequency_penalty', 0)

    if not isinstance(frequency_penalty, (int, float)):
        raise ValueError("chatgpt.frequency_penalty is invalid")

    return Config(
        api_key=api_key,
        model=model,
        temperature=temperature,
        top_p=top_p,
        max_tokens=max_tokens,
        presence_penalty=presence_penalty,
        frequency_penalty=frequency_penalty,
    )


def get_error_message(error: urllib.error.HTTPError) -> str:
    message = error.read().decode('utf-8', errors='ignore')

    try:
        # JSON data might look like this:
        # {
        #   "error": {
        #       "message": "...",
        #       "type": "...",
        #       "param": null,
        #       "code": null
        #   }
        # }
        message = json.loads(message)['error']['message']

        if "This model's maximum context length is" in message:
            message = 'Too much text for a request!'
    except Exception:
        # If we can't get a better message use the JSON payload at least.
        pass

    return message


def main() -> None:
    input_data = json.loads(sys.stdin.readline())

    try:
        config = load_config(input_data["config"])
    except ValueError as err:
        sys.exit(str(err))

    try:
        get_chatgpt_completion(config, input_data["prompt"])
    except urllib.error.HTTPError as error:
        if error.code == 400 or error.code == 401:
            message = get_error_message(error)
            sys.exit('Neural error: OpenAI request failure: ' + message)
        elif error.code == 429:
            sys.exit("Neural error: OpenAI request limit reached!")
        else:
            raise


if __name__ == "__main__":  # pragma: no cover
    main()  # pragma: no cover
