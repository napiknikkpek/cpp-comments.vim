
fu! s:mappings()
  onoremap <buffer><expr> ic cpp#comments#inner_expr()
  onoremap <buffer><expr> ac cpp#comments#outer_expr()
  vnoremap <buffer><expr> ic cpp#comments#inner_expr()
  vnoremap <buffer><expr> ac cpp#comments#outer_expr()

  nnoremap <buffer> gcu :<C-u>call cpp#comments#del()<cr>
  nnoremap <buffer> gc :<C-u>set opfunc=cpp#comments#set<cr>g@
  nnoremap <buffer> gcc :<C-u>call cpp#comments#set_line()<cr>
  vnoremap <buffer> gc :<C-u>call cpp#comments#set(visualmode())<cr>

  let &l:commentstring='//%s'
endfu

augroup cpp-comments
  autocmd!
  autocmd FileType c,cpp call s:mappings()
augroup END
