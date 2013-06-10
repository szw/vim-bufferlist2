" Vim NextBufferList - The Ultimate Buffer List
" Maintainer:   Szymon Wrozynski
" Version:      2.0.8
"
" Installation:
" Place in ~/.vim/plugin/next-bufferlist.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-next-bufferlist.git
"
" License:
" Copyright (c) 2013 Szymon Wrozynski <szymon@wrozynski.com>
" Distributed under the same terms as Vim itself.
" Original plugin code - copyright (c) 2005 Robert Lillack <rob@lillack.de>
" Redistribution in any form with or without modification permitted.
" Licensed under MIT License conditions.
"
" Usage:
" https://github.com/szw/vim-next-bufferlist/blob/master/README.md

if exists('g:next_bufferlist_loaded')
  finish
endif
let g:next_bufferlist_loaded = 1

if !exists('g:next_bufferlist_width')
  let g:next_bufferlist_width = 20
endif

if !exists('g:next_bufferlist_max_width')
  let g:next_bufferlist_max_width = 50
endif

if !exists('g:next_bufferlist_height')
  let g:next_bufferlist_height = 1
endif

if !exists('g:next_bufferlist_max_height')
  let g:next_bufferlist_max_height = 15
endif

if !exists('g:next_bufferlist_show_unnamed')
  let g:next_bufferlist_show_unnamed = 2
endif

if !exists('g:next_bufferlist_show_tab_friends')
  let g:next_bufferlist_show_tab_friends = 1
endif

if !exists('g:next_bufferlist_stick_to_bottom')
  let g:next_bufferlist_stick_to_bottom = 1
endif

if !exists('g:next_bufferlist_set_default_mapping')
    let g:next_bufferlist_set_default_mapping = 1
endif

if !exists('g:next_bufferlist_default_mapping_key')
    let g:next_bufferlist_default_mapping_key = '<F2>'
endif

if !exists('g:next_bufferlist_cyclic_list')
  let g:next_bufferlist_cyclic_list = 1
endif

if !exists('g:next_bufferlist_max_jumps')
  let g:next_bufferlist_max_jumps = 100
endif

command! -nargs=0 -range NextBufferList :call <SID>next_bufferlist_toggle(0)

if g:next_bufferlist_set_default_mapping
  silent! exe 'nnoremap <silent>' . g:next_bufferlist_default_mapping_key . ' :NextBufferList<CR>'
  silent! exe 'vnoremap <silent>' . g:next_bufferlist_default_mapping_key . ' :NextBufferList<CR>'
  silent! exe 'inoremap <silent>' . g:next_bufferlist_default_mapping_key . ' <C-[>:NextBufferList<CR>'
endif

if g:next_bufferlist_show_tab_friends
  au BufEnter * call <SID>add_tab_friend()
endif

let s:next_bufferlist_jumps = []
au BufEnter * call <SID>add_jump()

" toggled the buffer list on/off
function! <SID>next_bufferlist_toggle(internal)
  if !a:internal
    let s:tabfriendstoggle = g:next_bufferlist_show_tab_friends
  endif

  " if we get called and the list is open --> close it
  let buflistnr = bufnr("__NEXT_BUFFERLIST__")
  if bufexists(buflistnr)
    if bufwinnr(buflistnr) != -1
      call <SID>kill(buflistnr, 1)
      return
    else
      call <SID>kill(buflistnr, 0)
      if !a:internal
        let t:next_bufferlist_start_window = winnr()
        let t:next_bufferlist_winrestcmd = winrestcmd()
      endif
    endif
  elseif !a:internal
    let t:next_bufferlist_start_window = winnr()
    let t:next_bufferlist_winrestcmd = winrestcmd()
  endif

  if g:next_bufferlist_stick_to_bottom
    call <SID>horizontal()
  else
    call <SID>vertical()
  endif
endfunction

