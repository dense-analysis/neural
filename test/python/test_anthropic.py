import json
import urllib.error
import urllib.request
from io import BytesIO
from typing import Any, Dict, Optional, cast
from unittest import mock

import pytest
import sys

from neural_providers import anthropic


def get_valid_config() -> Dict[str, Any]:
    return {
        "api_key": ".",
        "model": "foo",
        "temperature": 1,
        "top_p": 1,
        "max_tokens": 1,
    }


def test_load_config_errors() -> None:
    with pytest.raises(ValueError) as exc:
        anthropic.load_config(cast(Any, 0))

    assert str(exc.value) == "anthropic config is not a dictionary"

    config: Dict[str, Any] = {}

    for modification, expected_error in [
        ({}, "anthropic.api_key is not defined"),
        ({"api_key": ""}, "anthropic.api_key is not defined"),
        ({"api_key": "."}, "anthropic.model is not defined"),
        ({"model": ""}, "anthropic.model is not defined"),
        ({"model": "x", "temperature": "x"}, "anthropic.temperature is invalid"),
        ({"temperature": 1, "top_p": "x"}, "anthropic.top_p is invalid"),
        ({"top_p": 1, "max_tokens": "x"}, "anthropic.max_tokens is invalid"),
    ]:
        config.update(modification)

        with pytest.raises(ValueError) as exc:
            anthropic.load_config(config)

        assert str(exc.value) == expected_error, config


def test_main_function_rate_other_error() -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(anthropic, 'get_claude_completion') as compl_mock:

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
            anthropic.main()


def test_print_anthropic_results() -> None:
    result_data = (
        b'data: {"completion":"Hi"}\n'  # noqa
        b'\n'
        b'data: {"completion":"!"}\n'  # noqa
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
        anthropic.main()

    assert print_mock.call_args_list == [
        mock.call('Hi', end='', flush=True),
        mock.call('!', end='', flush=True),
        mock.call(),
    ]


def test_main_function_bad_config() -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(anthropic, 'load_config') as load_config_mock:

        load_config_mock.side_effect = ValueError("expect this")
        readline_mock.return_value = json.dumps({"config": {}})

        with pytest.raises(SystemExit) as exc:
            anthropic.main()

    assert str(exc.value) == 'expect this'


@pytest.mark.parametrize(
    'code, error_text, expected_message',
    (
        pytest.param(
            429,
            None,
            'Anthropic request limit reached!',
            id="request_limit",
        ),
        pytest.param(
            400,
            '{]',
            'Anthropic request failure: {]',
            id="error_with_mangled_json",
        ),
        pytest.param(
            400,
            json.dumps({'error': {}}),
            'Anthropic request failure: {"error": {}}',
            id="error_with_missing_message_key",
        ),
        pytest.param(
            401,
            json.dumps({'error': {'message': 'Bad authentication error'}}),
            'Anthropic request failure: Bad authentication error',
            id="unauthorised_failure",
        ),
    )
)
def test_api_error(
    code: int,
    error_text: Optional[str],
    expected_message: str,
) -> None:
    with mock.patch.object(sys.stdin, 'readline') as readline_mock, \
        mock.patch.object(anthropic, 'get_claude_completion') as compl_mock:

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
            anthropic.main()

    assert str(exc.value) == f'Neural error: {expected_message}'
