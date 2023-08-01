import os
import subprocess
import sys
import json
import tempfile
from pathlib import Path
from typing import Any, NoReturn, Union

from . import node, __pyright_version__
from ._utils import get_tmp_path_suffix


def get_temp_dir() -> Path:
    return (
        Path(tempfile.gettempdir())
        / f'pyright-python-langserver{get_tmp_path_suffix()}'
    )


TEMP_DIR = get_temp_dir()


def main(*args: str, **kwargs: Any) -> int:
    return run(*args, **kwargs).returncode


def run(
    *args: str,
    **kwargs: Any,
) -> Union['subprocess.CompletedProcess[bytes]', 'subprocess.CompletedProcess[str]']:
    TEMP_DIR.mkdir(exist_ok=True, parents=True)

    version = os.environ.get('PYRIGHT_PYTHON_FORCE_VERSION', __pyright_version__)
    if version == 'latest':
        version = node.latest('pyright')

    pkg = TEMP_DIR / 'node_modules' / 'pyright' / 'package.json'
    if pkg.exists():
        current_version = json.loads(pkg.read_text()).get('version')
    else:
        current_version = None

    # TODO: use the same install location as the pyright CLI
    if current_version is None or current_version != version:
        node.run('npm', 'init', "-y", cwd=str(TEMP_DIR), check=True)
        node.run('npm', 'install', f'pyright@{version}', cwd=str(TEMP_DIR), check=True)

    binary = TEMP_DIR / 'node_modules' / 'pyright' / 'langserver.index.js'
    if not binary.exists():
        raise RuntimeError(f'Expected language server entrypoint: {binary} to exist')

    return node.run('node', str(binary), '--', *args, **kwargs)


def entrypoint() -> NoReturn:
    sys.exit(main(*sys.argv[1:]))


if __name__ == '__main__':
    entrypoint()
