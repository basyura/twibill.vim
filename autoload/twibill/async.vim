"
" 非同期でコマンドを実行
"
function! twibill#async#system(cmd, handler)
  let cmd = a:cmd
  let vimproc = vimproc#pgroup_open(cmd)
  call vimproc.stdin.close()

    " 1つのインスタンスを使いまわしているので2回呼ばれるとアウト
  let s:vimproc = vimproc
  let s:result = ""

  augroup vimproc-async-receive-test
    execute "autocmd! CursorHold,CursorHoldI * call"
          \ "s:receive_vimproc_result(".string(a:handler).")"
  augroup END
endfunction
"
" コマンドの終了チェック関数
"
function! s:receive_vimproc_result(handler)
  if !has_key(s:, "vimproc")
    return
  endif

  let vimproc = s:vimproc

  try
    if !vimproc.stdout.eof
      let s:result .= vimproc.stdout.read()
    endif

    if !vimproc.stderr.eof
      let s:result .= vimproc.stderr.read()
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      return 0
    endif
  catch
    echom v:throwpoint
  endtry

  call function(a:handler)(s:result)

  augroup vimproc-async-receive-test
    autocmd!
  augroup END

  call vimproc.stdout.close()
  call vimproc.stderr.close()
  call vimproc.waitpid()
  unlet s:vimproc
  unlet s:result
endfunction

