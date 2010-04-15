" vimform.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-09.
" @Last Change: 2010-04-15.
" @Revision:    126

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
setlocal ballooneval
setlocal balloonexpr=vimform#Balloon()

let b:vimform.SaveMapargs('<cr>', ' ')
noremap <buffer> <silent> <cr> :call b:vimform.SpecialKey('<lt>cr>', 0)<cr>
noremap <buffer> <silent> <space> :call b:vimform.SpecialKey(' ', 0)<cr>
noremap <buffer> <silent> <LeftMouse> <LeftMouse>:call b:vimform.SpecialKey('', 0)<cr>

" inoremap <buffer> <silent> <LeftMouse> <LeftMouse><c-\><c-n>:call b:vimform.SpecialKey('', 1)<cr>
" inoremap <buffer> <silent> <space> <c-\><c-n>:call b:vimform.SpecialKey(' ', 1)<cr>
" inoremap <buffer> <silent> <cr> <c-\><c-n>:call b:vimform.SpecialKey('<lt>cr>', 1)<cr>
inoremap <expr> <buffer> <silent> <LeftMouse> vimform#SpecialInsertKey("\<lt>LeftMouse>", '', 1)
inoremap <expr> <buffer> <silent> <space> vimform#SpecialInsertKey(' ', "\<c-y>", 0)
inoremap <expr> <buffer> <silent> <cr> vimform#SpecialInsertKey("\<lt>cr>", "\<c-y>", 0)

imap <expr> <buffer> <c-y> vimform#PumKey("\<c-y>")
imap <expr> <buffer> <c-e> vimform#PumKey("\<c-e>")
" imap <expr> <buffer> <up> vimform#PumKey("\<up>")
" imap <expr> <buffer> <down> vimform#PumKey("\<down>")
" imap <expr> <buffer> <c-n> vimform#PumKey("\<c-n>")
" imap <expr> <buffer> <c-p> vimform#PumKey("\<c-p>")

noremap <buffer> <f5> :VimformReset<cr>
noremap <buffer> <f1> :help vimform-keys<cr>
inoremap <buffer> <f1> <c-\><c-n>:help vimform-keys<cr>

noremap <buffer> <c-cr> :call b:vimform.Submit()<cr>
inoremap <buffer> <c-cr> <c-\><c-n>:call b:vimform.Submit()<cr>
noremap <silent> <buffer> <tab> :call b:vimform.NextField('w', 0, 1)<cr>
inoremap <silent> <buffer> <tab> <c-\><c-n>:call b:vimform.NextField('w', 1, 1)<cr>
noremap <silent> <buffer> <s-tab> :call b:vimform.NextField('bw', 0, 1)<cr>
inoremap <silent> <buffer> <s-tab> <c-\><c-n>:call b:vimform.NextField('bw', 1, 1)<cr>

imap <expr> <buffer> <c-space> vimform#Complete1()

imap <expr> <buffer> <bs> b:vimform.Key_BS()
map <expr> <buffer> <bs> b:vimform.Key_BS()
nmap <expr> <buffer> X b:vimform.Key_BS()

imap <expr> <buffer> <del> b:vimform.Key_DEL()
map <expr> <buffer> <del> b:vimform.Key_DEL()
nmap <expr> <buffer> x b:vimform.Key_DEL()

nmap <expr> <buffer> dd b:vimform.Key_dd()

nmap <expr> <buffer> a b:vimform.Key('a')
nmap <expr> <buffer> i b:vimform.Key('i')

" FIXME: define ]], ][, [[, [] in terms of NextField
for m in split('{}[]()', '\zs') + [']]', '][', '[[', '[]']
    exec 'map <expr> <buffer> '. m .' vimform#Motion("'. m .'")'
    exec 'omap <expr> <buffer> '. m .' vimform#Motion("'. m .'")'
endfor


let &cpo = s:save_cpo
unlet s:save_cpo
