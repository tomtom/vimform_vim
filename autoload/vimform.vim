" vimform.vim -- Simple forms for vim scripts
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-11.
" @Revision:    0.0.896

let s:save_cpo = &cpo
set cpo&vim


augroup Vimform
    autocmd!
augroup END


" Return the default form template.
function! vimform#New() "{{{3
    let form = deepcopy(g:vimform#prototype)
    return form
endf


" Return a form template that has no default buttons.
function! vimform#SimpleForm() "{{{3
    let form = vimform#New()
    let form.buttons = []
    return form
endf


" Reset the current form.
" If called with [!], use the original values. Otherwise try to reuse 
" the current values.
command! -bang VimformReset if !exists('b:vimform')
            \ |     echoerr 'Not a VimForm buffer'
            \ | else 
            \ |     call b:vimform.Reset(!empty('<bang>'))
            \ | endif



if !exists('g:vimform#prototype')
    " The default form tepmlate.
    " :read: let g:vimform#prototype = {...}   "{{{2
    let g:vimform#prototype = {
                \ 'name': '__Form__',
                \ 'indent': 0,
                \ 'buttons': [
                \   {'name': 'Submit', 'label': '&Submit'},
                \   {'name': 'Cancel', 'label': '&Cancel'},
                \ ],
                \ 'values': {},
                \ 'fields': [],
                \ '_fields': {},
                \ 'header': [],
                \ 'footer': [
                \   'Press <F1> for help'
                \ ]}
endif


" Show the form in a split window.
function! g:vimform#prototype.Split() dict "{{{3
    call self.Show('split')
endf


" :display: g:vimform#prototype#Show(?cmd = "split")
" Show the form.
" cmd should create a new buffer. By default, the new buffer will be 
" shown in a split view.
function! g:vimform#prototype.Show(...) dict "{{{3
    let cmd = a:0 >= 1 ? a:1 : 'split'
    exec cmd fnameescape(self.name)
    let self.bufnr = bufnr('%')
    let b:vimform = self.Setup()
    setlocal filetype=vimform
    call self.SetIndent()
    call self.Display()
    autocmd! Vimform * <buffer>
    autocmd Vimform CursorMoved,CursorMovedI <buffer> call b:vimform.CursorMoved()
endf


function! g:vimform#prototype.Setup() dict "{{{3
    let self._fields = {}
    for def in self.fields
        let name = get(def, 0)
        if name !~ '^-'
            let def1 = get(def, 1, {})
            let self._fields[name] = def1
        endif
    endfor
    
    let self._buttons = {}
    for button in self.buttons
        let name = self.GetButtonLabel(button)
        let self._buttons[name] = button
    endfor

    return self
endf


function! g:vimform#prototype.Reset(vanilla) dict "{{{3
    if a:vanilla
        let self.values = {}
    " else
    "     call self.CollectFields()
    endif
    call self.Show('edit')
endf


let s:vimform_modification = 0
let s:indent_plus = 3
let s:special_line_rx = '\^\(| \.\+ |\|" \.\+\|_\+ \.\{-} _\+\)\$'

function! g:vimform#prototype.Display() dict "{{{3
    setlocal modifiable
    1,$delete

    let width = winwidth(0) - &foldcolumn - 4

    if !empty(self.header)
        call append('$', map(copy(self.header), 'printf(''" %''. (width - 2) .''s "'', v:val)'))
    endif

    let fmt = ' %'. (self.indent - s:indent_plus) .'s: %s'
    " TLogVAR fmt
    for def0 in self.fields
        let name = get(def0, 0)
        if name =~ '^-'
            let text = matchstr(name, '^-\+\s\+\zs.*$')
            let npre = self.indent - 1
            let npost = width - npre - len(text)
            let line = repeat('_', npre) .' '. text .' '. repeat('_', npost)
        else
            let def = get(def0, 1, {})
            let type = get(def, 'type', 'text')
            let value = get(self.values, name, get(def, 'value', ''))
            if type == 'checkbox'
                let text = printf('[%s]', empty(value) ? ' ' : 'X')
            else
                let text = value
            endif
            let line = printf(fmt, name, text)
        endif
        call append('$', line)
    endfor

    let formatted_buttons = []
    for button in self.buttons
        call add(formatted_buttons, s:FormatButton(self.GetButtonLabel(button)))
    endfor
    if !empty(formatted_buttons)
        let formatted_buttons_str = printf('| %'. (width - 2) .'s |', join(formatted_buttons))
        call append('$', formatted_buttons_str)
    endif

    if !empty(self.footer)
        call append('$', map(copy(self.footer), 'printf(''" %''. (width - 2) .''s "'', v:val)'))
    endif

    0delete
    call s:SetAccellerators()
    norm! ggzt
    call self.NextField('cw', 1)
endf


function! s:EnsureBuffer() "{{{3
    if !exists('b:vimform') || bufnr('%') != b:vimform.bufnr
        " TLogVAR bufnr('%'), self.bufnr
        throw "Vimform: Wrong buffer"
    endif
endf


function! s:FormatButton(name) "{{{3
    return printf('<<%s>>', a:name)
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


function! g:vimform#prototype.Submit() dict "{{{3
    let m = matchlist(getline('.'), '<<\([^>]\{-}\%'. col('.') .'c[^>]\{-}\)>>')
    if empty(m)
        let name = 'Submit'
    else
        let name = substitute(m[1], '&', '', 'g')
        let name = substitute(name, '\W', '_', 'g')
        " TLogVAR name
    endif
    call self.CollectFields()
    if self.Validate()
        let cb_name = 'Do_'. name
        if name == 'Cancel'
            call self.Do_Cancel()
        elseif name == 'Submit'
            call self.Do_Cancel()
            call self.Do_Submit()
        elseif has_key(self, cb_name)
            call self.{cb_name}()
        else
            throw "VimForm: Unknown button: ". name
        endif
    endif
endf


function! g:vimform#prototype.Do_Submit() dict "{{{3
endf


function! g:vimform#prototype.Do_Cancel() dict "{{{3
    wincmd c
endf


function! g:vimform#prototype.Validate() dict "{{{3
    let invalid_values = filter(copy(self.values), '!self.ValidateField(v:key, v:val)')
    if !empty(invalid_values)
        echohl WarningMsg
        let error_rx = []
        for [field, value] in items(invalid_values)
            call add(error_rx, self.GetFieldRx(field))
            let def = self._fields[field]
            let msg = 'Invalid value for '. field .': '. string(value)
            if len(def) > 1 && has_key(def, 'message')
                let msg .= ': '. def.message
            endif
            echom msg
        endfor
        echohl NONE
        exec '3match Error /'. escape(join(error_rx, '\|'), '/') .'/'
        call search(error_rx[0], 'ew')
        call s:Feedkeys('a', 1)
        return 0
    else
        3match none
        return 1
    endif
endf


function! g:vimform#prototype.ValidateField(field, value) dict "{{{3
    let def = self._fields[a:field]
    let validate = get(def, 'validate', '')
    if empty(validate)
        return 1
    else
        return eval(printf(validate, string(a:value)))
    endif
endf


function! g:vimform#prototype.NextField(flags, insertmode) dict "{{{3
    call s:EnsureBuffer()
    exec 'resize '. line('$')
    let frx = self.GetFieldsRx()
    let brx = self.GetButtonsRx()
    let rx = frx .'\|'. brx
    let name = self.GetCurrentFieldName()
    if !empty(name)
        let self.values[name] = self.GetField(name)
        if a:flags =~ 'b'
            norm! 0
        endif
    endif
    let lnum = search(rx, 'e'. a:flags)
    if lnum && getline(lnum) =~ frx
        call cursor(lnum, self.indent + 1)
        let type = self.GetCurrentFieldType()
        if type == 'checkbox'
            call s:Feedkeys('l', 1)
        elseif col('.') == col('$') - 1
            call s:Feedkeys('a', 1)
        else
            call s:Feedkeys('i', 1)
        endif
    endif
endf


" :display: g:vimform#prototype.GetCurrentFieldName(?pos = '.') dict "{{{3
function! g:vimform#prototype.GetCurrentFieldName(...) dict "{{{3
    let frx = self.GetFieldsRx()
    let view = winsaveview()
    try
        if a:0 >= 1
            call setpos('.', a:1)
        endif
        if search(frx, 'bW')
            return matchstr(getline('.'), self.GetFieldRx('\zs\.\{-}\ze'))
        endif
        return ''
    finally
        call winrestview(view)
    endtry
endf


function! g:vimform#prototype.GetCurrentFieldType() dict "{{{3
    let field = self.GetCurrentFieldName()
    if empty(field)
        return ''
    else
        let type = get(self._fields[field], 'type', 'text')
        return type
    endif
endf


function! s:Modifiable() "{{{3
    let s:vimform_modification = 1
    setlocal modifiable
endf


function! s:Feedkeys(keys, level) "{{{3
    " TLogVAR a:keys
    call s:Modifiable()
    call feedkeys(a:keys, 'n')
endf


function! g:vimform#prototype.CursorMoved() dict "{{{3
    let lnum = line('.')
    let line = getline(lnum)
    let field = self.GetCurrentFieldName()
    " TLogVAR line, len(line)
    if line !~ '\S' && len(line) < self.indent
        let s:vimform_modification = 2
        setlocal modifiable
        call setline(lnum, repeat(' ', self.indent))
        " setlocal nomodifiable
        let s:vimform_modification = 0
    endif
    call self.SetModifiable()
    if !empty(field) && col('.') <= self.indent
        call cursor(lnum, self.indent + 1)
    endif
endf


function! g:vimform#prototype.SetModifiable() dict "{{{3
    if s:vimform_modification == 2
        let modifiable = 1
    elseif s:vimform_modification == 1
        let s:vimform_modification = 0
        let modifiable = 1
    else
        let line = getline('.')
        if line =~ s:special_line_rx
            let modifiable = 0
        else
            let field = self.GetCurrentFieldName()
            " TLogVAR field
            if empty(field)
                let modifiable = 0
            else
                " TLogVAR col('.'), self.indent
                if col('.') <= self.indent
                    let modifiable = 0
                else
                    let type = get(self._fields[field], 'type', 'text')
                    if type == 'checkbox'
                        let modifiable = 0
                        " let modifiable = getline('.')[col('.')] == ']'
                        " call feedkeys("\<c-\>\<c-o>", 0)
                    else
                        let modifiable = 1
                    endif
                endif
            endif
        endif
    endif
    " TLogVAR modifiable
    " let &l:modifiable = modifiable
    if modifiable
        setlocal modifiable
    else
        setlocal nomodifiable
    endif
endf


function! g:vimform#prototype.SpecialKey(key) dict "{{{3
    let view = winsaveview()
    try
        let type = self.GetCurrentFieldType()
    finally
        call winrestview(view)
    endtry
    let key = a:key
    " TLogVAR type
    if type == 'checkbox'
        call s:ToggleCheckbox()
    elseif !empty(key)
        call feedkeys(key, 't')
    endif
endf


function! g:vimform#prototype.Key(key) dict "{{{3
    " TLogVAR a:key
    let key = a:key
    if a:key =~ '^[ai]$'
        let ccol = col('.')
        let ecol = col('$')
        " TLogVAR ccol, ecol, self.indent
        if a:key == 'a' && ccol < self.indent
            let key = ''
        elseif a:key == 'i' && ccol <= self.indent
            let key = ''
        elseif ccol >= self.indent
            call s:Modifiable()
        endif
    endif
    return key
endf


function! s:ToggleCheckbox() "{{{3
    let line = getline('.')
    if line =~ '\[ \]$'
        let value = 'X'
    else
        let value = ' '
    endif
    " TLogVAR value
    let s:vimform_modification = 2
    call b:vimform.SetModifiable()
    let line = substitute(line, '\[\zs.\ze\]$', value, '')
    call setline('.', line)
    let s:vimform_modification = 0
endf


function! g:vimform#prototype.SetIndent() dict "{{{3
    let self.indent = max(map(keys(self._fields), 'len(v:val) + s:indent_plus'))
endf


function! g:vimform#prototype.GetButtonLabel(def) dict "{{{3
    return get(a:def, 'label', a:def.name)
endf


function! g:vimform#prototype.GetButtonsRx() dict "{{{3
    let button_labels = map(copy(self.buttons), 'self.GetButtonLabel(v:val)')
    call map(button_labels, 'strpart(v:val, 1)')
    let rx = '\V<<\.\ze\('. join(button_labels, '\|') .'\)>>'
    " TLogVAR rx
    return rx
endf


function! g:vimform#prototype.CollectFields() dict "{{{3
    let self.values = self.GetAllFields()
endf


function! g:vimform#prototype.GetAllFields() dict "{{{3
    let dict = {}
    let names = self.GetOrderedFieldNames()
    " TLogVAR names
    for name in names
        let dict[name] = self.GetField(name, names)
    endfor
    return dict
endf


function! g:vimform#prototype.GetOrderedFieldNames() dict "{{{3
    return filter(map(copy(self.fields), 'v:val[0]'), 'v:val !~ ''^-''')
endf


function! g:vimform#prototype.GetField(name, ...) dict "{{{3
    call s:EnsureBuffer()
    let quiet = a:0 >= 1
    let names = a:0 >= 1 ? a:1 : self.GetOrderedFieldNames()
    let index = index(names, a:name)
    if index == -1
        echoerr 'VimForm: No field of that name:' a:name
    else
        let view = winsaveview()
        try
            let def = self._fields[a:name]
            let type = get(def, 'type', 'text')
            let crx = self.GetFieldRx(a:name)
            let start = search(crx, 'w')
            " TLogVAR a:name, crx, start
            if start
                if index < len(names) - 1
                    let nrx = self.GetFieldsRx() .'\|'. s:special_line_rx
                    let end = search(nrx, 'w') - 1
                else
                    let end = line('$')
                endif
                " TLogVAR end
                if end
                    let lines = getline(start, end)
                    call map(lines, 'strpart(v:val, self.indent)')
                    " TLogVAR lines
                    if has_key(def, 'join')
                        let ljoin = def.join
                        let pjoin = def.join
                    else
                        let ljoin = get(def, 'joinlines', ' ')
                        let pjoin = get(def, 'joinparas', "\n")
                    endif
                    let out = []
                    for line in lines
                        if line =~ '\S'
                            if len(out) > 0 && out[-1] != "\n"
                                call add(out, ljoin)
                            endif
                            call add(out, line)
                        elseif len(out) > 0
                            call add(out, pjoin)
                        endif
                    endfor
                    let value = join(out, '')
                    " TLogVAR ljoin, pjoin, out, value
                    if type == 'checkbox'
                        let value = value =~ 'X'
                    endif
                    let return = get(def, 'return', {})
                    if !empty(return) && has_key(return, value)
                        return return[value]
                    else
                        return value
                    endif
                endif
            endif
            if quiet
                return type == 'checkbox' ? 0 : ''
            else
                echoerr 'VimForm: Field not found: ' a:name
            endif
        finally
            call winrestview(view)
        endtry
    endif
endf


function! g:vimform#prototype.GetFieldRx(name) dict "{{{3
    return '\V\^ \+'. a:name .': '
endf


function! g:vimform#prototype.GetFieldsRx() dict "{{{3
    let rxs = map(keys(self._fields), 'escape(v:val, ''\'')')
    return '\V\^ \+\('. join(rxs, '\|') .'\): '
endf


function! g:vimform#prototype.Indent() dict "{{{3
    let indent = self.indent
    let cline = getline(v:lnum)
    let rx = self.GetFieldsRx()
    " TLogVAR v:lnum, indent, cline
    " call tlog#Debug(cline =~# self.GetFieldsRx())
    if cline =~# self.GetFieldsRx()
        let indent = 0
    endif
    " TLogVAR indent
    return indent
endf


function! vimform#Balloon() "{{{3
    call s:EnsureBuffer()
    let pos = [v:beval_bufnr, v:beval_lnum, v:beval_col, 0]
    let field = b:vimform.GetCurrentFieldName(pos)
    if !empty(field)
        return get(b:vimform._fields[field], 'tooltip', '')
    endif
endf


function! vimform#Complete1() "{{{3
    return pumvisible() ? "\<c-n>" : "\<c-x>\<c-o>"
endf


function! vimform#Complete(findstart, base) "{{{3
    if exists('b:vimform')
        if a:findstart
            let field = b:vimform.GetCurrentFieldName()
            " TLogVAR a:findstart, a:base, field
            let def = b:vimform._fields[field]
            let b:vimform_complete = get(def, 'complete', '')
        endif
        if empty(b:vimform_complete)
            if a:findstart
                return col('.')
            else
                return ''
            endif
        else
            return call(b:vimform_complete, [a:findstart, a:base])
        endif
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo

finish

0.1
Initial

0.2
- Changed syntax & everything

