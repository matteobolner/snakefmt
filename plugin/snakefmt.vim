" Author: Brice Letcher
" Requires: Vim Ver7.0+
" Version:  1.1
"
" Documentation:
"   This plugin formats Snakemake files.
"   It is inspired by black's vim plugin for Python: https://github.com/psf/black/blob/master/plugin/black.vim. Credit to its author Łukasz Langa.
"
" History:
"  1.1:
"    - Isolated import try block to snakefmt, formatted with black
"  1.0:
"    - initial version

if exists("g:load_snakefmt")
   finish
endif

python3 << EndPython3
import sys
import vim
import time
from io import StringIO

try:
    from snakefmt import __version__ as snakefmt_version
except ModuleNotFoundError:
    error_message = "snakefmt not found. Is snakefmt installed?"

    def Snakefmt():
        print(error_message)

    def SnakefmtVersion():
        print(error_message)


else:
    from snakefmt.config import (
        read_snakefmt_config,
        find_pyproject_toml,
        DEFAULT_LINE_LENGTH,
    )
    from snakefmt.formatter import Formatter
    from snakefmt.parser.parser import Snakefile

    def Snakefmt():
        start = time.time()
        source_file = (vim.eval("expand('%:p')"),)
        pyproject_toml = find_pyproject_toml(source_file)
        config = read_snakefmt_config(pyproject_toml)
        line_length = config.get("line_length", None)

        buffer_str = "\n".join(vim.current.buffer) + "\n"
        try:
            snakefile = Snakefile(StringIO(buffer_str))
            formatter = Formatter(
                snakefile, line_length=line_length, black_config_file=pyproject_toml
            )
            new_buffer_str = formatter.get_formatted()
        except Exception as exc:
            print(exc)
        else:
            current_buffer = vim.current.window.buffer
            cursors = []
            for i, tabpage in enumerate(vim.tabpages):
                if tabpage.valid:
                    for j, window in enumerate(tabpage.windows):
                        if window.valid and window.buffer == current_buffer:
                            cursors.append((i, j, window.cursor))
            vim.current.buffer[:] = new_buffer_str.split("\n")[:-1]
            for i, j, cursor in cursors:
                window = vim.tabpages[i].windows[j]
                try:
                    window.cursor = cursor
                except vim.error:
                    window.cursor = (len(window.buffer), 0)
            print(f"Reformatted with snakefmt in {time.time() - start:.4f}s.")

    def SnakefmtVersion():
        print(f"snakefmt version {snakefmt_version} on Python {sys.version}.")

EndPython3

let g:load_snakefmt = "py1.0"

command! Snakefmt :py3 Snakefmt()
command! SnakefmtVersion :py3 SnakefmtVersion()
