import json
import sys
import urllib.error
import urllib.request
from io import BytesIO
from typing import Any, Dict, Optional, cast
from unittest import mock

import pytest

from neural_providers import openai


def get_valid_config() -> Dict[str, Any]:
    return {
        "api_key": ".",
        "model": "foo",
        "prompt": "say hello",
        "temperature": 1,
        "top_p": 1,
        "max_tokens": 1,
        "presence_penalty": 1,
        "frequency_penalty": 1,
    }


def test_load_config_errors():
    with pytest.raises(ValueError) as exc:
        openai.load_config(cast(Any, 0))

    assert str(exc.value) == "openai config is not a dictionary"

    config: Dict[str, Any] = {}

    for modification, expected_error in [
        ({}, "openai.api_key is not defined"),
        ({"api_key": ""}, "openai.api_key is not defined"),
        ({"api_key": "."}, "openai.model is not defined"),
        ({"model": ""}, "openai.model is not defined"),
        (
            {"model": "x", "temperature": "x"},
            "openai.temperature is invalid"
        ),
        (
            {"temperature": 1, "top_p": "x"},
            "openai.top_p is invalid"
        ),
        (
            {"top_p": 1, "max_tokens": "x"},
            "openai.max_tokens is invalid"
        ),
        (
            {"max_tokens": 1, "presence_penalty": "x"},
            "openai.presence_penalty is invalid"
        ),
        (
            {"presence_penalty": 1, "frequency_penalty": "x"},
            "openai.frequency_penalty is invalid"
        ),
    ]:
        config.update(modification)

        with pytest.raises(ValueError) as exc:
            openai.load_config(config)

        assert str(exc.value) == expected_error, config


def test_main_function_rate_other_error():
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(openai, 'get_openai_completion') as completion_mock:

        completion_mock.side_effect = urllib.error.HTTPError(
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


def test_print_openai_results():
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
            "config": get_valid_config(),
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


def test_main_function_bad_config():
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
            json.dumps({'error': {}}),
            '{"error": {}}',
            id="request_limit",
        ),
        pytest.param(
            400,
            '{]',
            '{]',
            id="error_with_mangled_json",
        ),
        pytest.param(
            400,
            json.dumps({'error': {}}),
            '{"error": {}}',
            id="error_with_missing_message_key",
        ),
        pytest.param(
            400,
            json.dumps({
                'error': {
                    'message': "This model's maximum context length is 123",
                },
            }),
            'Too much text for a request!',
            id="too_much_text",
        ),
        pytest.param(
            401,
            json.dumps({
                'error': {
                    'message': "Bad authentication error",
                },
            }),
            'Bad authentication error',
            id="unauthorised_failure",
        ),
    )
)
def test_api_error(
    code: int,
    error_text: Optional[str],
    expected_message: str,
):
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

    assert str(exc.value) == f'Neural error [OpenAI]: {expected_message}'
