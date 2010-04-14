" singlechoice.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-14.
" @Last Change: 2010-04-14.
" @Revision:    17

let s:save_cpo = &cpo
set cpo&vim


if has_key(g:vimform#widgets, 'singlechoice')
    finish
endif


let s:prototype = {
            \ 'modifiable': 0,
            \ 'default_value': 0,
            \ 'complete': 'vimform#CompleteSingleChoice',
            \ }


function! s:prototype.Format(form, value) dict "{{{3
    return a:value
endf


function! s:prototype.GetFieldValue(form, value) dict "{{{3
    return a:value
endf


function! s:prototype.SelectField(form, to_insertmode) dict "{{{3
endf


function! s:prototype.GetValidate(form) dict "{{{3
    TLogVAR self
    if has_key(self, 'list')
        let list = get(self, 'list', [])
        return get(self, 'validate', 'index('. string(list) .', %s) != -1')
    else
        return get(self, 'validate', '')
    endif
endf


function! s:prototype.SetCursorMoved(form, insertmode, lnum) dict "{{{3
    if a:insertmode
        call feedkeys("\<esc>$", 't')
    endif
endf


function! s:prototype.GetPumKey(form, key) dict "{{{3
    return a:key ."\<esc>"
endf


function! s:prototype.GetSpecialInsertKey(form, key) dict "{{{3
    return "\<esc>"
endf


function! s:prototype.GetSpecialKey(form, name, key) dict "{{{3
    " TLogVAR a:name, a:key
    call a:form.SetModifiable(3)
    return "$a\<c-x>\<c-o>"
endf


function! s:prototype.GetKey(form, key) dict "{{{3
    " TLogVAR a:key
    return "\<cr>"
endf


function! s:prototype.Key_dd(form) dict "{{{3
    call a:form.SetModifiable(2)
    return (a:form.indent + 1) .'|d$'
endf


function! s:prototype.Key_BS(form) dict "{{{3
    return ''
endf


function! s:prototype.Key_DEL(form) dict "{{{3
    return ''
endf


let g:vimform#widgets['singlechoice'] = s:prototype


let &cpo = s:save_cpo
unlet s:save_cpo
