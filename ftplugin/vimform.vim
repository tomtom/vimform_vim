" vimform.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-09.
" @Last Change: 2010-04-10.
" @Revision:    52

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let s:save_cpo = &cpo
set cpo&vim


setlocal buftype=nofile
setlocal bufhidden=hide
setlocal noswapfile
setlocal modifiable
setlocal omnifunc=vimform#Complete

noremap <buffer> <cr> :call b:vimform.SpecialKey('<lt>cr>')<cr>
noremap <buffer> <space> :call b:vimform.SpecialKey('<lt>space>')<cr>
noremap <buffer> <LeftMouse> <LeftMouse>:call b:vimform.SpecialKey('')<cr>
inoremap <buffer> <LeftMouse> <LeftMouse><c-\><c-n>:call b:vimform.SpecialKey('')<cr>

noremap <buffer> <c-cr> :call b:vimform.Submit()<cr>
inoremap <buffer> <c-cr> <c-\><c-n>:call b:vimform.Submit()<cr>
noremap <silent> <buffer> <tab> :call b:vimform.NextField('w', 1)<cr>
inoremap <silent> <buffer> <tab> <c-\><c-n>:call b:vimform.NextField('w', 1)<cr>
noremap <silent> <buffer> <s-tab> :call b:vimform.NextField('bw', 1)<cr>
inoremap <silent> <buffer> <s-tab> <c-\><c-n>:call b:vimform.NextField('bw', 1)<cr>

imap <expr> <buffer> <c-space> vimform#Complete1()


let &cpo = s:save_cpo
unlet s:save_cpo
