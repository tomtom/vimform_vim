" vimform.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2017-03-25.
" @Revision:    1.0.44

if version < 600
    syntax clear
elseif exists('b:current_syntax')
    finish
endif
if version < 508
    command! -nargs=+ HiLink hi link <args>
else
    command! -nargs=+ HiLink hi def link <args>
endif


syn match VimformSeparator /^_\+ .\{-} _\+$/
syn match VimformComment /^" .*$/
syn match VimformButton /<<.\{-}>>/ contained containedin=VimformControls
syn match VimformControls /^| .* |$/ contains=VimformButton
syn match VimformAttribute /^ \(File\|Dir\)| / contained containedin=VimformLabel
syn match VimformLabel /^ \+.\{-}\ze: / contains=VimformAttribute

HiLink VimformAttribute Type
HiLink VimformLabel Constant 
HiLink VimformButton Special
HiLink VimformControls Identifier
HiLink VimformSeparator PreProc
HiLink VimformComment Comment


delcommand HiLink
let b:current_syntax = 'vimform'
