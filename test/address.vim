" vimform.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-04-10.
" @Revision:    90


let form = vimform#New()
let form.name = "Test Form"
let form.fields = [
            \ ['Name'],
            \ ['Address', {'join': "\n"}],
            \ ['Planet', {'value': 'Earth', 'complete': 'CompletePlanets', 'validate': 'index(g:planets, %s) != -1'}],
            \ ['Phone',   {'validate': '%s =~ ''^[0-9()+-]*$''', 'message': 'Must be a phone number'}],
            \ ['E-Mail', {'validate': '%s =~ ''^\([a-zA-Z.]\+@[a-zA-Z]\+\.[a-zA-Z.]\+\)\?$''', 'message': 'Must be an e-mail'}],
            \ ['Private', {'value': 0, 'type': 'checkbox'}],
            \ ['Business', {'value': 1, 'type': 'checkbox'}],
            \ ]
function! form.Do_Submit() dict "{{{3
    echom "Test: ". self.name
    for [field, value] in items(self.values)
        echom "Field" field value
    endfor
endf

let g:planets = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptun', 'Pluto FTW']
function! CompletePlanets(findstart, base) "{{{3
    if a:findstart
        return match(getline('.'), '\k\{-}\%'. col('.') .'c')
    else
        let rx = '\V'. escape(a:base, '\')
        return filter(copy(g:planets), 'v:val =~ rx')
    endif
endf

call form.Split()

