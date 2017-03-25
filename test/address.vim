" vimform.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2017-03-25.
" @Revision:    98


let g:planets = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptun', 'Pluto FTW']
let form = vimform#New()
let form.name = 'Test Form'
let form.fields = [
            \ ['Name'],
            \ ['Address', {'join': "\n"}],
            \ ['Planet', {'value': 'Earth', 'type': 'singlechoice', 'list': g:planets}],
            \ ['Phone',   {'validate': '%s =~ ''^[0-9()+-]*$''', 'message': 'Must be a phone number'}],
            \ ['E-Mail', {'validate': '%s =~ ''^\([a-zA-Z.]\+@[a-zA-Z]\+\.[a-zA-Z.]\+\)\?$''', 'message': 'Must be an e-mail'}],
            \ ['Picture', {'type': 'file'}],
            \ ['Private', {'value': 0, 'type': 'checkbox'}],
            \ ['Business', {'value': 1, 'type': 'checkbox'}],
            \ ['Note'],
            \ ]
function! form.Do_Submit() dict "{{{3
    echom 'Test: '. self.name
    for [field, value] in items(self.values)
        echom 'Field' field string(value)
    endfor
endf

call form.Split()

