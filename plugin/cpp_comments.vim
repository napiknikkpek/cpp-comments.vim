
fu! s:mappings()
  onoremap <buffer><expr> ic cpp_comments#inner_expr()
  onoremap <buffer><expr> ac cpp_comments#outer_expr()
  vnoremap <buffer><expr> ic cpp_comments#inner_expr()
  vnoremap <buffer><expr> ac cpp_comments#outer_expr()

  nnoremap <buffer> gcu :<C-u>call cpp_comments#del()<cr>
  nnoremap <buffer> gc :<C-u>set opfunc=cpp_comments#set<cr>g@
  nnoremap <buffer> gcc :<C-u>call cpp_comments#set_line()<cr>
  vnoremap <buffer> gc :<C-u>call cpp_comments#set(visualmode())<cr>
endfu

augroup cpp-comments
  autocmd!
  autocmd FileType c,cpp call s:mappings()
  autocmd FileType c,cpp :setlocal commentstring=//%s
augroup END
