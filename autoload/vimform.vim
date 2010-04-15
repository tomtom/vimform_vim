" vimform.vim -- Simple forms for vim scripts
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-15.
" @Revision:    0.0.1561

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


if !exists('g:vimform#forms')
    let g:vimform#forms = {}   "{{{2
endif


if !exists('g:vimform#view')
    let g:vimform#view = "split"   "{{{2
endif


if !exists('g:vimform#prototype')
    " The default form tepmlate.
    " :read: let g:vimform#prototype = {...}   "{{{2
    let g:vimform#prototype = {
                \ 'name': '__Form__',
                \ 'indent': 0,
                \ 'options': '',
                \ 'buttons': [
                \   {'name': 'Submit', 'label': '&Submit'},
                \   {'name': 'Cancel', 'label': '&Cancel'},
                \ ],
                \ 'values': {},
                \ 'fields': [],
                \ '_fields': {},
                \ '_formattedlabels': {},
                \ 'mapargs': {},
                \ 'header': [
                \   '<F1>:help; <F5>:redraw; <TAB>:next field; <C-CR>:submit'
                \ ],
                \ 'footer': [
                \ ]}
endif


if !exists('g:vimform#widgets')
    let g:vimform#widgets = {}   "{{{2
    runtime! autoload/vimform/widgets/*.vim
endif



let s:vimform_modification = 0
let s:indent_plus = 3
let s:skip_line_rx = '\V\^\(" \.\+\|_\+ \.\{-} _\+\)\$'
let s:special_line_rx = s:skip_line_rx .'\V\|\^\(| \.\{-} |\)\$'
let s:done_commands = 0


function! g:vimform#prototype.Delegate(fieldname, method, ...) dict "{{{3
    " TLogVAR "Delegate", a:fieldname, a:method, a:000
    if !empty(a:fieldname)
        let field = self._fields[a:fieldname]
        return call(field[a:method], [self] + a:000, field)
    endif
endf


function! g:vimform#prototype.DelegateCurrentField(method, ...) dict "{{{3
    " TLogVAR "DelegateCurrentField", a:method, a:000
    " TLogVAR keys(self)
    let fieldname = self.GetCurrentFieldName()
    return call(self.Delegate, [fieldname, a:method] + a:000, self)
endf


" Show the form in a split window.
function! g:vimform#prototype.Split() dict "{{{3
    call self.Show('split')
endf


" :display: g:vimform#prototype#Show(?cmd = "split")
" Show the form.
" cmd should create a new buffer. By default, the new buffer will be 
" shown in a split view.
function! g:vimform#prototype.Show(...) dict "{{{3
    let cmd = a:0 >= 1 ? a:1 : g:vimform#view
    silent exec cmd fnameescape(self.name)
    let self.bufnr = bufnr('%')
    let b:vimform = self.Setup()
    setlocal filetype=vimform
    if !empty(self.options)
        exec 'setlocal '. self.options
    endif
    call self.SetIndent()
    call self.Display()
    autocmd! Vimform * <buffer>
    autocmd Vimform CursorMoved,CursorMovedI <buffer> call b:vimform.CursorMoved()
endf


function! g:vimform#prototype.Setup() dict "{{{3
    let self._fields = {}
    for def in self.fields
        let fieldname = get(def, 0)
        if fieldname !~ '^-'
            let def1 = get(def, 1, {})
            let type = get(def1, 'type', 'text')
            " TLogVAR fieldname, type
            call extend(def1, g:vimform#widgets[type], 'keep')
            let def1.name = fieldname
            let def1.formattedlabel = def1.FormatLabel(self)
            let self._formattedlabels[def1.formattedlabel] = fieldname
            let self._fields[fieldname] = def1
        endif
    endfor

    let self._buttons = {}
    for button in self.buttons
        let buttonname = self.GetButtonLabel(button)
        let self._buttons[buttonname] = button
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


function! g:vimform#prototype.Display() dict "{{{3
    setlocal modifiable
    " TLogVAR line('$')
    %delete

    let width = winwidth(0) - &foldcolumn - 4

    if !empty(self.header)
        call append('$', map(copy(self.header), 'printf(''" %''. (width - 2) .''s "'', v:val)'))
    endif

    let fmt = ' %'. (self.indent - s:indent_plus) .'s: %s'
    " TLogVAR fmt
    for def0 in self.fields
        let fieldname = get(def0, 0)
        if fieldname =~ '^-'
            let text = matchstr(fieldname, '^-\+\s\+\zs.*$')
            let npre = self.indent - 1
            let npost = width - npre - len(text)
            let line = repeat('_', npre) .' '. text .' '. repeat('_', npost)
        else
            let def = self._fields[fieldname]
            let type = get(def, 'type', 'text')
            let value = get(self.values, fieldname, get(def, 'value', ''))
            let text = self.Delegate(fieldname, 'Format', value)
            let line = printf(fmt, def.formattedlabel, text)
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
    call self.NextField('cw', 0, 1)
endf


function! s:EnsureBuffer() "{{{3
    if !exists('b:vimform') || bufnr('%') != b:vimform.bufnr
        " TLogVAR bufnr('%'), self.bufnr
        throw "Vimform: Wrong buffer"
    endif
endf


function! s:FormatButton(buttonname) "{{{3
    return printf('<<%s>>', a:buttonname)
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
        let buttonname = 'Submit'
    else
        let buttonname = substitute(m[1], '&', '', 'g')
        let buttonname = substitute(buttonname, '\W', '_', 'g')
        " TLogVAR buttonname
    endif
    call self.CollectFields()
    if self.Validate()
        let cb_name = 'Do_'. buttonname
        if buttonname == 'Cancel'
            call self.Do_Cancel()
        elseif buttonname == 'Submit'
            call self.Do_Cancel()
            call self.Do_Submit()
        elseif has_key(self, cb_name)
            call self.{cb_name}()
        else
            throw "VimForm: Unknown button: ". buttonname
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
        let msgs = []
        let error_rx = map(keys(invalid_values), 'self.GetFieldRx(v:val)')
        exec '3match Error /'. escape(join(error_rx, '\|'), '/') .'/'
        redraw
        for [field, value] in items(invalid_values)
            let def = self._fields[field]
            let msg = 'Invalid value for '. field .': '. string(value)
            if len(def) > 1 && has_key(def, 'message')
                let msg .= ': '. def.message
            endif
            echom msg
        endfor
        echohl MoreMsg
        echo "Press any KEY to continue"
        echohl NONE
        call getchar()
        call search(error_rx[0], 'ew')
        call vimform#Feedkeys('a', 1)
        return 0
    else
        3match none
        return 1
    endif
endf


function! g:vimform#prototype.ValidateField(field, value) dict "{{{3
    let validate = self.Delegate(a:field, 'GetValidate')
    if empty(validate)
        return 1
    else
        return eval(printf(validate, string(a:value)))
    endif
endf


function! g:vimform#prototype.NextField(flags, in_insertmode, to_insertmode) dict "{{{3
    " TLogVAR a:flags, a:in_insertmode, a:to_insertmode
    call s:EnsureBuffer()
    exec 'resize '. line('$')
    let frx = self.GetFieldsRx()
    let brx = self.GetButtonsRx()
    let rx = frx .'\|'. brx
    " TLogVAR rx
    let fieldname = self.GetCurrentFieldName()
    if !empty(fieldname)
        let self.values[fieldname] = self.GetField(fieldname)
        if a:flags =~ 'b'
            norm! 0
        endif
    endif
    let lnum = search(rx, 'e'. a:flags)
    if lnum && getline(lnum) =~ frx
        " TLogVAR lnum
        call cursor(lnum, self.indent + 1)
        call self.DelegateCurrentField('SelectField', a:to_insertmode)
    endif
endf


function! vimform#AppendOrInsert() "{{{3
    let val = col('.') == col('$') - 1 ? 'a' : 'i'
    " TLogVAR col('.'), col('$'), val
    return val
endf


function! vimform#Insertmode() "{{{3
    call vimform#Feedkeys(vimform#AppendOrInsert(), 0)
endf


" :display: g:vimform#prototype.GetCurrentFieldName(?pos = '.') dict "{{{3
function! g:vimform#prototype.GetCurrentFieldName(...) dict "{{{3
    let frx = self.GetFieldsRx() .'\|'. s:special_line_rx
    " TLogVAR frx
    let view = {}
    if a:0 >= 1
        if type(a:1) == 0
            let lnum = a:1
        else
            let lnum = a:1[1]
        endif
        " TLogVAR a:1, lnum
    else
        let lnum = line('.')
    endif
    let frx = self.GetFieldRx('\zs\.\{-}\ze')
    let fieldname = ''
    while lnum > 0
        let line = getline(lnum)
        if line =~ frx
            let fieldname = matchstr(line, frx)
            break
        endif
        let lnum -= 1
    endwh
    " TLogVAR lnum, getline(lnum), fieldname
    if !empty(fieldname)
        let fieldname = get(self._formattedlabels, fieldname, fieldname)
        " TLogVAR fieldname
        " echom "DBG ". string(keys(self._formattedlabels))
    endif
    " TLogVAR line('.'), lnum, fieldname
    return fieldname
endf


function! g:vimform#prototype.GetFieldType(fieldname) dict "{{{3
    return get(self._fields[a:fieldname], 'type', 'text')
endf


function! vimform#Feedkeys(keys, level) "{{{3
    call b:vimform.SetModifiable(a:level)
    " TLogVAR a:keys, a:level, col('.'), col('$'), &modifiable
    call feedkeys(a:keys, 't')
endf


function! g:vimform#prototype.CursorMoved() dict "{{{3
    let lnum = line('.')
    let line = getline(lnum)
    " TLogVAR line
    if line =~ s:skip_line_rx
        call self.NextField('w', mode() == 'i', mode() != 'i')
    else
        " TLogVAR line, len(line)
        " TLogVAR col('$'), self.indent, mode()
        if col('$') - 1 < self.indent
            let diff = self.indent - len(line)
            let line .= repeat(' ', diff)
            " let vimform_modification = s:vimform_modification
            call self.SetModifiable(1)
            call setline(lnum, line)
            " let s:vimform_modification = vimform_modification
        endif
        call self.DelegateCurrentField('SetCursorMoved', mode() == 'i', lnum)
        " TLogVAR &modifiable, field, col('.'), self.indent
        call self.SetModifiable()
    endif
endf


function! g:vimform#prototype.SetModifiable(...) dict "{{{3
    if a:0 >= 1
        if a:1 >= 0
            let s:vimform_modification += a:1
        " elseif a:1 == 0
        "     let s:vimform_modification = 0
        else
            let s:vimform_modification = a:1
        endif
    endif
    " echom "DBG s:vimform_modification=". s:vimform_modification
    if s:vimform_modification < 0
        let modifiable = 1
    elseif s:vimform_modification > 0
        let s:vimform_modification -= 1
        let modifiable = 1
    else
        let line = getline('.')
        if line =~ s:special_line_rx
            let modifiable = 0
        else
            let fieldname = self.GetCurrentFieldName()
            " TLogVAR fieldname
            if empty(fieldname) || !self._fields[fieldname].modifiable
                let modifiable = 0
            else
                " TLogVAR col('.'), self.indent
                if col('.') <= self.indent
                    let modifiable = 0
                else
                    let modifiable = self._fields[fieldname].modifiable
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


function! g:vimform#prototype.SaveMapargs(...) dict "{{{3
    " TLogVAR a:000
    for map in a:000
        let arg = maparg(map)
        let arg = eval('"'. escape(substitute(arg, '<', '\\<', 'g'), '"') .'"')
        let self.mapargs[map] = arg
    endfor
endf


function! vimform#PumKey(key) "{{{3
    " TLogVAR a:key
    if pumvisible()
        let self = b:vimform
        call self.SetModifiable(1)
        let key = self.DelegateCurrentField('GetPumKey', a:key)
        return key
    else
        return a:key
    endif
endf


function! vimform#SpecialInsertKey(key, pumkey, prepend) "{{{3
    " TLogVAR a:key, a:prepend
    if pumvisible()
        return a:pumkey
    else
        let self = b:vimform
        let key = self.DelegateCurrentField('GetSpecialInsertKey', a:key)
        if a:prepend
            let key = a:key . key
        endif
        return key
    endif
endf


function! g:vimform#prototype.SpecialKey(key, insertmode) dict "{{{3
    let mode = 'n'
    let key = a:key
    " TLogVAR key, pumvisible()
    if !pumvisible()
        let fieldname = self.GetCurrentFieldName()
        let key = self.Delegate(fieldname, 'GetSpecialKey', fieldname, key)
    endif
    if !empty(key)
        " TLogVAR key, mode
        call feedkeys(key, mode)
    endif
endf


function! g:vimform#prototype.Key(key) dict "{{{3
    let key = self.DelegateCurrentField('GetKey', a:key)
    " TLogVAR a:key, key
    return key
endf


function! g:vimform#prototype.Key_dd() dict "{{{3
    let key = self.DelegateCurrentField('Key_dd')
    return key
endf


function! g:vimform#prototype.Key_BS() dict "{{{3
    let key = self.DelegateCurrentField('Key_BS')
    return key
endf


function! g:vimform#prototype.Key_DEL() dict "{{{3
    let key = self.DelegateCurrentField('Key_DEL')
    return key
endf


function! g:vimform#prototype.SetIndent() dict "{{{3
    let self.indent = max(map(copy(self._fields), 'len(v:val.formattedlabel) + s:indent_plus'))
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
    for fieldname in names
        let dict[fieldname] = self.GetField(fieldname, names)
    endfor
    return dict
endf


function! g:vimform#prototype.GetOrderedFieldNames() dict "{{{3
    return filter(map(copy(self.fields), 'v:val[0]'), 'v:val !~ ''^-''')
endf


function! g:vimform#prototype.GetField(fieldname, ...) dict "{{{3
    call s:EnsureBuffer()
    let names = a:0 >= 1 ? a:1 : self.GetOrderedFieldNames()
    let index = index(names, a:fieldname)
    if index == -1
        echoerr 'VimForm: No field of that name:' a:fieldname
    else
        let view = winsaveview()
        let def = self._fields[a:fieldname]
        try
            let crx = self.GetFieldRx(a:fieldname)
            let start = search(crx, 'w')
            " TLogVAR a:fieldname, crx, start
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
                    let value = self.Delegate(a:fieldname, 'GetFieldValue', join(out, ''))
                    " TLogVAR ljoin, pjoin, out, value
                    let return = get(def, 'return', {})
                    if !empty(return) && has_key(return, value)
                        return return[value]
                    else
                        return value
                    endif
                endif
            endif
            return def.default_value
        finally
            call winrestview(view)
        endtry
    endif
endf


function! g:vimform#prototype.GetIndentRx() dict "{{{3
    return '\V\s\{'. self.indent .'}'
endf


function! g:vimform#prototype.GetFieldRx(fieldname) dict "{{{3
    return '\V\^ \+'. a:fieldname .':\%'. self.indent .'c '
endf


function! g:vimform#prototype.GetFieldsRx() dict "{{{3
    let rxs = map(values(self._fields), 'escape(v:val.formattedlabel, ''\'')')
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
        let self = b:vimform
        if a:findstart
            let field = self.GetCurrentFieldName()
            " TLogVAR a:findstart, a:base, field
            let def = self._fields[field]
            let type = self.GetFieldType(field)
            if type == 'singlechoice'
                let s:vimform_list = get(def, 'list', [])
            endif
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


function! vimform#CompleteSingleChoice(findstart, base) "{{{3
    " TLogVAR a:findstart, a:base
    let self = b:vimform
    " if a:findstart == -1
    "     let rx = '\V'. escape(a:base, '\')
    "     let list = filter(copy(s:vimform_list), 'v:val =~ rx')
    "     " TLogVAR list
    "     call complete(b:vimform.indent + 1, list)
    "     return ''
    " elseif a:findstart
    if a:findstart
        let self = b:vimform
        return self.indent
    else
        let rx = '\V'. escape(a:base, '\')
        call self.SetModifiable(1)
        " return filter(copy(s:vimform_list), 'v:val =~ rx')
        return s:vimform_list
    endif
endf


function! vimform#CommandComplete(ArgLead, CmdLine, CursorPos) "{{{3
    if !s:done_commands
        let s:done_commands = 1
        runtime! autoload/vimform/forms/*.vim
    endif
    let commands = copy(g:vimform#forms)
    " TLogVAR commands
    if !empty(a:ArgLead)
        call filter(commands, 'a:ArgLead =~ v:val.rx')
    endif
    " TLogVAR commands
    return keys(commands)
endf


function! vimform#Command(cmd) "{{{3
    let cmds = vimform#CommandComplete(a:cmd, '', 0)
    " TLogVAR cmds
    if len(cmds) == 1
        let form = g:vimform#forms[cmds[0]]
        call form.Show(g:vimform#view)
    else
        echoerr "Vimform: Unknown or ambivalent command: ". a:cmd
    endif
endf


function! s:GetField(...) "{{{3
    let lnum = a:0 >= 1 ? a:1 : line('.')
    let lbeg = s:FieldBegin(lnum)
    let lend = s:FieldEnd(lnum)
    let lines = getline(lbeg, lend)
    let self = b:vimform
    call map(lines, 'strpart(v:val, self.indent)')
    return lines
endf


function! s:FieldBegin(...) "{{{3
    let lnum = a:0 >= 1 ? a:1 : line('.')
    let self = b:vimform
    let frx  = self.GetFieldsRx() .'\|'. s:special_line_rx
    while lnum > 0 && getline(lnum) !~ frx
        let lnum -= 1
    endwh
    return lnum
endf


function! s:FieldEnd(...) "{{{3
    let lnum1 = (a:0 >= 1 ? a:1 : line('.')) + 1
    let max = line('$')
    let self = b:vimform
    let frx  = self.GetFieldsRx() .'\|'. s:special_line_rx
    while lnum1 <= max && getline(lnum1) !~ frx
        let lnum1 += 1
    endwh
    return lnum1 - 1
endf


function! s:FieldNext(...) "{{{3
    let lnum = a:0 >= 1 ? a:1 : line('.')
    call self.NextField('w', 0, 0)
endf


let s:motions = {
            \ '(': 'Begin',
            \ ')': 'End',
            \ '{': 'Begin',
            \ '}': 'Next',
            \ '[': 'Begin',
            \ ']': 'Next',
            \ }


function! vimform#Motion(motion) "{{{3
    call s:EnsureBuffer()
    let l = line("'". a:motion)
    if l
        let self = b:vimform
        let a = self.GetCurrentFieldName()
        let b = self.GetCurrentFieldName(l)
        " TLogVAR l, a, b
        if a != b
            if has_key(s:motions, a:motion)
                let amot = s:motions[a:motion]
                let alnum = s:Field{amot}()
                if alnum
                    let alnum .= 'G'
                    if amot == 'Begin'
                        let alnum .= self.indent .'|'
                    elseif amot == 'End'
                        let alnum .= '$'
                    endif
                    return alnum
                endif
            endif
            return ''
        endif
    endif
    return a:motion
endf


" function! vimform#Motion(motion) "{{{3
"     call s:EnsureBuffer()
"     let field = s:GetField()
"     let view = winsaveview()
"     let lnum0 = s:FieldBegin()
"     let byte0 = line2byte(lnum0)
"     let pos = []
"     try
"         split __VimFormScratch__
"         setlocal buftype=nofile
"         setlocal bufhidden=hide
"         setlocal noswapfile
"         setlocal nobuflisted
"         setlocal foldmethod=manual
"         setlocal foldcolumn=0
"         setlocal modifiable
"         setlocal nospell
"         call setline(1, field)
"         exec 'norm! '. a:motion
"         let pos1 = getpos('.')
"         let byte1 = line2byte('.')
"     finally
"         wincmd c
"         call winrestview(view)
"     endtry
"     if !empty(pos)
"         let byte = byte0 + byte1 + pos1[2]
"         let ldiff = pos1[]
"         let self = b:vimform
"         let byte += (pos1[1] - lnum0) * self.indent
"         return byte .'go'
"     endif
"     return ''
" endf


let &cpo = s:save_cpo
unlet s:save_cpo

finish

0.1
Initial

0.2
- Changed syntax & everything

