" vim-bufferlist2 - The Ultimate Buffer List
" Maintainer:   Szymon Wrozynski
" Version:      2.0.3
"
" Installation:
" Place in ~/.vim/plugin/bufferlist2.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-bufferlist2.git
"
" License:
" Copyright (c) 2013 Szymon Wrozynski <szymon@wrozynski.com>
" Distributed under the same terms as Vim itself.
" Original plugin code - copyright (c) 2005 Robert Lillack <rob@lillack.de>
" Redistribution in any form with or without modification permitted.
" See :help license
"
" Usage:
" https://github.com/szw/vim-bufferlist2/blob/master/README.md

if exists('g:bufferlist_loaded')
  finish
endif
let g:bufferlist_loaded = 1

if !exists('g:bufferlist_width')
  let g:bufferlist_width = 20
endif

if !exists('g:bufferlist_max_width')
  let g:bufferlist_max_width = 40
endif

if !exists('g:bufferlist_height')
  let g:bufferlist_height = 1
endif

if !exists('g:bufferlist_max_height')
  let g:bufferlist_max_height = 10
endif

if !exists('g:bufferlist_show_unnamed')
  let g:bufferlist_show_unnamed = 2
endif

if !exists('g:bufferlist_show_tab_friends')
  let g:bufferlist_show_tab_friends = 2
endif

if !exists('g:bufferlist_stick_to_bottom')
  let g:bufferlist_stick_to_bottom = 0
endif

if !exists('g:bufferlist_set_default_mapping')
    let g:bufferlist_set_default_mapping = 1
endif

if !exists('g:bufferlist_default_mapping_key')
    let g:bufferlist_default_mapping_key = '<F2>'
endif

command! -nargs=0 -range BufferList :call <SID>bufferlist_toggle(0)

if g:bufferlist_set_default_mapping
  silent! exe 'nnoremap <silent>' . g:bufferlist_default_mapping_key . ' :BufferList<CR>'
  silent! exe 'vnoremap <silent>' . g:bufferlist_default_mapping_key . ' :BufferList<CR>'
  silent! exe 'inoremap <silent>' . g:bufferlist_default_mapping_key . ' <C-[>:BufferList<CR>'
endif

if g:bufferlist_show_tab_friends
  au BufEnter * call <SID>add_tab_friend()
endif

" toggled the buffer list on/off
function! <SID>bufferlist_toggle(internal)
  if !a:internal
    let s:tabfriendstoggle = (g:bufferlist_show_tab_friends == 2)
  endif

  " if we get called and the list is open --> close it
  if bufexists(bufnr("__BUFFERLIST__"))
    let buflistnr = bufnr("__BUFFERLIST__")
    let buflistwindow = bufwinnr(buflistnr)
    call <SID>kill(buflistnr)
    " if the list wasn't open, just the buffer existed, proceed with opening
    if buflistwindow != -1
      return
    endif
  elseif !a:internal
    let t:bufferlist_start_window = winnr()
  endif

  if g:bufferlist_stick_to_bottom
    call <SID>horizontal()
  else
    call <SID>vertical()
  endif
endfunction

