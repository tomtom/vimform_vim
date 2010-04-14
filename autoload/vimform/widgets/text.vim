" text.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-14.
" @Last Change: 2010-04-14.
" @Revision:    14

let s:save_cpo = &cpo
set cpo&vim

if has_key(g:vimform#widgets, 'text')
    finish
endif


let s:prototype = vimform#widget#New()
let s:prototype.modifiable = 1


let g:vimform#widgets['text'] = s:prototype


let &cpo = s:save_cpo
unlet s:save_cpo
