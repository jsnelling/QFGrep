" QFGrep  : a vim plugin to filter Quickfix entries
" Author  : Kai Yuan <kent.yuan@gmail.com>
" License: {{{
"Copyright (c) 2013 Kai Yuan
"Permission is hereby granted, free of charge, to any person obtaining a copy of
"this software and associated documentation files (the "Software"), to deal in
"the Software without restriction, including without limitation the rights to
"use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
"the Software, and to permit persons to whom the Software is furnished to do so,
"subject to the following conditions:
"
"The above copyright notice and this permission notice shall be included in all
"copies or substantial portions of the Software.
"
"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
"FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
"COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
"IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
"CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
if exists("g:loaded_QFGrep") || &cp
  finish
endif

let s:version       = "1.0.2"

let g:loaded_QFGrep = 1

let s:origQF        = !exists("s:origQF")? [] : s:origQF

"mappings
let g:QFG_Grep      = !exists('g:QFG_Grep')? '<Leader>g' : g:QFG_Grep
let g:QFG_GrepV     = !exists('g:QFG_GrepV')? '<Leader>v' : g:QFG_GrepV
let g:QFG_Restore   = !exists('g:QFG_Restore')? '<Leader>r' : g:QFG_Restore

"highlighting
if !exists('g:QFG_hi_prompt')
  let g:QFG_hi_prompt='ctermbg=68 ctermfg=16 guibg=#5f87d7 guifg=black'
endif

"a buffer variable, to store a flag, if current buffer is :
"quickfix_list (1) (default)
"location_list(0)
" This variable must be set when the buffer loaded
let b:isQF = 1


if !exists('g:QFG_hi_info')
  let g:QFG_hi_info = 'ctermbg=113 ctermfg=16 guibg=#87d75f guifg=black'
endif

if !exists('g:QFG_hi_error')
  let g:QFG_hi_error = 'ctermbg=167 ctermfg=16 guibg=#d75f5f guifg=black'
endif

"the message header
let s:msgHead = '[QFGrep] ' 

"helpers
function! <SID>SaveQuickFix() 
  "store original quickfix lists, so that later could be restored
  let s:origQF = len( s:origQF )>0? s:origQF : getqflist()
  let all = getqflist()
  if empty(all)
    call PrintErrMsg('Quickfix window is empty. Nothing could be grepped. ')
    return
  endif

  return deepcopy(all)
endfunction

function! <SID>DoFilter(pat, invert, cp) 
  exec 'redraw' 
  if empty(a:pat)
    call PrintErrMsg("Empty pattern is not allowed")
    return
  endif
  try
    for d in a:cp
      if (!a:invert)
        if ( bufname(d['bufnr']) !~ a:pat && d['text'] !~ a:pat)
          call remove(a:cp, index(a:cp,d))
        endif
      else " here do invert matching
        if (bufname(d['bufnr']) =~ a:pat || d['text'] =~ a:pat)
          call remove(a:cp, index(a:cp,d))
        endif
      endif
    endfor
    if empty(a:cp)
      call PrintErrMsg('Empty resultset, aborted.')
    else		"found entries
      call setqflist(a:cp)
      call PrintHLInfo(len(a:cp) . ' entries in Grep result.')
    endif
  catch /^Vim\%((\a\+)\)\=:E/
    call PrintErrMsg('Pattern invalid')
  endtry
endfunction


"do grep on quickfix entries
function! <SID>GrepQuickFix(invert)
  let cp = <SID>SaveQuickFix()

  call inputsave()
  echohl QFGPrompt
  let pat = input( s:msgHead . 'Pattern' . (a:invert?' (Invert-matching):':':'))
  echohl None
  call inputrestore()
  "clear the cmdline
  exec 'redraw' 
  if empty(pat)
    call PrintErrMsg("Empty pattern is not allowed")
    return
  endif

  call <SID>DoFilter( pat, a:invert, cp )

endfunction

"do grep on quickfix without prompting for pattern
function! <SID>FilterQuickFixWithPattern( pat, invert )
  let cp = <SID>SaveQuickFix()

  call <SID>DoFilter( a:pat, a:invert, cp )
endfunction


fun! <SID>RestoreQuickFix()
  if len(s:origQF) > 0
    call setqflist(s:origQF)
    call PrintHLInfo('Quickfix entries restored.')
  else
    call PrintErrMsg("Nothing can be restored")
  endif

endf


fun! PrintErrMsg(errMsg)
  echohl QFGError
  echon s:msgHead.a:errMsg
  echohl None
endf


"print Highlighted info
fun! PrintHLInfo(msg)
  echohl QFGInfo
  echon s:msgHead.a:msg
  echohl None
endf


"autocommands 
fun! <SID>FTautocmdBatch()
  execute 'hi QFGPrompt ' . g:QFG_hi_prompt
  execute 'hi QFGInfo '   . g:QFG_hi_info
  execute 'hi QFGError '  . g:QFG_hi_error
  command! -nargs=0 QFGrep     call <SID>GrepQuickFix(0)                        "invert flag =0
  command! -nargs=0 QFGrepV    call <SID>GrepQuickFix(1)                        "invert flag =1
  command! -nargs=0 QFRestore  call <SID>RestoreQuickFix()
  command! -nargs=1 QFGrepPat  call <SID>FilterQuickFixWithPattern("<args>",0)  "invert flag =0
  command! -nargs=1 QFGrepPatV call <SID>FilterQuickFixWithPattern("<args>",1)  "invert flag =1
  "mapping
  execute 'nnoremap <buffer><silent>' . g:QFG_Grep    . ' :QFGrep<cr>'
  execute 'nnoremap <buffer><silent>' . g:QFG_GrepV   . ' :QFGrepV<cr>'
  execute 'nnoremap <buffer><silent>' . g:QFG_Restore . ' :QFRestore<cr>'

endf



augroup QFG
  au!
  autocmd QuickFixCmdPre * let s:origQF = []
  autocmd QuickFixCmdPost * let s:origQF = getqflist() 
  autocmd FileType qf call <SID>FTautocmdBatch()
augroup end

command! QFGrepVersion echo "QFGrep Version: " . s:version

" vim: ts=2:tw=80:shiftwidth=2:tabstop=2:fdm=marker:expandtab:
