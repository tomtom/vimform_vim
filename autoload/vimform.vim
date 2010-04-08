" vimform.vim -- Simple forms for vim scripts
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-08.
" @Revision:    0.0.277
" 
" TODO: Demo: :s Form
" TODO: Multi-line text fields

if &cp || exists("loaded_vimform_autoload")
    finish
endif
let loaded_vimform_autoload = 1
let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


augroup Vimform
    autocmd!
augroup END


function! vimform#SimpleForm() "{{{3
    let form = copy(s:prototype)
    let form.simple = 1
    let form.Cancel = 'cancel'
    let form.Submit = 'submit'
    let form.epilogue = ['<<&Cancel>>  <<&Submit>>']
    return form
endf


function! vimform#WithFile(file, ...) "{{{3
    let form = a:0 >= 1 ? a:1 : vimform#SimpleForm()
    let form.lines = readfile(a:file)
    call vimform#Form(form)
endf


function! vimform#WithString(string, ...) "{{{3
    let form = a:0 >= 1 ? a:1 : vimform#SimpleForm()
    let form.lines = split(a:string, '\n')
    call vimform#Form(form)
endf


function! vimform#WithArray(lines, ...) "{{{3
    let form = a:0 >= 1 ? a:1 : vimform#SimpleForm()
    let form.lines = a:lines
    call vimform#Form(form)
endf


function! vimform#Form(form) "{{{3
    let name = get(a:form, 'name', '__Form__')
    let bufnr = bufnr('')
    exec 'split '. fnameescape(name)
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal modifiable
    setfiletype vimform
    let b:vimform = copy(s:prototype)
    call extend(b:vimform, a:form)
    let b:vimform.bufnr = bufnr
    1,$delete
    let lines = get(b:vimform, 'prologue', []) + b:vimform.lines + get(b:vimform, 'epilogue', [])
    call append(0, lines)
    call s:SetAccellerators()
    $delete
    if has_key(b:vimform, 'fields')
        for [field, value] in items(b:vimform.fields)
            call b:vimform.SetField(field, value)
        endfor
    endif
    exec 'resize '. len(lines)
    if b:vimform.simple
        noremap <buffer> <cr> :call <SID>Submit()<cr>
        inoremap <buffer> <cr> <c-\><c-n>:call <SID>Submit()<cr>
    endif
    noremap <buffer> <c-cr> :call <SID>Submit()<cr>
    inoremap <buffer> <c-cr> <c-\><c-n>:call <SID>Submit()<cr>
    noremap <silent> <buffer> <tab> :call <SID>NextField('w', 1)<cr>
    inoremap <silent> <buffer> <tab> <c-\><c-n>:call <SID>NextField('w', 1)<cr>
    noremap <silent> <buffer> <s-tab> hh:call <SID>NextField('bw', 1)<cr>
    inoremap <silent> <buffer> <s-tab> <c-\><c-n>hh:call <SID>NextField('bw', 1)<cr>
    norm! ggzt
    autocmd Vimform CursorMoved,CursorMovedI <buffer> call s:SetModifiable()
    call s:NextField('w', 1)
endf


function! s:SetAccellerators() "{{{3
    norm! ggzt
    while search('&', 'W')
        let acc = tolower(getline('.')[col('.')])
        " TLogVAR acc
        if acc =~# '^[a-z]$'
            exec 'norm! m'. acc
        endif
    endwh
endf


function! s:SetModifiable() "{{{3
    let line = getline('.')
    let col  = col('.')
    let part = line[0 : col - 1]
    " TLogVAR line, col, part, part =~ ':´\(\\.\|[^´]\)*$'
    if part =~ ':´\(\\.\|[^´]\)\+$'
        setlocal modifiable
    else
        setlocal nomodifiable
        if mode() == 'R'
            call feedkeys("\<c-\>\<c-n>")
        endif
    endif
endf


function! s:Submit() "{{{3
    let m = matchlist(getline('.'), '<<\([^>]\{-}\%'. col('.') .'c[^>]\{-}\)>>')
    if empty(m)
        echom 'Vimform: No button under cursor'
    else
        let form = b:vimform
        let name = substitute(m[1], '&', '', 'g')
        let name = substitute(name, '\W', '_', 'g')
        let cb_name = 'Do_'. name
        if has_key(form, cb_name)
            if name == 'Cancel'
                call form.Do_Cancel()
            elseif name == 'Submit'
                call form.CollectFields()
                call form.Do_Cancel()
                call form.Do_Submit()
            else
                call form.{cb_name}()
            endif
        endif
    endif
endf


function! s:NextField(flags, feedkeys) "{{{3
    if search(':´\(\\.\|[^´]\)\{-}´\|<<.\{-}>>', a:flags)
        let line = getline('.')
        if line =~ '\%'. col('.') .'c<<'
            if a:feedkeys
                " TLogDBG "fk: ll"
                call feedkeys('ll')
            else
                " TLogDBG "n: ll"
                norm! ll
            endif
        else
            if a:feedkeys
                " TLogDBG "fk: llR"
                call feedkeys('llR')
            else
                " TLogDBG "n: ll"
                norm! ll
            endif
        endif
        return line('.')
    else
        return 0
    endif
endf


let s:prototype = {'simple': 0}


function! s:prototype.Do_Cancel() dict "{{{3
    wincmd c
endf


function! s:prototype.CollectFields() dict "{{{3
    let pos = getpos('.')
    try
        norm! ggzt
        let self.fields = {}
        if mode() != 'n'
            exec "norm! <c-\><c-n>"
        endif
        while s:NextField('W', 0)
            let line = getline('.')
            let name = matchstr(line, '\(^\|[^:]´\|>\)\s*\zs[^´]\{-}\ze:´\%'. col('.') .'c')
            " TLogVAR name
            " TLogDBG line[0 : col('.') - 1]
            if !empty(name)
                let field = self.GetField(name)
                if !empty(field)
                    call extend(self.fields, field)
                endif
            endif
        endwh
    finally
        call setpos('.', pos)
    endtry
endf


function! s:prototype.SetField(name, text) dict "{{{3
    let rx  = '\V\('. escape(a:name, '\') .'\)\s\*:´\zs\s\*\(\(\\\.\|\[^´]\)\{-}\)\s\*\ze´'
    let lno = search(rx, 'wnc')
    if lno
        let line = getline(lno)
        let mlen = len(matchstr(line, rx))
        let tlen = len(a:text)
        let text = a:text
        if tlen < mlen
            let text .= repeat(' ', mlen - tlen)
        endif
        let line = substitute(line, rx, escape(text, '\~&'), '')
        call setline(lno, line)
    endif
endf


function! s:prototype.GetField(name) dict "{{{3
    let rx  = '\V\('. escape(a:name, '\') .'\)\s\*:´\s\*\(\(\\\.\|\[^´]\)\{-}\)\s\*´'
    " TLogVAR rx, a:name
    let lno = search(rx, 'wnc')
    if lno
        let line = getline(lno)
        let m = matchlist(line, rx)
        " TLogVAR line, m
        let rv = m[2]
        let rv = substitute(rv, '\\\zs.', '&', 'g')
        return {m[1]: rv}
    endif
    return {}
endf


let &cpo = s:save_cpo
unlet s:save_cpo
