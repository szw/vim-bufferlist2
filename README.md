Vim NextBufferList
==================

Welcome
-------

This project is based on original Robert Lillack's great
[VIM bufferlist](https://github.com/roblillack/vim-bufferlist) plugin. However, instead of forking
Rob's project I decided to create a new project based exactly on his original one. Partially because
his project seems a bit abandoned, and also, the changes I've introduced into the code are radical
and might be hard for future merging.

Please, don't forget to star the repository if you like (and use) the plugin. This will let me know
how many users it has and then how to proceed with further development :).

About
-----

Upon keypress this script display a nice list of buffers at the bottom (or on the left),
which can be selected with mouse or keyboard. As soon as a buffer is selected
(`Return` (or `s`, `v`, `t`), double click) the list disappears.

The selection can be cancelled with the same key that is configured to open the list or by pressing
`q`. Movement key and mouse (wheel) should work as one expects.

Buffers that are visible (in any window) are marked with `*`, ones that are modified are marked with
`+`.

You can adjust the displaying of unnamed buffers. If you set `g:next_bufferlist_show_unnamed = 1` then
unnamed buffers will be shown on the list any time. However, if you set this value to `2` (default),
unnamed buffers will be displayed only if they are modified or just visible on the screen. Of course
you can hide unnamed buffers permanently by `g:next_bufferlist_show_unnamed = 0`.

To delete a buffer from the list (i.e. close the file) press `d`. To delete all hidden buffers (the
ones not visible in any tab) press `D` (uppercase).

You can also jump between previous and next opened buffers with help of `p` (like *previous*) and `n`
(like *next*) keys (note, currently displayed buffers does not count). There is even a shortcut
to open the previous buffer immediately: uppercase `P`.

If you want to toggle between all buffers view and those related with the current tab only, press
`a`. *Related* means buffers seen in that tab at least once. This feature, called internally *tab
friends* is turned on by default and can be turned off by setting `g:next_bufferlist_show_tab_friends = 0`.

If you use *tab friends* feature you are also allowed to detach a *friend* buffer from the current
tab. We would say to make it a *foreign* one ;). To perform that press `f` (a good mnemonic could
be also to *forget*). It is also safer than deleting a buffer especially if you are unsure whether
you need this buffer in another tab.

To close all detached (foreign) buffers, press uppercase letter `F`. This is particularly
useful to clean up *orphaned* buffers, if you just have closed the tab you were working with.
Use it freely whenever your *all buffers* list view seems messy to you.


### Keys summary ###

<table>
<tr>
<th>Key</th>
<th>Action</th>
</tr>
<tr>
<td><code>Return</code></td>
<td>Opens the selected buffer</td>
</tr>
<tr>
<td><code>t</code></td>
<td>Opens the selected buffer in a new tab</td>
</tr>
<tr>
<td><code>s</code></td>
<td>Opens the selected buffer in a new horizontal split</td>
</tr>
<tr>
<td><code>v</code></td>
<td>Opens the selected buffer in a new vertical split</td>
</tr>
<tr>
<td><code>p</code></td>
<td>Jump to <em>previous</em> opened buffer</td>
</tr>
<tr>
<td><code>P</code></td>
<td>Jump to <em>previous</em> opened buffer and open it immediately</td>
</tr>
<tr>
<td><code>n</code></td>
<td>Jump to <em>next</em> opened buffer</td>
</tr>
<tr>
<td><code>d</code></td>
<td>Deletes the selected buffer (closes it)</td>
</tr>
<tr>
<td><code>D</code></td>
<td>Deletes (closes) all hidden (not displayed in any tab) buffers</td>
</tr>
<tr>
<td><code>f</code></td>
<td>Forgets the current buffer (make it a <em>foreign</em> (unrelated) to the current tab)</td>
</tr>
<tr>
<td><code>F</code></td>
<td>Deletes (closes) all forgotten buffers (unrelated with any tab)</td>
</tr>
<tr>
<td><code>a</code></td>
<td>Toggles between tab-friends (the ones related to the current tab) and all buffers</td>
</tr>
<tr>
<td><code>o</code></td>
<td>Toggles between sorting modes (chronological vs alphanumeric)</td>
</tr>
<tr>
<td><code>q</code> / <code>F2</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on settings</td>
</tr>
</table>

Usage
-----

Put `next-bufferlist.vim` file into your `~/.vim/plugin` directory. To open NextBufferList there is a command:

    :NextBufferList

By default it is mapped to `<F2>`. You can change it or even disable default mappings
in your `.vimrc`. Here are all possible options of NextBufferList:

### Possible options examples ###

    let g:next_bufferlist_show_unnamed = 1
    let g:next_bufferlist_show_tab_friends = 1
    let g:next_bufferlist_width = 25
    let g:next_bufferlist_max_width = 50
    let g:next_bufferlist_height = 5
    let g:next_bufferlist_max_height = 15
    let g:next_bufferlist_stick_to_bottom = 1
    let g:next_bufferlist_cyclic_list = 0
    let g:next_bufferlist_set_default_mapping = 0
    let g:next_bufferlist_default_mapping_key = '<F3>'
    let g:next_bufferlist_max_jumps = 200
    let g:next_bufferlist_default_sort_order = 1 " 0 - no sort, 1 - chronological, 2 - alphanumeric
    hi BufferSelected term=reverse ctermfg=white ctermbg=red cterm=bold
    hi BufferNormal term=NONE ctermfg=black ctermbg=darkcyan cterm=NONE

License
-------

Copyright(c) 2005, Robert Lillack <rob@burningsoda.com> - original plugin code<br />
Copyright(c) 2013, Szymon Wrozynski <szymon@wrozynski.com> - further development

Licensed under the MIT License conditions.
