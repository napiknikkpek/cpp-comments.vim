fu! s:line(pos)
  return a:pos[1]
endfu

fu! s:col(pos)
  return a:pos[2]
endfu

fu! s:char(pos)
  return getline(s:line(a:pos))[s:col(a:pos)-1]
endfu

fu! s:less(lhs, rhs)
  return s:line(a:lhs) < s:line(a:rhs)
        \|| s:line(a:lhs) == s:line(a:rhs) && s:col(a:lhs) < s:col(a:rhs)
endfu

let s:intersect_msg = '[comments] intersect existing comment'
fu! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfu

fu! s:next()
  call search('\_.', 'W')
endfu

fu! s:prev()
  call search('\_.', 'bW')
endfu

fu! s:syname(pos)
  return synIDattr(synID(s:line(a:pos), s:col(a:pos), 1), 'name')
endfu

fu! s:insideL(pos)
  return s:syname(a:pos) == 'cCommentL'
endfu

fu! s:inside(pos)
  if s:syname(a:pos) =~# '^cComment\(\|Start\|StartError\)$'
    return v:true
  endif
  if s:col(a:pos) <= strlen(getline(s:line(a:pos)))
    return v:false
  endif
  let cur = getpos('.')
  call setpos('.', a:pos) 
  call search('.', 'bW')
  let syn = s:syname(getpos('.'))
  let ch = s:char(getpos('.'))
  call setpos('.', cur)
  if syn == 'cComment'
    return v:true
  elseif syn == 'cCommentStart'
    return ch != '/'
  else
    return v:false
  endif
endfu

fu! s:tostartL()
  let lnum = line('.')
  while search('\/\/', 'cb', lnum)
    if col('.') == 0
      break
    elseif s:syname([0, lnum, col('.')-1, 0]) != 'cCommentL'
      break
    endif
    normal! h
  endw
endfu

fu! s:tostart()
  let cur = getpos('.')
  if s:syname(cur) == 'cCommentStart' && s:char(cur) == '/'
    call search('.', 'W')
    let next = getpos('.')
    call setpos('.', cur)
    if s:char(next) == '*' && s:syname(next) == 'cCommentStart'
      return
    endif
  endif
  while search('\/\*', 'bW')
    if s:syname(getpos('.')) == 'cCommentStart'
      return
    endif
  endwhile
endfu

fu! s:exit_expr()
  return index(['v', 'V', "<CTRL-V>"], mode()) != -1 ? '' : '<Esc>'
endfu

fu! cpp_comments#innerL()
  call s:tostartL()
  normal! 2lvg_
endfu

fu! cpp_comments#inner()
  normal! vv
  call s:tostart()
  call s:next()
  call s:next()
  normal! m<
  call search('\*\/', 'e')
  call s:prev()
  call s:prev()
  normal! m>gv
endfu

fu! cpp_comments#inner_expr()
  if s:insideL(getpos('.'))
    call s:tostartL()
    let sz = strlen(getline('.'))
    if col('.')+1 == sz
      return s:exit_expr()
    endif
    return ":\<C-u>call cpp_comments#innerL()\<cr>"
  endif
  if !s:inside(getpos('.'))
    return s:exit_expr()
  endif
  call s:tostart()
  call s:next()
  call s:next()
  if s:syname(getpos('.')) == 'cCommentStart'
    return s:exit_expr()
  endif
  return ":\<C-u>call cpp_comments#inner()\<cr>"
endfu

fu! cpp_comments#outerL()
  call s:tostartL()
  normal! vg_
endfu

fu! cpp_comments#outer()
  call s:tostart()
  normal! vl]*
endfu

fu! cpp_comments#outer_expr()
  if s:insideL(getpos('.'))
    return ":\<C-u>call cpp_comments#outerL()\<cr>"
  endif
  if !s:inside(getpos('.'))
    return s:exit_expr()
  endif
  return ":\<C-u>call cpp_comments#outer()\<cr>"
endfu

fu! cpp_comments#set_line()
  let cur = getpos('.')
  normal ^vacv
  if line("'>") != s:line(cur)
    call s:warn(s:intersect_msg)
    call setpos('.', cur)
    return
  endif
  normal g_vacv
  if line("'<") != s:line(cur)
    call s:warn(s:intersect_msg)
    call setpos('.', cur)
    return
  endif
  exe ":normal \<Plug>CommentaryLine\<cr>"
endfu

fu! cpp_comments#set(mode) abort
  if a:mode == 'v'
    let b = getpos("'<")
    let e = getpos("'>")
  elseif a:mode == 'V'
    let b = getpos("'<")
    let b[2] = 1
    let e = getpos("'>")
    let e[2] = strlen(getline("'>"))
  elseif a:mode == 'line'
    let b = getpos("'[")
    let b[2] = 1
    let e = getpos("']")
    let e[2] = strlen(getline("']"))
  elseif a:mode == 'char'
    let b = getpos("'[")
    let e = getpos("']")
  else
    return
  endif

  if !exists('b') || !exists('e')
    return
  endif
  if s:less(e, b)
    let e = b
  endif

  let cur = getpos('.')
  let intersect = v:false
  if s:inside(b) || s:syname(b) =~# '^cComment'
    let intersect = v:true
  else
    call setpos('.', b)
    if search('\*\/', 'ceW', s:line(e))
          \ && !s:less([0, e[1], e[2]+1, 0], getpos('.'))
      let intersect = v:true
    else
      if s:inside(e) || s:syname(e) =~# '^cComment'
        let intersect = v:true
      endif
    endif
  endif
  
  if intersect
    call s:warn('[comments] intersect existing comment')
    call setpos('.', cur)
    return
  endif

  if a:mode == 'V'
    exe ":normal \<Plug>Commentary\<cr>"
    return
  endif

  normal! vv
  call setpos("'<", b)
  call setpos("'>", e)
  set paste 
  set ei=all
  exe 'normal! gvc'
        \."\<C-o>".':let @" = ''/*''.@".''*/'''."\<cr>"
        \."\<C-r>\""
  set ei=
  set nopaste
endfu

fu! cpp_comments#del() abort
  let cur = getpos('.')
  normal ^
  let start = getpos('.')
  call setpos('.', cur)
  if s:insideL(start)
    exe ":normal \<Plug>Commentary\<Plug>Commentary\<cr>"
    return
  endif

  if !s:inside(cur) && !s:insideL(cur)
    return
  endif
  set paste
  set ei=all
  exe 'normal yiccac'."\<C-r>0"
  set ei=
  set nopaste
endfu
