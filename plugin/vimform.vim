" vimform.vim -- Simple forms for vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-11.
" @Revision:    4
" GetLatestVimScripts: 3051 0 vimform.vim

if &cp || exists("loaded_vimform")
    finish
endif
let loaded_vimform = 2

let s:save_cpo = &cpo
set cpo&vim





let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

