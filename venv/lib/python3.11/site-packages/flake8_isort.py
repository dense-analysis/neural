import warnings
from contextlib import redirect_stdout
from difflib import unified_diff
from io import StringIO
from pathlib import Path

import isort
from pkg_resources import DistributionNotFound, get_distribution


def _version():
    try:
        return get_distribution('flake8_isort').version
    except DistributionNotFound:
        return 'dev'  # for local development if package is not installed yet


class Flake8IsortBase:
    name = 'flake8_isort'
    version = _version()
    isort_unsorted = 'I001 isort found an import in the wrong position'
    no_config_msg = 'I002 no configuration found (.isort.cfg or [isort] in configs)'
    isort_blank_req = 'I003 isort expected 1 blank line in imports, found 0'
    isort_blank_unexp = 'I004 isort found an unexpected blank line in imports'
    isort_add_unexp = 'I005 isort found an unexpected missing import'

    show_traceback = False
    no_skip_gitignore = False
    stdin_display_name = None
    search_current = True

    def __init__(self, tree, filename, lines):
        self.filename = filename
        self.lines = lines

    @staticmethod
    def add_options(option_manager):
        option_manager.add_option(
            '--isort-show-traceback',
            action='store_true',
            parse_from_config=True,
            help='Show full traceback with diff from isort',
        )
        option_manager.add_option(
            '--isort-no-skip-gitignore',
            action='store_true',
            parse_from_config=True,
            help=(
                "Temporarily override the set value of isort's `skip_gitignore` option "
                'with `False`. This can cause flake8-isort to run significantly faster '
                "at the cost of making flake8-isort's behavior differ slightly from "
                'the behavior of `isort --check`.'
            ),
        )

    @classmethod
    def parse_options(cls, option_manager, options, args):
        cls.stdin_display_name = options.stdin_display_name
        cls.show_traceback = options.isort_show_traceback
        cls.no_skip_gitignore = options.isort_no_skip_gitignore


class Flake8Isort5(Flake8IsortBase):
    """class for isort >=5"""

    def run(self):
        if self.filename is not self.stdin_display_name:
            file_path = Path(self.filename)
            settings_path = file_path.parent
        else:
            file_path = None
            settings_path = Path.cwd()
        if self.no_skip_gitignore:
            isort_config = isort.settings.Config(
                settings_path=settings_path, skip_gitignore=False
            )
        else:
            isort_config = isort.settings.Config(settings_path=settings_path)
        input_string = ''.join(self.lines)
        traceback = ''
        isort_changed = False
        input_stream = StringIO(input_string)
        output_stream = StringIO()
        isort_stdout = StringIO()
        try:
            with redirect_stdout(isort_stdout):
                isort_changed = isort.api.sort_stream(
                    input_stream=input_stream,
                    output_stream=output_stream,
                    config=isort_config,
                    file_path=file_path,
                )
        except isort.exceptions.FileSkipped:
            pass
        except isort.exceptions.ISortError as e:
            warnings.warn(e)
        if isort_changed:
            outlines = output_stream.getvalue()
            diff_delta = ''.join(
                unified_diff(
                    input_string.splitlines(keepends=True),
                    outlines.splitlines(keepends=True),
                    fromfile=f'{self.filename}:before',
                    tofile=f'{self.filename}:after',
                )
            )
            traceback = f'{isort_stdout.getvalue()}\n{diff_delta}'
            for line_num, message in self.isort_linenum_msg(diff_delta):
                if self.show_traceback:
                    message += traceback
                yield line_num, 0, message, type(self)

    def isort_linenum_msg(self, udiff):
        """Parse unified diff for changes and generate messages

        Args
        ----
        udiff : unified diff delta

        Yields
        ------
        tuple: A tuple of the specific isort line number and message.
        """
        line_num = 0
        additions = []
        moves = []
        for line in udiff.splitlines():
            if line.startswith('@@', 0, 2):
                line_num = int(line[4:].split(' ')[0].split(',')[0])
                continue
            elif not line_num:  # skip lines before first hunk
                continue
            if line.startswith(' ', 0, 1):
                line_num += 1  # Ignore unchanged lines but increment line_num.
            elif line.startswith('-', 0, 1):
                if line.strip() == '-':
                    yield line_num, self.isort_blank_unexp
                    line_num += 1
                else:
                    moves.append(line[1:])
                    yield line_num, self.isort_unsorted
                    line_num += 1
            elif line.startswith('+', 0, 1):
                if line.strip() == '+':
                    # Include newline additions but do not increment line_num.
                    yield line_num, self.isort_blank_req
                else:
                    additions.append((line_num, line))

        # return all additions that did not move
        for line_num, line in additions:
            if not line[1:] in moves:
                yield line_num, self.isort_add_unexp


Flake8Isort = Flake8Isort5
