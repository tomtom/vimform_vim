" vimform.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-11.
" @Revision:    117


let replace_form = vimform#SimpleForm()
let replace_form.name = "Search & Replace"
let replace_form.options = 'tw=0'
let replace_form.fields = [
            \ ['Search', {'tooltip': 'A regular expression', 'join': '\n'}],
            \ ['Replace', {'tooltip': 'The replacement expression'}],
            \ ['--- Options'],
            \ ['Range', {'value': '%'}],
            \ ['Replace all', {'value': 1, 'type': 'checkbox', 'return': {'1': 'g', '0': ''}}],
            \ ['Case-sensitive', {'type': 'checkbox', 'return': {'1': 'I', '0': ''}}],
            \ ['Confirm', {'value': 1, 'type': 'checkbox', 'return': {'1': 'c', '0': ''}}],
            \ ]

function! replace_form.Do_Submit() dict "{{{3
    let search = self.values['Search']
    if !empty(search)
        let flags = map(["Replace all", "Case-sensitive", "Confirm"], 'self.values[v:val]')
        exec printf('%ss/%s/%s/%se',
                    \ self.values.Range,
                    \ escape(search, '/'),
                    \ escape(self.values['Replace'], '/'),
                    \ join(flags, ''))
    endif
endf

call replace_form.Split()

