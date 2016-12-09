" generate by http://www.villustrator.com/
set background=light
highlight clear
if exists("syntax on")
	syntax reset
endif
let g:colors_name="super_saiyajin_1"
hi Normal guifg=#e0e9ff guibg=#818c1a
hi Comment guifg=#e07bdd guibg=NONE
hi Constant guifg=#2b082b guibg=NONE
hi String guifg=#ff00ff guibg=NONE
hi htmlTagName guifg=#bf3f3f guibg=NONE
hi Identifier guifg=#2db5b5 guibg=NONE
hi Statement guifg=#8c3333 guibg=NONE
hi PreProc guifg=#ff80ff guibg=NONE
hi Type guifg=#60ff60 guibg=NONE
hi Function guifg=#000000 guibg=NONE
hi Repeat guifg=#000000 guibg=NONE
hi Operator guifg=#ff0000 guibg=NONE
hi Error guibg=#ff0000 guifg=#ffffff
hi TODO guibg=#0011ff guifg=#ffffff
hi link character	constant
hi link number	constant
hi link boolean	constant
hi link Float		Number
hi link Conditional	Repeat
hi link Label		Statement
hi link Keyword	Statement
hi link Exception	Statement
hi link Include	PreProc
hi link Define	PreProc
hi link Macro		PreProc
hi link PreCondit	PreProc
hi link StorageClass	Type
hi link Structure	Type
hi link Typedef	Type
hi link htmlTag	Special
hi link Tag		Special
hi link SpecialChar	Special
hi link Delimiter	Special
hi link SpecialComment Special
hi link Debug		Special
