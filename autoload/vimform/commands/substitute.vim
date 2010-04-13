" substitute.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.lithom.net
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-04-13.
" @Last Change: 2010-04-13.
" @Revision:    0.0.26


let s:substitute_form = vimform#SimpleForm()
let s:substitute_form.name = "Search & Replace"
let s:substitute_form.rx = '^s\%[ubstitute]'
let s:substitute_form.options = 'tw=0'
let s:substitute_form.fields = [
            \ ['Search', {'tooltip': 'A regular expression', 'join': '\n', 'validate': 'vimform#commands#substitute#ValidateRegexp(%s)'}],
            \ ['Replace', {'value': '&', 'tooltip': 'The replacement expression', 'validate': 'vimform#commands#substitute#ValidateSubst(%s)'}],
            \ ['--- Options'],
            \ ['Range', {'value': '1,$'}],
            \ ['Replace all', {'value': 1, 'type': 'checkbox', 'return': {'1': 'g', '0': ''}}],
            \ ['Case-sensitive', {'type': 'checkbox', 'return': {'1': 'I', '0': ''}}],
            \ ['Confirm', {'value': 1, 'type': 'checkbox', 'return': {'1': 'c', '0': ''}}],
            \ ]

function! s:substitute_form.Do_Submit() dict "{{{3
    let search = self.values['Search']
    if !empty(search)
        let flags = map(["Replace all", "Case-sensitive", "Confirm"], 'self.values[v:val]')
        let replace = self.values['Replace']
        if replace == '&'
            if index(flags, 'I') != -1
                let search = '\C'. search
            endif
            let cmd = printf(':/%s',
                        \ escape(search, '/'))
        else
            let cmd = printf(':%ss/%s/%s/%se',
                        \ self.values.Range,
                        \ escape(search, '/'),
                        \ escape(replace, '/'),
                        \ join(flags, ''))
        endif
        " TLogVAR cmd
        call feedkeys(cmd ."\<cr>", 'n')
    endif
endf


function! vimform#commands#substitute#ValidateRegexp(rx) "{{{3
    try
        call match("x", a:rx)
        return 1
    catch
        return 0
    endtry
endf


function! vimform#commands#substitute#ValidateSubst(str) "{{{3
    try
        call substitute('a', '.', a:str, '')
        return 1
    catch
        return 0
    endtry
endf


let g:vimform#forms['substitute'] = s:substitute_form


