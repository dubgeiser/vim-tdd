" Description: TDD plugin
"           Runs a file with tests and shows a green or red bar depending on
"           the fact that the test(s) passed or failed.
"
" Author: P. Juchtmans
" License: http://sam.zoy.org/wtfpl/COPYING
"          No warranties, expressed or implied.
"
" Usage: In the ftplugin directory of your vim configuration, add an
"       errorformat for the output of your test runner that you use.  You can
"       add an errorformat like this (note the + sign):
"
"           set errorformat+=%m\ at\ \[%f\ line\ %l]
"       
"       Then define the test runner in g:Tdd_makeprg, which is actually a
"       makeprg definition that will be used for running the tests.
"
"           let g:Tdd_makeprg='php ~/Projects/myproject/alltests.php'
"
"       or (an ok default imo), which will run the file in the current buffer:
"
"           let g:Tdd_makeprg='php %'
"
"       tdd.vim will remember the current makeprg setting and will restore
"       that after the test is run.
"
"       To run the test:
"
"           :call Tdd_RunTest()
"
"       This will then save your current makeprg setting, set g:Tdd_makeprg as
"       the makeprg, execute Vim's make, match the output against the list of
"       defined errorformat and if it finds anything in the output that
"       matches, it shows a red bar, otherwise a green one.  After that the
"       original makeprg setting is restored.
"
"       Note that it's best to define a key map that runs the current file in
"       the current buffer:
"
"           :nmap <Leader>t :call Tdd_RunTest()
"
"
" Known Limitations:
"   - Only tested in Gvim and MacVim with:
"       - PHP and SimpleTest's autorun on Mac & Linux
"       - Python unittest.main() on Mac & Linux
"   - The test file must be runnable, if it is not, a green bar will
"     be displayed.
"   - When a test run is a success, the last line of the test run
"     output is re-echoed in the green bar, depending on the output
"     format of your test runner, this might not be the result you
"     were hoping for.
"   - Alternating between buffers with code in different languages needs
"     manually re-setting the filetype, ex: edit php file switch to buffer
"     with python code, go back to the php file, :call Tdd_RunTest()
"     and a red bar is shown with 'Syntax Error' message.  :set ft=php before
"     running again solves this.
"   - Yes, I am aware of the tragic irony that this plugin does not
"     have tests.
"
" To Do:
"   - Better error handling for things like checking if 'Tdd_makeprg' is
"     defined.  Maybe we need to supply some defaults?
"   - UI screwed when used in vim (G-/MacVim are ok though)?
"   - Investigate :help write-compiler-plugin


if exists('tdd_loaded') || &cp || version < 700
    finish
endif
let tdd_loaded = 1


" Run test, ie. call make with the makeprg set to g:Tdd_makeprg
fun! Tdd_RunTest()
    call s:runTest()
    let result = s:processTestOuput()
    call s:showBar(result.type, result.message)
endf

fun! s:runTest()
    let save_makeprg=&makeprg
    exec "set makeprg=" . escape(g:Tdd_makeprg, ' ')
    silent exec "make"
    silent !echo
    exec "set makeprg=" . escape(save_makeprg, ' ')
endf

" Process the output of the test run.
" Return following Dictionary:
"   {
"       'type' : string Either 'Success' or 'Failure',
"       'message' : Either the first encountered error message 'type' will be
"                   'Failure', or the last line of the test run output, 'type'
"                   will be 'Success'.
"   }
fun! s:processTestOuput()
    let result = {}
    for each in getqflist()
        if each.valid == 1
            return {'type' : 'Failure', 'message' : each.text}
        endif
    endfor
    return {'type' : 'Success', 'message' : each.text}
endf

" 'success_or_failure' string Either 'Success' or 'Failure'
fun! s:showBar(success_or_failure, message)
    hi Tdd_Success ctermfg=white ctermbg=green guifg=white guibg=#256414
    hi Tdd_Failure ctermfg=white ctermbg=red guifg=white guibg=#dd2212
    exec "echohl Tdd_" . a:success_or_failure
    echon a:message
    " -1 because we don't want a blank line
    echon repeat(" ", &columns - len(a:message) - 1)
    echohl
endf