function! <SID>horizontal()
  let bufcount = bufnr('$')
  let displayedbufs = 0
  let activebuf = bufnr('')
  let activebufline = 0
  let buflist = ''
  let bufnumbers = ''

  " create the buffer first & set it up
  exec 'silent! new __BUFFERLIST__'
  silent! exe "wincmd J"
  silent! exe "resize" g:bufferlist_height
  call <SID>set_up_buffer()

  let width = winwidth(0)

  " iterate through the buffers
  let i = 0 | while i <= bufcount | let i += 1
    if s:tabfriendstoggle && !exists('t:bufferlist_tab_friends[' . i . ']')
      continue
    endif

    let bufname = bufname(i)

    if g:bufferlist_show_unnamed && !strlen(bufname)
      if !((g:bufferlist_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
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
  if displayedbufs > g:bufferlist_height
    if displayedbufs < g:bufferlist_max_height
      silent! exe "resize " . displayedbufs
    else
      silent! exe "resize " . g:bufferlist_max_height
    endif
  endif

  call <SID>display_list(displayedbufs, buflist, width)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:bufnumbers = bufnumbers
  let b:bufcount = displayedbufs

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
  let width = g:bufferlist_width

  " iterate through the buffers
  let i = 0 | while i <= bufcount | let i += 1
    if s:tabfriendstoggle && !exists('t:bufferlist_tab_friends[' . i . ']')
      continue
    endif

    let bufname = bufname(i)

    if g:bufferlist_show_unnamed && !strlen(bufname)
      if !((g:bufferlist_show_unnamed == 2) && !getbufvar(i, '&modified')) || (bufwinnr(i) != -1)
        let bufname = '[' . i . '*No Name]'
      endif
    endif

    if strlen(bufname) && getbufvar(i, '&modifiable') && getbufvar(i, '&buflisted')
      " adapt width and/or buffer name
      if width < (strlen(bufname) + 5)
        if strlen(bufname) + 5 < g:bufferlist_max_width
          let width = strlen(bufname) + 5
        else
          let width = g:bufferlist_max_width
          let bufname = '…' . strpart(bufname, strlen(bufname) - g:bufferlist_max_width + 6)
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
      while strlen(bufname) < g:bufferlist_max_width
        let bufname .= ' '
      endwhile
      " add the name to the list
      let buflist .=  '  ' . bufname . "\n"
    endif
  endwhile

  " now, create the buffer & set it up
  exec 'silent! ' . width . 'vne __BUFFERLIST__'
  call <SID>set_up_buffer()
  call <SID>display_list(displayedbufs, buflist, width)

  " make the buffer count & the buffer numbers available
  " for our other functions
  let b:bufnumbers = bufnumbers
  let b:bufcount = displayedbufs

  " go to the correct line
  call <SID>move(activebufline)
endfunction

function! <SID>kill(buflistnr)
  if a:buflistnr
    silent! exe ':' . a:buflistnr . 'bwipeout'
  else
    bwipeout
  end

  if exists("t:bufferlist_start_window")
    silent! exe t:bufferlist_start_window . "wincmd w"
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

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
    au BufEnter <buffer> set timeoutlen=10
    au BufLeave <buffer> silent! exe "set timeoutlen=" . b:old_timeoutlen
  endif

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
  map <silent> <buffer> q :call <SID>kill(0)<CR>
  map <silent> <buffer> j :call <SID>move("down")<CR>
  map <silent> <buffer> k :call <SID>move("up")<CR>
  map <silent> <buffer> d :call <SID>delete_buffer()<CR>
  map <silent> <buffer> D :call <SID>delete_hidden_buffers()<CR>
  map <silent> <buffer> <MouseDown> :call <SID>move("up")<CR>
  map <silent> <buffer> <MouseUp> :call <SID>move("down")<CR>
  map <silent> <buffer> <LeftDrag> <Nop>
  map <silent> <buffer> <LeftRelease> :call <SID>move("mouse")<CR>
  map <silent> <buffer> <2-LeftMouse> :call <SID>move("mouse")<CR>
    \:call <SID>load_buffer()<CR>
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

  if g:bufferlist_show_tab_friends
    map <silent> <buffer> a :call <SID>toggle_tab_friends()<CR>
    map <silent> <buffer> f :call <SID>detach_tab_friend()<CR>
    map <silent> <buffer> F :call <SID>delete_foreign_buffers()<CR>
  endif
endfunction

function! <SID>display_list(displayedbufs, buflist, width)
  " generate a variable to fill the buffer afterwards
  " (we need this for "full window" color :)
  let fill = "\n"
  let i = 0 | while i < a:width | let i += 1
    let fill = ' ' . fill
  endwhile

  setlocal modifiable
  if a:displayedbufs > 0
    " input the buffer list, delete the trailing newline, & fill with blank lines
    silent! put! =a:buflist
    " is there any way to NOT delete into a register? bummer...
    "normal! Gdd$
    normal! GkJ
    while winheight(0) > line(".")
      silent! put =fill
    endwhile
  else
    let i = 0 | while i < winheight(0) | let i += 1
      silent! put! =fill
    endwhile
    normal! 0
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
    call cursor(1, 1)
  elseif a:line > b:bufcount
    call cursor(b:bufcount, 1)
  else
    call cursor(a:line, 1)
  endif
endfunction

" loads the selected buffer
function! <SID>load_buffer(...)
  " get the selected buffer
  let str = <SID>get_selected_buffer()
  " kill the buffer list
  call <SID>kill(0)

  if !empty(a:000)
    exec ":" . a:1
  endif

  " ...and switch to the buffer number
  exec ":b " . str
endfunction

function! <SID>load_buffer_into_window(winnr)
  if exists("t:bufferlist_start_window")
    let old_start_window = t:bufferlist_start_window
    let t:bufferlist_start_window = a:winnr
  endif
  call <SID>load_buffer()
  if exists("old_start_window")
    let t:bufferlist_start_window = old_start_window
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
          call <SID>kill(0)
        else
          call <SID>load_buffer_into_window(selected_buffer_window)
        endif
      else
        call <SID>load_buffer_into_window(selected_buffer_window)
      endif
    else
      call <SID>kill(0)
    endif
    exec ":bdelete " . str
    call <SID>bufferlist_toggle(1)
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
  call <SID>kill(0)
  call <SID>keep_buffers_for_keys(visible)
  call <SID>bufferlist_toggle(1)
endfunction

" deletes all foreign (not tab friend) buffers
function! <SID>delete_foreign_buffers()
  let friends = {}
  for t in range(1, tabpagenr('$'))
    silent! call extend(friends, gettabvar(t, 'bufferlist_tab_friends'))
  endfor
  call <SID>kill(0)
  call <SID>keep_buffers_for_keys(friends)
  call <SID>bufferlist_toggle(1)
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
  if !exists('t:bufferlist_tab_friends')
    let t:bufferlist_tab_friends = {}
  endif

  let current = bufnr('%')

  if getbufvar(current, '&modifiable') && getbufvar(current, '&buflisted') && current != bufnr("__BUFFERLIST__")
    let t:bufferlist_tab_friends[current] = 1
  endif
endfunction

function! <SID>toggle_tab_friends()
  let s:tabfriendstoggle = !s:tabfriendstoggle
  call <SID>kill(0)
  call <SID>bufferlist_toggle(1)
endfunction

function! <SID>detach_tab_friend()
  let str = <SID>get_selected_buffer()
  if exists('t:bufferlist_tab_friends[' . str . ']')
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
      call <SID>kill(0)
    endif
    call remove(t:bufferlist_tab_friends, str)
    call <SID>bufferlist_toggle(1)
  endif
endfunction
