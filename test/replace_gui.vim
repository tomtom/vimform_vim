" vimform.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-10.
" @Revision:    95


let replace_form= vimform#SimpleForm()
let replace_form.name = "Search & Replace"
let replace_form.fields = [
            \ ['Search'],
            \ ['Replace'],
            \ ['--- Options'],
            \ ['Replace all', {'value': 1, 'type': 'checkbox', 'return': {'1': 'g', '0': ''}}],
            \ ['Case-sensitive', {'type': 'checkbox', 'return': {'1': 'I', '0': ''}}],
            \ ['Confirm', {'value': 1, 'type': 'checkbox', 'return': {'1': 'c', '0': ''}}],
            \ ['Ignore errors', {'type': 'checkbox', 'return': {'1': 'e', '0': ''}}],
            \ ]
function! replace_form.Do_Submit() dict "{{{3
    let search = self.values['Search']
    if !empty(search)
        let flags = map(["Replace all", "Case-sensitive", "Confirm", "Ignore errors"], 'self.values[v:val]')
        exec printf('%%s/%s/%s/%s',
                    \ escape(search, '/'),
                    \ escape(self.values['Replace'], '/'),
                    \ join(flags, ''))
    endif
endf

call replace_form.Split()
