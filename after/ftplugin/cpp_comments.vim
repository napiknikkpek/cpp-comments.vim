
onoremap <buffer><expr> ic cpp_comments#inner_expr()
onoremap <buffer><expr> ac cpp_comments#outer_expr()
vnoremap <buffer><expr> ic cpp_comments#inner_expr()
vnoremap <buffer><expr> ac cpp_comments#outer_expr()

nnoremap <buffer> gcu :<C-u>call cpp_comments#del()<cr>
nnoremap <buffer> gc :<C-u>set opfunc=cpp_comments#set<cr>g@
nmap <buffer> gcc 0gc$
vnoremap <buffer> gc :<C-u>call cpp_comments#set('visual')<cr>
