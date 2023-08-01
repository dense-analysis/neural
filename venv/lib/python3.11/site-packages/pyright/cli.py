import os
import sys
import logging
import subprocess
from typing import List, NoReturn, Union, Tuple, Any

from . import __pyright_version__, node
from .utils import env_to_bool, get_latest_version
from .errors import VersionCheckFailed


__all__ = (
    'run',
    'main',
)

log: logging.Logger = logging.getLogger(__name__)


def main(args: List[str], **kwargs: Any) -> int:
    return run(*args, **kwargs).returncode


def run(
    *args: str, **kwargs: Any
) -> Union['subprocess.CompletedProcess[bytes]', 'subprocess.CompletedProcess[str]']:
    version = os.environ.get('PYRIGHT_PYTHON_FORCE_VERSION', __pyright_version__)
    if version == 'latest':
        version = node.latest('pyright')
    else:
        if _should_warn_version(version, args=args):
            print(
                f'WARNING: there is a new pyright version available (v{__pyright_version__} -> v{get_latest_version()}).\n'
                + 'Please install the new version or set PYRIGHT_PYTHON_FORCE_VERSION to `latest`\n'
            )

    try:
        npx = node.version('npx')
    except VersionCheckFailed:
        if not env_to_bool('PYRIGHT_PYTHON_IGNORE_NPX_CHECK', default=False):
            raise

        log.debug('Ignoring failed version check for npx, defaulting to v7')
        npx = (7,)

    if npx[0] >= 7:
        pre_args = ['--yes']

        if not env_to_bool('PYRIGHT_PYTHON_VERBOSE', default=False):
            pre_args.insert(0, '--silent')
    else:
        pre_args = []

    if args and pre_args:
        pre_args = (*pre_args, '--')

    return node.run('npx', *pre_args, f'pyright@{version}', *args, **kwargs)


def _should_warn_version(version: str, args: Tuple[object]) -> bool:
    if '--outputjson' in args:
        # If this flag is set then the output must be machine parseable
        return False

    if env_to_bool('PYRIGHT_PYTHON_VERBOSE', default=False) or env_to_bool(
        'PYRIGHT_PYTHON_IGNORE_WARNINGS', default=False
    ):
        return False

    # NOTE: there is an edge case here where a new pyright version has been released
    # but we haven't made a new pyright-python release yet and the user has set
    # PYRIGHT_PYTHON_FORCE_VERSION to the new pyright version.
    # This should rarely happen as we make new releases very frequently after
    # pyright does. Also in order to correctly compare versions we would need an additional
    # dependency. As such this is an acceptable bug.
    latest = get_latest_version()
    return latest is not None and latest != version


def entrypoint() -> NoReturn:
    sys.exit(main(sys.argv[1:]))
