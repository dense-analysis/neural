from getpass import getuser


def get_tmp_path_suffix() -> str:
    try:
        user = getuser()
    except Exception:
        return ''

    return f'.{hash(user)}'
