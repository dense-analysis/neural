import json
import sys
import urllib.error
import urllib.request
from io import BytesIO
from typing import Any, cast
from unittest import mock

import pytest

from neural.provider import openai


def get_valid_config(
    model: str = "foo",
    *,
    api_key: str = '.',
) -> dict[str, str | int]:
    return {
        "api_key": api_key,
        "model": model,
        "prompt": "say hello",
        "temperature": 1,
        "top_p": 1,
        "max_tokens": 1,
        "presence_penalty": 1,
        "frequency_penalty": 1,
    }


def test_load_config_errors() -> None:
    with pytest.raises(ValueError) as exc:
        openai.load_config(cast(Any, 0))

    assert str(exc.value) == "openai config is not a dictionary"

    config: dict[str, Any] = {}

    for modification, expected_error in [
        ({"url": 1}, "url must be a string"),
        ({"url": "x"}, "url must start with http(s)://"),
        ({"url": "https://x"}, "model is not defined"),
        ({"model": ""}, "model is not defined"),
        (
            {"model": "x", "use_chat_api": 1},
            "use_chat_api must be true or false",
        ),
        (
            {"use_chat_api": None, "temperature": "x"},
            "temperature is invalid",
        ),
        (
            {"temperature": 1, "top_p": "x"},
            "top_p is invalid",
        ),
        (
            {"top_p": 1, "max_tokens": "x"},
            "max_tokens is invalid",
        ),
        (
            {"max_tokens": 1, "presence_penalty": "x"},
            "presence_penalty is invalid",
        ),
        (
            {"presence_penalty": 1, "frequency_penalty": "x"},
            "frequency_penalty is invalid",
        ),
    ]:
        config.update(modification)

        with pytest.raises(ValueError) as exc:
            openai.load_config(config)

        assert str(exc.value) == expected_error, config


def test_automatic_completions_api_usage() -> None:
    raw_config = get_valid_config()

    for model in (
        'ada',
        'babbage',
        'curie',
        'davinci',
        'gpt-3.5-turbo-instruct',
        'text-ada-001',
        'text-babbage-001',
        'text-curie-001',
        'text-davinci-002',
        'text-davinci-003',
    ):
        raw_config['model'] = model

        assert openai.load_config(raw_config).use_chat_api is False

    for model in ('gpt-3.5', 'gpt-4'):
        raw_config['model'] = model

        assert openai.load_config(raw_config).use_chat_api is True


def test_url_configuration() -> None:
    raw_config = get_valid_config()

    assert openai.load_config(raw_config).url == 'https://api.openai.com'

    raw_config['url'] = 'http://myhost'

    assert openai.load_config(raw_config).url == 'http://myhost'


def test_main_function_rate_other_error() -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(openai, 'get_openai_completion') as compl_mock:

        compl_mock.side_effect = urllib.error.HTTPError(
            url='',
            msg='',
            hdrs=mock.Mock(),
            fp=None,
            code=500,
        )
        readline_mock.return_value = json.dumps({
            "config": get_valid_config(),
            "prompt": "hello there",
        })

        with pytest.raises(urllib.error.HTTPError):
            openai.main()


@pytest.mark.parametrize(['api_key', 'expected_headers'], [
    pytest.param(
        'sk-fake',
        {
            'Authorization': 'Bearer sk-fake',
            'Content-type': 'application/json',
        },
        id='authenticated',
    ),
    pytest.param(
        '',
        {'Content-type': 'application/json'},
        id='unauthenticated',
    ),
])
def test_openai_authentication(
    api_key: str,
    expected_headers: dict[str, str],
) -> None:
    result_data = b'data: [DONE]\n\n'

    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(urllib.request, 'urlopen') as urlopen_mock:

        urlopen_mock.return_value.__enter__.return_value = BytesIO(result_data)

        readline_mock.return_value = json.dumps({
            "config": get_valid_config(api_key=api_key),
            "prompt": "hello there",
        })
        openai.main()

        assert urlopen_mock.mock_calls[0][1][0].headers == expected_headers


