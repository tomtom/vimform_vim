" checkbox.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-14.
" @Last Change: 2010-04-14.
" @Revision:    14

let s:save_cpo = &cpo
set cpo&vim


if has_key(g:vimform#widgets, 'checkbox')
    finish
endif


let s:prototype = vimform#widget#New()


function! s:prototype.Format(form, value) dict "{{{3
    return printf('[%s]', empty(a:value) ? ' ' : 'X')
endf


function! s:prototype.GetFieldValue(form, value) dict "{{{3
    return a:value =~ 'X'
endf


function! s:prototype.SelectField(form, to_insertmode) dict "{{{3
    call vimform#Feedkeys('l', 0)
endf


function! s:prototype.SetCursorMoved(form, insertmode, lnum) dict "{{{3
    if a:insertmode
        call feedkeys("\<esc>", 't')
    endif
    call cursor(a:lnum, a:form.indent + 2)
endf


function! s:prototype.GetPumKey(form, key) dict "{{{3
    return a:key ."\<esc>"
endf


function! s:prototype.GetSpecialInsertKey(form, key) dict "{{{3
    return "\<esc>"
endf


function! s:prototype.GetSpecialKey(form, name, key) dict "{{{3
    let line = getline('.')
    let notchecked = line =~ '\[ \]$'
    if notchecked
        let value = 'X'
    else
        let value = ' '
    endif
    let a:form.values[a:name] = !notchecked
    " TLogVAR value
    call a:form.SetModifiable(1)
    let line = substitute(line, '\[\zs.\ze\]$', value, '')
    call setline('.', line)
    return ''
endf


function! s:prototype.GetKey(form, key) dict "{{{3
    return "\<cr>"
endf


function! s:prototype.Key_dd(form) dict "{{{3
    return ''
endf


function! s:prototype.Key_BS(form) dict "{{{3
    return ''
endf


function! s:prototype.Key_DEL(form) dict "{{{3
    return ''
endf



let g:vimform#widgets['checkbox'] = s:prototype


let &cpo = s:save_cpo
unlet s:save_cpo
