" Author: Anexon <anexon@protonmail.com>
" Description: A Neural Scratch Buffer acts as a playground for interacting with
" Neural sources directly, sending all content of the buffer to the source.

scriptencoding utf-8

call neural#config#Load()

function! s:GetOptions(options_dict_string) abort
    call neural#config#Load()

    " TODO: Set buffer name based on source.
    let l:options = {
    \   'name': 'Neural Buffer',
    \   'create_mode': g:neural.buffer.create_mode,
    \   'wrap': g:neural.buffer.wrap,
    \}

    " Override default options for the buffer instance.
    if !empty(a:options_dict_string)
        let l:options_dict = eval(a:options_dict_string)

        if has_key(l:options_dict, 'name')
            let l:options.name = l:options_dict.name
        endif

        if has_key(l:options_dict, 'create_mode')
            let l:options.create_mode = l:options_dict.create_mode
        endif

        if has_key(l:options_dict, 'wrap')
            let l:options.wrap = l:options_dict.wrap
        endif
    endif

    return l:options
endfunction

function! neural#buffer#CreateBuffer(options) abort
    let l:buffer_options = s:GetOptions(a:options)

    " TODO: Add auto incrementing buffer names instead of switching.
    if bufexists(l:buffer_options.name)
        execute 'buffer' bufnr(l:buffer_options.name)
    else
        if l:buffer_options.create_mode is# 'vertical'
            vertical new
        elseif l:buffer_options.create_mode is# 'horizontal'
            new
        else
            call neural#OutputErrorMessage('Invalid create mode for Neural Buffer. Must be horizontal or vertical.')
        endif

        if l:buffer_options.wrap
            setlocal wrap linebreak
        else
            setlocal nowrap nolinebreak
        endif

        execute 'file ' . escape(l:buffer_options.name, ' ')
        setlocal filetype=neuralbuf
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
    endif

    " Switch into insert mode when entering the buffer
    startinsert
endfunction

function! neural#buffer#RunBuffer() abort
    let l:buffer_contents = join(getline(1, '$'), "\n")
    let l:options = {
    \   'line': line('$'),
    \   'echo': 0,
    \}

    if &filetype is# 'neuralbuf'
        call neural#Run(l:buffer_contents, l:options)
    endif
endfunction
