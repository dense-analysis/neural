" Author: Anexon <anexon@protonmail.com>, w0rp <devw0rp@gmail.com>
" Description: Utils and helpers with API normalised between Neovim/Vim 8 and
" platform independent.

let s:python_script_dir = expand('<sfile>:p:h:h:h') . '/python3'

function! s:IsWindows() abort
    return has('win32') || has('win64')
endfunction

" Return string of full neural python script path.
function! s:GetPythonScript(script) abort
    return s:python_script_dir . '/' . a:script
endfunction

" Return path of python executable.
function! s:GetPython() abort
    " Use the virtual environment if it exists.
    if neural#utils#IsVenvAvailable()
        return s:python_script_dir . '/venv/bin/python3'
    else
        let l:python = ''

        " Try to automatically find Python on Windows, even if not in PATH.
        if s:IsWindows()
            let l:python = expand('~/AppData/Local/Programs/Python/Python3*/python.exe')
        endif

        " Fallback to the system Python path
        if empty(l:python)
            let l:python = 'python3'
        endif

        return l:python
    endif
endfunction

" Check the virtual environment exist.
function! neural#utils#IsVenvAvailable() abort
    let l:venv_dir = s:python_script_dir . '/venv'
    let l:venv_python = l:venv_dir . (s:IsWindows() ? '\Scripts\python.exe' : '/bin/python')

    return isdirectory(l:venv_dir) && filereadable(l:venv_python) && executable(l:venv_python)
endfunction

" Returns python command call for a given neural python script.
function! neural#utils#GetPythonCommand(script) abort
    let l:script = neural#utils#StringEscape(s:GetPythonScript(a:script))
    let l:python = neural#utils#StringEscape(s:GetPython())

    return neural#utils#GetCommand(l:python . ' ' . l:script)
endfunction

" Return a command that should be executed in a subshell.
"
" This fixes issues related to PATH variables, %PATHEXT% in Windows, etc.
" Neovim handles this automatically if the command is a String, but we do
" this explicitly for consistency.
function! neural#utils#GetCommand(command) abort
    if s:IsWindows()
        return 'cmd /s/c "' . a:command . '"'
    endif

    return ['/bin/sh', '-c', a:command]
endfunction

" Return platform independent escaped String.
function! neural#utils#StringEscape(str) abort
    if fnamemodify(&shell, ':t') is? 'cmd.exe'
        " If the string contains spaces, it will be surrounded by quotes.
        " Otherwise, special characters will be escaped with carets (^).
        return substitute(
        \   a:str =~# ' '
        \       ?  '"' .  substitute(a:str, '"', '""', 'g') . '"'
        \       : substitute(a:str, '\v([&|<>^])', '^\1', 'g'),
        \   '%',
        \   '%%',
        \   'g',
        \)
    endif

    return shellescape (a:str)
endfunction
