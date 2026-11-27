from contextlib import redirect_stdout
from io import StringIO


def check_version():
    from yt_dlp import main

    output = StringIO()
    with redirect_stdout(output):
        try:
            main(["--ignore-config", "--version"])
        except SystemExit as exit_status:
            if exit_status.code != 0:
                raise RuntimeError(f"yt-dlp exited with status {exit_status.code}") from exit_status

    return output.getvalue().strip()
