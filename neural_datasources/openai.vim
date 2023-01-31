" Define the openai datasource.
call neural#datasource#Define({
\   'name': 'openai',
\   'script_language': 'python',
\   'script': expand('<sfile>:p:h') . '/openai.py',
\})
