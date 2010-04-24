" file.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-14.
" @Last Change: 2010-04-24.
" @Revision:    108

if has_key(g:vimform#widgets, 'file')
    finish
endif


let s:prototype = vimform#widget#New()
" let s:prototype.modifiable = !has('browse')
let s:prototype.modifiable = 1
let s:prototype.complete = 'vimform#widgets#file#Complete'
let s:prototype.validate = 'vimform#widgets#file#Validate(%s)'
let s:prototype.message = 'Must be a filename'


let s:empty = '<Browse>'
let s:empty = ''


function! vimform#widgets#file#Complete(findstart, base) "{{{3
    if a:findstart
        let self = b:vimform
        return self.indent
    else
        let baselen = len(a:base)
        let files = split(glob('*'), '\n')
        call filter(files, 'strpart(v:val, 0, baselen) ==# a:base')
        return files
    endif
endf


function! vimform#widgets#file#Validate(file) "{{{3
    let self = b:vimform
    let dir = get(self, 'cd', '.')
    let filename = join([dir, a:file], '/')
    if get(self, 'filesave', 1)
        return filewritable(filename)
    else
        return filereadable(filename)
    endif
endf


function! s:prototype.Format(form, value) dict "{{{3
    return empty(a:value) ? s:empty : a:value
endf


function! s:prototype.GetFieldValue(form, value) dict "{{{3
    return a:value ==# s:empty ? '' : a:value
endf


if has('browse')
    function! s:prototype.GetSpecialKey(form, name, key) dict "{{{3
        " TLogVAR a:name, a:key
        " let dir = get(self, 'cd', expand('%:h'))
        let dir = get(self, 'cd', '.')
        let file = browse(get(self, 'filesave', 1), 'Select file', dir, '')
        if empty(file)
            return ''
        else
            " TLOgVAR file
            let line = strpart(getline('.'), 0, a:form.indent) . file
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


function! s:prototype.GetSpecialInsertKey(form, key) dict "{{{3
    " TLogVAR a:key
    return "\<esc>". a:key
endf


function! s:prototype.Key_dd(form) dict "{{{3
    call a:form.SetModifiable(3)
    return (a:form.indent + 1) ."|d$a<Browse>\<esc>"
endf


let g:vimform#widgets['file'] = s:prototype

