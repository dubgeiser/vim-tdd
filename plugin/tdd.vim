" Description: TDD plugin
"           Runs a file with tests and shows a green or red bar depending on
"           the fact that the test(s) passed or failed.
" Author: <dubgeiser@gmail.com>
" License: http://sam.zoy.org/wtfpl/COPYING
"          No warranties, expressed or implied.
"
" TODO rewrite the rest of this doc comment
"
" Usage: In the ftplugin directory of your vim configuration, add an
"       errorformat for the output of your test runner that you use.  You can
"       add an errorformat like this (note the + sign):
"
"           set errorformat+=%m\ at\ \[%f\ line\ %l]
"
"       Then define the test runner in g:Tdd_makeprg, which is actually a
"       makeprg definition that will be used for running the tests.
"       For php, this will probably be 'phpunit' or 'php' when using
"       SimpleTest.
"
"           let g:Tdd_makeprg='phpunit'
"
"       tdd.vim will remember the current makeprg setting and will restore
"       that after the test is run.
"
"       To run the test:
"
"           :RunTest
"
"       This will then save your current makeprg setting, set g:Tdd_makeprg as
"       the makeprg, execute Vim's make, match the output against the list of
"       defined errorformat and if it finds anything in the output that
"       matches, it shows a red bar, otherwise a green one.  After that the
"       original makeprg setting is restored.
"
"       'RunTest' runs the current test file, if no current test file was
"       set yet, the file in the active buffer is set as the current test.
"
"       To set a new current test load the test file in the active buffer and
"       execute:
"
"           :SetTest
"
"       Alternatively, manually set the variable 'g:tdd_current_test'
"
"       For a faster TDD cycle, it's best to map some quick keys to the Tdd*
"       commands, ex:
"
"           :nmap <Leader>t :RunTest<cr>
"           :nmap <Leader>c :SetTest<cr>
"
"       By default (if necessary and possible), tdd.vim maps <leader>t to
"       ':RunTest'.  ':SetTest' is not mapped.
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
"     with python code, go back to the php file, :call RunTest()
"     and a red bar is shown with 'Syntax Error' message.  :set ft=php before
"     running again solves this.
"   - Yes, I am aware of the tragic irony that this plugin does not
"     have tests.
"
" TODO:
"   - Better error handling for things like checking if 'Tdd_makeprg' is
"     defined.  Maybe we need to supply some defaults?
"   - UI screwed when used in vim (G-/MacVim are ok though)?
"   - Investigate :help write-compiler-plugin


if exists('g:tdd_loaded') || &cp || version < 700
    finish
endif
let g:tdd_loaded = 1


" Run the current test, if it is not (yet) defined, try to find it.
" Behaviour:
" if the current buffer is a test file:
"   override current_test with it
" if no current_test:
"   try to determine/guess current_test.
" if no current_test:
"   Can't run any tests; warn user about it.
" else:
"   run current_test
function! RunTest() abort
    let save_makeprg=&makeprg
    if !exists('g:tdd_current_test')
        call SetTest()
    endif
    exec "set makeprg=" . escape(g:Tdd_makeprg . ' ' . g:tdd_current_test, ' ')
    silent exec "make"
    silent !echo
    exec "set makeprg=" . escape(save_makeprg, ' ')
    let result = s:ProcessTestOutput()
    call s:ShowTestResult(result.type, result.message)
endfunction

" Set the file in the active buffer as the current test to run.
function! SetTest() abort
    let g:tdd_current_test = bufname("%")
endfunction

" Process the output of the test run.
" Return following Dictionary:
"   {
"       'type' : string Either 'Success' or 'Failure',
"       'message' : Either the first encountered error message 'type' will be
"                   'Failure', or the last line of the test run output, 'type'
"                   will be 'Success'.
"   }
function! s:ProcessTestOutput() abort
    let result = {}
    for each in getqflist()
        if each.valid == 1
            return {'type' : 'Failure', 'message' : each.text}
        endif
    endfor
    return {'type' : 'Success', 'message' : each.text}
endfunction

" 'success_or_failure' string Either 'Success' or 'Failure'
function! s:ShowTestResult(success_or_failure, message) abort
    hi Tdd_Success ctermfg=white ctermbg=green guifg=white guibg=#256414
    hi Tdd_Failure ctermfg=white ctermbg=red guifg=white guibg=#dd2212
    exec "echohl Tdd_" . a:success_or_failure
    echon a:message
    " -1 because we don't want a blank line
    echon repeat(" ", &columns - len(a:message) - 1)
    echohl
endfunction


command RunTest call RunTest()
command SetTest call SetTest()

if !hasmapto('RunTest') && mapcheck('<Leader>t', 'n') == ""
    nnoremap <Leader>t :RunTest<cr>
endif
