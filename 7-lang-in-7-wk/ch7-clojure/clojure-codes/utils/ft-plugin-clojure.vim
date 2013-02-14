" usage:
"     append the content of this file to `~/.vim/ftdetect/clojure.vim`
"     use <F7> to run the script, `-main` in the current file will be called
"
" dependency:
"     vim-foreplay 	https://github.com/tpope/vim-foreplay
"

" <F7> always stands for running the program

function! s:GetCurrentClojureNamespace()
	let first_line = getline(1)
	let curr_name_sp = matchstr( first_line, '(ns\s\+\zs[a-z0-9.-]\+\ze' )

	if empty(curr_name_sp)
		throw "cannot find any clojure namespace in first line"
	endif

	return curr_name_sp
endfunction

if exists("g:loaded_foreplay")
	let b:clj_ns = s:GetCurrentClojureNamespace()
	let b:eval_cmd = 'Eval (' . b:clj_ns . '/-main)'
	" relies on 'cpR' and ':Eval' from foreplay.vim
	execute 'nmap <F7> :w<CR>cpR:'.b:eval_cmd.'<CR>'
else
	nmap <F7> :w<CR>:! lein-ns-run %<CR>
endif
