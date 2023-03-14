scriptencoding utf-8

function! neural#buffer#CreateBuffer() abort
    " TODO: Customise buffer options
    vertical new
    setlocal wrap linebreak

    file Neural Buffer
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal filetype=neuralbuf

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

