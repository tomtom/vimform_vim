" dir.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-14.
" @Last Change: 2010-04-14.
" @Revision:    79

let s:save_cpo = &cpo
set cpo&vim

if has_key(g:vimform#widgets, 'dir')
    finish
endif


let s:prototype = vimform#widget#New()
let s:prototype.modifiable = !has('browse')


" function! s:prototype.FormatLabel(form) dict "{{{3
"     return 'Dir| '. self.name
" endf


function! s:prototype.Format(form, value) dict "{{{3
    return empty(a:value) ? '<Browse>' : a:value
endf


function! s:prototype.GetFieldValue(form, value) dict "{{{3
    return a:value ==# '<Browse>' ? '' : a:value
endf


if has('browse')
    function! s:prototype.GetSpecialKey(form, name, key) dict "{{{3
        " TLogVAR a:name, a:key
        " let dir = get(self, 'cd', expand('%:h'))
        let dir = get(self, 'cd', '.')
        let dir = browsedir('Select dir', dir)
        if empty(dir)
            return ''
        else
            " TLOgVAR dir
            let line = strpart(getline('.'), 0, a:form.indent) . dir
            call a:form.SetModifiable(1)
            call setline('.', line)
            return ''
        endif
    endf
else
    function! s:prototype.GetSpecialKey(form, name, key) dict "{{{3
        call a:form.SetModifiable(2)
        let line = strpart(getline('.'), 0, a:form.indent)
        call setline('.', line)
        return "$a\<c-x>\<c-f>"
    endf
endif


function! s:prototype.Key_dd(form) dict "{{{3
    call a:form.SetModifiable(2)
    return (a:form.indent + 1) ."|d$<Browse>\<esc>"
endf


let g:vimform#widgets['dir'] = s:prototype


let &cpo = s:save_cpo
unlet s:save_cpo
