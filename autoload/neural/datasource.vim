" Author: w0rp <dev@w0rp.com>
" Description: Functions for discovering and loading Neural datasources

let s:supported_script_languages = ['python']
let s:datasources = []
let s:runtime_loaded = 0

function! neural#datasource#PreProcess(datasource) abort
    if type(a:linter) isnot v:t_dict
        throw 'The datasource object must be a Dictionary'
    endif

    let l:obj = {
    \   'name': get(a:datasource, 'name'),
    \   'script_language': get(a:datasource, 'script_language'),
    \   'script': get(a:datasource, 'script'),
    \}

    if type(l:obj.name) isnot v:t_string
        throw '`name` must be defined to name the datasource'
    endif

    if type(l:obj.script_language) isnot v:t_string
        throw '`script_language` must be defined for the datasource'
    endif

    if index(s:supported_script_languages, l:obj.script_language) < 0
        throw '`script_language` must be one of: '
        \   . join(s:supported_script_languages, ', ')
    endif

    if type(l:obj.script) isnot v:t_string
        throw '`script` must be defined for the datasource'
    endif

    return l:obj
endfunction

function! neural#datasource#Define(datasource) abort
    " This command will throw from the sandbox.
    let &l:equalprg=&l:equalprg

    let l:new_datasource = neural#datasource#PreProcess(a:datasource)

    " Remove previously defined datasources with the same name.
    call filter(s:datasources, 'v:val.name isnot# a:datasource.name')
    call add(s:datasources, l:new_datasource)
endfunction

" Load all Neural datasources.
function! neural#datasource#LoadAll() abort
    if !s:runtime_loaded
        execute 'silent! runtime! neural_datasources/*.vim'
        let s:runtime_loaded = 1
    endif
endfunction

" Get a specific datasource by name.
function! neural#datasource#Get(name) abort
    call neural#datasource#LoadAll()

    for l:source in s:datasources
        if l:source.name is# a:name
            return l:source
        endif
    endfor

    throw 'datasource named ' . string(a:name) . ' not found!'
endfunction
