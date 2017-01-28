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

fu! s:inside(pos)
  if index(['cComment', 'cCommentStart'], s:syname(a:pos)) != -1
    return v:true
  endif
  if s:col(a:pos) <= strlen(getline(s:line(a:pos)))
    return v:false
  endif
  let cur = getpos('.')
  call setpos('.', a:pos) 
  call search('.', 'bW')
  let pr = getpos('.')
  let sn = s:syname(pr)
  let ch = s:char(pr)
  call setpos('.', cur)
  if sn == 'cComment'
    return v:true
  elseif sn == 'cCommentStart'
    return ch != '/'
  else
    return v:false
  endif
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

fu! cpp_comments#inner()
  normal vv
  call s:tostart()
  call s:next()
  call s:next()
  normal m<
  call search('\*\/', 'e')
  call s:prev()
  call s:prev()
  normal m>gv
endfu

fu! cpp_comments#inner_expr()
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

fu! cpp_comments#outer()
  call s:tostart()
  normal! vl]*
endfu

fu! cpp_comments#outer_expr()
  if !s:inside(getpos('.'))
    return s:exit_expr()
  endif
  return ":\<C-u>call cpp_comments#outer()\<cr>"
endfu

fu! cpp_comments#set(mode)
  if a:mode == 'visual'
    if visualmode() == 'v'
      let b = getpos("'<")
      let e = getpos("'>")
    elseif visualmode() == 'V'
      let b = getpos("'<")
      let b[2] = 1
      let e = getpos("'>")
      let e[2] = strlen(getline("'>"))
    endif
  elseif a:mode == 'line'
    let b = getpos("'[")
    let b[2] = 1
    let e = getpos("']")
    let e[2] = strlen(getline("']"))
  elseif a:mode == 'char'
    let b = getpos("'[")
    let e = getpos("']")
  endif

  if !exists('b') || !exists('e')
    return
  endif
  if s:less(e, b)
    let e = b
  endif

  if s:inside(b)
    call s:warn('[comments] intersect existing comment')
    return
  endif
  let cur = getpos('.')
  call setpos('.', b)
  while search('\/\*', 'W', s:line(e))
    if (!s:less(e, getpos('.')))
          \&& s:inside(getpos('.'))
      call setpos('.', cur)
      call s:warn('[comments] intersect existing comment')
      return
    endif
  endwhile
  normal vv
  call setpos("'<", b)
  call setpos("'>", e)
  set paste 
  exe 'normal! gvc'
        \."\<C-o>".':let @" = ''/*''.@".''*/'''."\<cr>"
        \."\<C-r>\""
  set nopaste
endfu

fu! cpp_comments#del() abort
  let cur = getpos('.')
  if s:syname(cur) == 'cCommentL'
    s/\/\///  
  endif
  if !s:inside(cur)
    return
  endif
  call s:tostart()
  set paste
  exe 'normal cac'
        \."\<C-o>".':let @" = strpart(@", 2, strlen(@")-4)'."\<cr>"
        \."\<C-r>\""
  set nopaste
endfu
