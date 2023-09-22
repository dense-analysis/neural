" Author: w0rp <devw0rp@gmail.com>
" Description: Redact passwords and secrets from code.

" This will never be a perfect implementation, but effort can be made.
"
" The regex to use for keys in objects.
let s:key_regex = 'password|secret[_ ]?key'
" This substitution will be applied for each of the s:key_value_groups.
let s:key_value_sub = '\1\3*\4'
" Regular expressions to replace with s:key_value_sub
let s:key_value_groups = map(
\   [
\       '("(KEYS)")( *[=:]+ *r?")[^"]+(")',
\       '("(KEYS)")( *[=:]+ *r?'')[^'']+('')',
\       '(''(KEYS)'')( *[=:]+ *r?'')[^'']+('')',
\       '(''(KEYS)'')( *[=:]+ *r?")[^"]+(")',
\       '((KEYS))( *[=:]+ *r?")[^"]+(")',
\       '((KEYS))( *[=:]+ *r?'')[^'']+('')',
\       '((KEYS))( *[=:]+ *r?`)[^`]+(`)',
\   ],
\   {_, template -> '\v\c' . substitute(template, 'KEYS', s:key_regex, '')}
\)

function! neural#redact#PasswordsAndSecrets(unredacted) abort
    let l:line_list = []

    for l:line in a:unredacted
        for l:regex in s:key_value_groups
            let l:line = substitute(l:line, l:regex, s:key_value_sub, 'g')
        endfor

        call add(l:line_list, l:line)
    endfor

    return l:line_list
endfunction