def test_print_openai_completion_results() -> None:
    result_data = (
        b'data: {"id": "cmpl-6jMlRJtbYTGrNwE6Lxy1Ns1EtD0is", "object": "text_completion", "created": 1676270285, "choices": [{"text": "\\n", "index": 0, "logprobs": null, "finish_reason": null}], "model": "gpt-3.5-turbo-instruct"}\n'  # noqa
        b'\n'
        b'data: {"id": "cmpl-6jMlRJtbYTGrNwE6Lxy1Ns1EtD0is", "object": "text_completion", "created": 1676270285, "choices": [{"text": "\\n", "index": 0, "logprobs": null, "finish_reason": null}], "model": "gpt-3.5-turbo-instruct"}\n'  # noqa
        b'\n'
        b'data: {"id": "cmpl-6jMlRJtbYTGrNwE6Lxy1Ns1EtD0is", "object": "text_completion", "created": 1676270285, "choices": [{"text": "Hello", "index": 0, "logprobs": null, "finish_reason": null}], "model": "gpt-3.5-turbo-instruct"}\n'  # noqa
        b'\n'
        b'data: {"id": "cmpl-6jMlRJtbYTGrNwE6Lxy1Ns1EtD0is", "object": "text_completion", "created": 1676270285, "choices": [{"text": "!", "index": 0, "logprobs": null, "finish_reason": null}], "model": "gpt-3.5-turbo-instruct"}\n'  # noqa
        b'\n'
        b'data: {"id": "cmpl-6jMlRJtbYTGrNwE6Lxy1Ns1EtD0is", "object": "text_completion", "created": 1676270285, "choices": [{"text": "", "index": 0, "logprobs": null, "finish_reason": "stop"}], "model": "gpt-3.5-turbo-instruct"}\n'  # noqa
        b'\n'
        b'data: [DONE]\n'
        b'\n'
    )

    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(urllib.request, 'urlopen') as urlopen_mock, \
        mock.patch('builtins.print') as print_mock:

        urlopen_mock.return_value.__enter__.return_value = BytesIO(result_data)

        readline_mock.return_value = json.dumps({
            "config": get_valid_config("gpt-3.5-turbo-instruct"),
            "prompt": "hello there",
        })
        openai.main()

    assert print_mock.call_args_list == [
        mock.call('\n', end='', flush=True),
        mock.call('\n', end='', flush=True),
        mock.call('Hello', end='', flush=True),
        mock.call('!', end='', flush=True),
        mock.call('', end='', flush=True),
        mock.call(),
    ]


def test_print_openai_chat_completion_results() -> None:
    result_data = (
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"role":"assistant"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"\\n\\n"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"This"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" is"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" a"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" test"},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"."},"index":0,"finish_reason":null}]}\n'  # noqa
        b'\n'
        b'data: {"id":"chatcmpl-6tMwjovREOTA84MkGBOS5rWyj1izv","object":"chat.completion.chunk","created":1678654265,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{},"index":0,"finish_reason":"length"}]}\n'  # noqa
        b'\n'
        b'data: [DONE]\n'
        b'\n'
    )

    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(urllib.request, 'urlopen') as urlopen_mock, \
        mock.patch('builtins.print') as print_mock:

        urlopen_mock.return_value.__enter__.return_value = BytesIO(result_data)

        readline_mock.return_value = json.dumps({
            "config": get_valid_config("gpt-3.5-turbo-0301"),
            "prompt": "Say this is a test",
        })
        openai.main()

    assert print_mock.call_args_list == [
        mock.call('\n\n', end='', flush=True),
        mock.call('This', end='', flush=True),
        mock.call(' is', end='', flush=True),
        mock.call(' a', end='', flush=True),
        mock.call(' test', end='', flush=True),
        mock.call('.', end='', flush=True),
        mock.call(),
    ]


def test_main_function_bad_config() -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(openai, 'load_config') as load_config_mock:

        load_config_mock.side_effect = ValueError("expect this")
        readline_mock.return_value = json.dumps({"config": {}})

        with pytest.raises(SystemExit) as exc:
            openai.main()

    assert str(exc.value) == 'expect this'


@pytest.mark.parametrize(
    'code, error_text, expected_message',
    (
        pytest.param(
            429,
            json.dumps({
                'error': {
                    'message': "Your token is bad",
                },
            }),
            'OpenAI request limit reached: Your token is bad',
            id="request_limit",
        ),
        pytest.param(
            400,
            '{]',
            'OpenAI request failure: {]',
            id="error_with_mangled_json",
        ),
        pytest.param(
            400,
            json.dumps({'error': {}}),
            'OpenAI request failure: {"error": {}}',
            id="error_with_missing_message_key",
        ),
        pytest.param(
            400,
            json.dumps({
                'error': {
                    'message': "This model's maximum context length is 123",
                },
            }),
            'OpenAI request failure: Too much text for a request!',
            id="too_much_text",
        ),
        pytest.param(
            401,
            json.dumps({
                'error': {
                    'message': "Bad authentication error",
                },
            }),
            'OpenAI request failure: Bad authentication error',
            id="unauthorised_failure",
        ),
    ),
)
def test_api_error(
    code: int,
    error_text: str | None,
    expected_message: str,
) -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(openai, 'get_openai_completion') as compl_mock:

        compl_mock.side_effect = urllib.error.HTTPError(
            url='',
            msg='',
            hdrs=mock.Mock(),
            fp=BytesIO(error_text.encode('utf-8')) if error_text else None,
            code=code,
        )

        readline_mock.return_value = json.dumps({
            "config": get_valid_config(),
            "prompt": "hello there",
        })

        with pytest.raises(SystemExit) as exc:
            openai.main()

    assert str(exc.value) == f'Neural error: {expected_message}'