function! <SID>create_jumplines(bufnumbers, activebufline)
  let buffers = []
  for bufnr in split(a:bufnumbers, ":")
    call add(buffers, str2nr(bufnr))
  endfor

  if s:tabfriendstoggle && exists("t:next_bufferlist_jumps")
    let bufferjumps = t:next_bufferlist_jumps
  else
    let bufferjumps = s:next_bufferlist_jumps
  endif

  let jumplines = []

  for jumpbuf in bufferjumps
    if bufwinnr(jumpbuf) == -1
      let jumpline = index(buffers, jumpbuf)
      if (jumpline >= 0)
        call add(jumplines, jumpline + 1)
      endif
    endif
  endfor

  call add(jumplines, a:activebufline)

  return reverse(<SID>unique_list(jumplines))
endfunction

function! <SID>unique_list(list)
  return filter(copy(a:list), 'index(a:list, v:val, v:key + 1) == -1')
endfunction

function! <SID>horizontal()
  let bufcount = bufnr('$')
  let displayedbufs = 0
  let activebuf = bufnr('')
  let activebufline = 0
  let buflist = ''
  let bufnumbers = ''

  " create the buffer first & set it up
  exec 'silent! new __NEXT_BUFFERLIST__'
  silent! exe "wincmd J"
  silent! exe "resize" g:next_bufferlist_height
  call <SID>set_up_buffer()

  let width = winwidth(0)

  " iterate through the buffers
  let i = 0 | while i <= bufcount | let i += 1
    if s:tabfriendstoggle && !exists('t:next_bufferlist_tab_friends[' . i . ']')
      continue
    endif

    let bufname = bufname(i)

    if g:next_bufferlist_show_unnamed && !strlen(bufname)
      if !((g:next_bufferlist_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      " adapt width and/or buffer name
      if strlen(bufname) + 5 > width
        let bufname = '…' . strpart(bufname, strlen(bufname) - width + 6)
      endif

      if bufwinnr(i) != -1
        let bufname .= '*'
      endif
      if getbufvar(i, '&modified')
        let bufname .= '+'
      endif
      " count displayed buffers
      let displayedbufs += 1
      " remember buffer numbers
      let bufnumbers .= i . ':'
      " remember the buffer that was active BEFORE showing the list
      if activebuf == i
        let activebufline = displayedbufs
      endif
      " fill the name with spaces --> gives a nice selection bar
      " use MAX width here, because the width may change inside of this 'for' loop
      while strlen(bufname) < width
        let bufname .= ' '
      endwhile
      " add the name to the list
      let buflist .=  '  ' . bufname . "\n"
    endif
  endwhile

  " set up window height
  if displayedbufs > g:next_bufferlist_height
    if displayedbufs < g:next_bufferlist_max_height
      silent! exe "resize " . displayedbufs
    else
      silent! exe "resize " . g:next_bufferlist_max_height
    endif
  endif

  call <SID>display_list(displayedbufs, buflist, width)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:bufnumbers = bufnumbers
  let b:bufcount = displayedbufs
  let b:jumplines = <SID>create_jumplines(bufnumbers, activebufline)

  " go to the correct line
  call <SID>move(activebufline)
  normal! zb
endfunction

" toggled the buffer list on/off
function! <SID>vertical()
  let bufcount = bufnr('$')
  let displayedbufs = 0
  let activebuf = bufnr('')
  let activebufline = 0
  let buflist = ''
  let bufnumbers = ''
  let width = g:next_bufferlist_width

  " iterate through the buffers
  let i = 0 | while i <= bufcount | let i += 1
    if s:tabfriendstoggle && !exists('t:next_bufferlist_tab_friends[' . i . ']')
      continue
    endif

    let bufname = bufname(i)

    if g:next_bufferlist_show_unnamed && !strlen(bufname)
      if !((g:next_bufferlist_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      " adapt width and/or buffer name
      if width < (strlen(bufname) + 5)
        if strlen(bufname) + 5 < g:next_bufferlist_max_width
          let width = strlen(bufname) + 5
        else
          let width = g:next_bufferlist_max_width
          let bufname = '…' . strpart(bufname, strlen(bufname) - g:next_bufferlist_max_width + 6)
        endif
      endif

      if bufwinnr(i) != -1
        let bufname .= '*'
      endif
      if getbufvar(i, '&modified')
        let bufname .= '+'
      endif
      " count displayed buffers
      let displayedbufs += 1
      " remember buffer numbers
      let bufnumbers .= i . ':'
      " remember the buffer that was active BEFORE showing the list
      if activebuf == i
        let activebufline = displayedbufs
      endif
      " fill the name with spaces --> gives a nice selection bar
      " use MAX width here, because the width may change inside of this 'for' loop
      while strlen(bufname) < g:next_bufferlist_max_width
        let bufname .= ' '
      endwhile
      " add the name to the list
      let buflist .=  '  ' . bufname . "\n"
    endif
  endwhile

  " now, create the buffer & set it up
  exec 'silent! ' . width . 'vne __NEXT_BUFFERLIST__'
  call <SID>set_up_buffer()
  call <SID>display_list(displayedbufs, buflist, width)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:bufnumbers = bufnumbers
  let b:bufcount = displayedbufs
  let b:jumplines = <SID>create_jumplines(bufnumbers, activebufline)

  " go to the correct line
  call <SID>move(activebufline)
endfunction

function! <SID>kill(buflistnr, final)
  if a:buflistnr
    silent! exe ':' . a:buflistnr . 'bwipeout'
  else
    bwipeout
  end

  if a:final
    if exists("t:next_bufferlist_start_window")
      silent! exe t:next_bufferlist_start_window . "wincmd w"
    endif

    if exists("t:next_bufferlist_winrestcmd") && (winrestcmd() != t:next_bufferlist_winrestcmd)
      silent! exe t:next_bufferlist_winrestcmd

      if winrestcmd() != t:next_bufferlist_winrestcmd
        wincmd =
      endif
    endif
  endif
endfunction

function! <SID>set_up_buffer()
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nomodifiable
  setlocal nowrap
  setlocal nonumber

  if s:tabfriendstoggle
    let &l:statusline = "NEXT_BUFFERLIST [TAB]"
  else
    let &l:statusline = "NEXT_BUFFERLIST [ALL]"
  endif

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
    au BufEnter <buffer> set timeoutlen=10
    au BufLeave <buffer> silent! exe "set timeoutlen=" . b:old_timeoutlen
  endif

  augroup NextBufferListLeave
    au!
    au BufLeave <buffer> call <SID>kill(0, 1)
  augroup END

  " set up syntax highlighting
  if has("syntax")
    syn clear
    syn match BufferNormal /  .*/
    syn match BufferSelected /> .*/hs=s+1
    hi def BufferNormal ctermfg=black ctermbg=white
    hi def BufferSelected ctermfg=white ctermbg=black
  endif

  " set up the keymap
  noremap <silent> <buffer> <CR> :call <SID>load_buffer()<CR>
  noremap <silent> <buffer> v :call <SID>load_buffer("vs")<CR>
  noremap <silent> <buffer> s :call <SID>load_buffer("sp")<CR>
  noremap <silent> <buffer> t :call <SID>load_buffer("tabnew")<CR>
  map <silent> <buffer> q :call <SID>kill(0, 1)<CR>
  map <silent> <buffer> j :call <SID>move("down")<CR>
  map <silent> <buffer> k :call <SID>move("up")<CR>
  map <silent> <buffer> p :call <SID>jump("previous")<CR>
  map <silent> <buffer> P :call <SID>jump("previous")<CR>:call <SID>load_buffer()<CR>
  map <silent> <buffer> n :call <SID>jump("next")<CR>
  map <silent> <buffer> d :call <SID>delete_buffer()<CR>
  map <silent> <buffer> D :call <SID>delete_hidden_buffers()<CR>
  map <silent> <buffer> <MouseDown> :call <SID>move("up")<CR>
  map <silent> <buffer> <MouseUp> :call <SID>move("down")<CR>
  map <silent> <buffer> <LeftDrag> <Nop>
  map <silent> <buffer> <LeftRelease> :call <SID>move("mouse")<CR>
  map <silent> <buffer> <2-LeftMouse> :call <SID>move("mouse")<CR>:call <SID>load_buffer()<CR>
  map <silent> <buffer> <Down> j
  map <silent> <buffer> <Up> k
  map <buffer> h <Nop>
  map <buffer> l <Nop>
  map <buffer> <Left> <Nop>
  map <buffer> <Right> <Nop>
  map <buffer> i <Nop>
  map <buffer> a <Nop>
  map <buffer> I <Nop>
  map <buffer> A <Nop>
  map <buffer> o <Nop>
  map <buffer> O <Nop>
  map <silent> <buffer> <Home> :call <SID>move(1)<CR>
  map <silent> <buffer> <End> :call <SID>move(line("$"))<CR>

  if g:next_bufferlist_show_tab_friends
    map <silent> <buffer> a :call <SID>toggle_tab_friends()<CR>
    map <silent> <buffer> f :call <SID>detach_tab_friend()<CR>
    map <silent> <buffer> F :call <SID>delete_foreign_buffers()<CR>
  endif
endfunction

function! <SID>make_filler(width)
  " generate a variable to fill the buffer afterwards
  " (we need this for "full window" color :)
  let fill = "\n"
  let i = 0 | while i < a:width | let i += 1
    let fill = ' ' . fill
  endwhile

  return fill
endfunction

function! <SID>display_list(displayedbufs, buflist, width)
  setlocal modifiable
  if a:displayedbufs > 0
    " input the buffer list, delete the trailing newline, & fill with blank lines
    silent! put! =a:buflist
    " is there any way to NOT delete into a register? bummer...
    "normal! Gdd$
    normal! GkJ
    let fill = <SID>make_filler(a:width)
    while winheight(0) > line(".")
      silent! put =fill
    endwhile
  else
    let empty_list_message = "  List empty"
    let width = a:width

    if width < (strlen(empty_list_message) + 2)
      if strlen(empty_list_message) + 2 < g:next_bufferlist_max_width
        let width = strlen(empty_list_message) + 2
      else
        let width = g:next_bufferlist_max_width
        let empty_list_message = strpart(empty_list_message, 0, width - 3) . "…"
      endif
      silent! exe "vert resize " . width
    endif

    while strlen(empty_list_message) < width
      let empty_list_message .= ' '
    endwhile

    silent! put! =empty_list_message
    normal! GkJ

    let fill = <SID>make_filler(width)

    while winheight(0) > line(".")
      silent! put =fill
    endwhile

    normal! 0

    " handle vim segfault on calling bd/bw if there are no buffers listed
    let any_buffer_listed = 0
    for i in range(1, bufnr("$"))
      if buflisted(i)
        let any_buffer_listed = 1
        break
      endif
    endfor

    if !any_buffer_listed
      au! NextBufferListLeave BufLeave
      noremap <silent> <buffer> q :q<CR>
      if g:next_bufferlist_show_tab_friends
        noremap <silent> <buffer> a <Nop>
      endif
      if g:next_bufferlist_set_default_mapping
        silent! exe 'noremap <silent><buffer>' . g:next_bufferlist_default_mapping_key . ' :q<CR>'
      endif
    endif

    noremap <silent> <buffer> <CR> <Nop>
    noremap <silent> <buffer> v <Nop>
    noremap <silent> <buffer> s <Nop>
    noremap <silent> <buffer> t <Nop>
    noremap <silent> <buffer> j <Nop>
    noremap <silent> <buffer> k <Nop>
    noremap <silent> <buffer> d <Nop>
    noremap <silent> <buffer> D <Nop>
    noremap <silent> <buffer> p <Nop>
    noremap <silent> <buffer> P <Nop>
    noremap <silent> <buffer> n <Nop>
    noremap <silent> <buffer> <MouseDown> <Nop>
    noremap <silent> <buffer> <MouseUp> <Nop>
    noremap <silent> <buffer> <LeftDrag> <Nop>
    noremap <silent> <buffer> <LeftRelease> <Nop>
    noremap <silent> <buffer> <2-LeftMouse> <Nop>
    noremap <silent> <buffer> <Down> <Nop>
    noremap <silent> <buffer> <Up> <Nop>
    map <silent> <buffer> <Home> <Nop>
    map <silent> <buffer> <End> <Nop>

    if g:next_bufferlist_show_tab_friends
      map <silent> <buffer> f :call <Nop>
      map <silent> <buffer> F :call <Nop>
    endif
  endif
  setlocal nomodifiable
endfunction

" move the selection bar of the list:
" where can be "up"/"down"/"mouse" or
" a line number
function! <SID>move(where)
  if b:bufcount < 1
    return
  endif
  let newpos = 0
  if !exists('b:lastline')
    let b:lastline = 0
  endif
  setlocal modifiable

  " the mouse was pressed: remember which line
  " and go back to the original location for now
  if a:where == "mouse"
    let newpos = line(".")
    call <SID>goto(b:lastline)
  endif

  " exchange the first char (>) with a space
  call setline(line("."), " ".strpart(getline(line(".")), 1))

  " go where the user want's us to go
  if a:where == "up"
    call <SID>goto(line(".")-1)
  elseif a:where == "down"
    call <SID>goto(line(".")+1)
  elseif a:where == "mouse"
    call <SID>goto(newpos)
  else
    call <SID>goto(a:where)
  endif

  " and mark this line with a >
  call setline(line("."), ">".strpart(getline(line(".")), 1))

  " remember this line, in case the mouse is clicked
  " (which automatically moves the cursor there)
  let b:lastline = line(".")

  setlocal nomodifiable
endfunction

" tries to set the cursor to a line of the buffer list
function! <SID>goto(line)
  if b:bufcount < 1 | return | endif
  if a:line < 1
    if g:next_bufferlist_cyclic_list
      call <SID>goto(b:bufcount - a:line)
    else
      call cursor(1, 1)
    endif
  elseif a:line > b:bufcount
    if g:next_bufferlist_cyclic_list
      call <SID>goto(a:line - b:bufcount)
    else
      call cursor(b:bufcount, 1)
    endif
  else
    call cursor(a:line, 1)
  endif
endfunction

function! <SID>jump(direction)
  if !exists("b:jumppos")
    let b:jumppos = 0
  endif

  if a:direction == "previous"
    let b:jumppos += 1

    if b:jumppos == len(b:jumplines)
      let b:jumppos = len(b:jumplines) - 1
    endif
  elseif a:direction == "next"
    let b:jumppos -= 1

    if b:jumppos < 0
      let b:jumppos = 0
    endif
  endif

  call <SID>move(string(b:jumplines[b:jumppos]))
endfunction

" loads the selected buffer
function! <SID>load_buffer(...)
  " get the selected buffer
  let str = <SID>get_selected_buffer()
  " kill the buffer list
  call <SID>kill(0, 1)

  if !empty(a:000)
    exec ":" . a:1
  endif

  " ...and switch to the buffer number
  exec ":b " . str
endfunction

function! <SID>load_buffer_into_window(winnr)
  if exists("t:next_bufferlist_start_window")
    let old_start_window = t:next_bufferlist_start_window
    let t:next_bufferlist_start_window = a:winnr
  endif
  call <SID>load_buffer()
  if exists("old_start_window")
    let t:next_bufferlist_start_window = old_start_window
  endif
endfunction

" deletes the selected buffer
function! <SID>delete_buffer()
  let str = <SID>get_selected_buffer()
  if !getbufvar(str2nr(str), '&modified')
    let selected_buffer_window = bufwinnr(str2nr(str))
    if selected_buffer_window != -1
      call <SID>move("down")
      if <SID>get_selected_buffer() == str
        call <SID>move("up")
        if <SID>get_selected_buffer() == str
          call <SID>kill(0, 0)
        else
          call <SID>load_buffer_into_window(selected_buffer_window)
        endif
      else
        call <SID>load_buffer_into_window(selected_buffer_window)
      endif
    else
      call <SID>kill(0, 0)
    endif
    exec ":bdelete " . str
    call <SID>next_bufferlist_toggle(1)
  endif
endfunction

function! <SID>keep_buffers_for_keys(dict)
  for b in range(1, bufnr('$'))
    if buflisted(b) && !has_key(a:dict, b) && !getbufvar(b, '&modified')
      exe ':bdelete ' . b
    endif
  endfor
endfunction

" deletes all hidden buffers
" taken from: http://stackoverflow.com/a/3180886
function! <SID>delete_hidden_buffers()
  let visible = {}
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let visible[b] = 1
    endfor
  endfor
  call <SID>kill(0, 0)
  call <SID>keep_buffers_for_keys(visible)
  call <SID>next_bufferlist_toggle(1)
endfunction

" deletes all foreign (not tab friend) buffers
function! <SID>delete_foreign_buffers()
  let friends = {}
  for t in range(1, tabpagenr('$'))
    silent! call extend(friends, gettabvar(t, 'next_bufferlist_tab_friends'))
  endfor
  call <SID>kill(0, 0)
  call <SID>keep_buffers_for_keys(friends)
  call <SID>next_bufferlist_toggle(1)
endfunction

function! <SID>get_selected_buffer()
  " this is our string containing the buffer numbers in
  " the order of the list (separated by ':')
  let str = b:bufnumbers

  " remove all numbers BEFORE the one we want
  let i = 1 | while i < line(".") | let i += 1
    let str = strpart(str, stridx(str, ':') + 1)
  endwhile

  " and everything AFTER
  let str = strpart(str, 0, stridx(str, ':'))

  return str
endfunction

function! <SID>add_tab_friend()
  if !exists('t:next_bufferlist_tab_friends')
    let t:next_bufferlist_tab_friends = {}
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__NEXT_BUFFERLIST__")
    let t:next_bufferlist_tab_friends[current] = 1
  endif
endfunction

function! <SID>add_jump()
  if g:next_bufferlist_show_tab_friends && !exists("t:next_bufferlist_jumps")
    let t:next_bufferlist_jumps = []
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__NEXT_BUFFERLIST__")
    call add(s:next_bufferlist_jumps, current)
    let s:next_bufferlist_jumps = <SID>unique_list(s:next_bufferlist_jumps)

    if len(s:next_bufferlist_jumps) > g:next_bufferlist_max_jumps + 1
      unlet s:next_bufferlist_jumps[0]
    endif

    if g:next_bufferlist_show_tab_friends
      call add(t:next_bufferlist_jumps, current)
      let t:next_bufferlist_jumps = <SID>unique_list(t:next_bufferlist_jumps)

      if len(t:next_bufferlist_jumps) > g:next_bufferlist_max_jumps + 1
        unlet t:next_bufferlist_jumps[0]
      endif
    endif
  endif
endfunction

function! <SID>toggle_tab_friends()
  let s:tabfriendstoggle = !s:tabfriendstoggle
  call <SID>kill(0, 0)
  call <SID>next_bufferlist_toggle(1)
endfunction

function! <SID>detach_tab_friend()
  let str = <SID>get_selected_buffer()
  if exists('t:next_bufferlist_tab_friends[' . str . ']')
    let selected_buffer_window = bufwinnr(str2nr(str))
    if selected_buffer_window != -1
      call <SID>move("down")
      if <SID>get_selected_buffer() == str
        call <SID>move("up")
        if <SID>get_selected_buffer() == str
          return
        endif
      endif
      call <SID>load_buffer_into_window(selected_buffer_window)
    else
      call <SID>kill(0, 0)
    endif
    call remove(t:next_bufferlist_tab_friends, str)
    call <SID>next_bufferlist_toggle(1)
  endif
endfunction
