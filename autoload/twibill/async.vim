let s:V   = vital#twibill#new()
let s:Job = s:V.import('System.Job')

"
" 非同期でコマンドを実行
"
function! twibill#async#system(cmd, handler, param)
  if get(g:, 'twibill_use_job', 0)
    "TODO: Use partial and closure instead of unsafe_closure when neovim supported it
    let s:handler = a:handler
    let s:param   = a:param
    function! s:unsafe_closure(_, __, ___) abort
      call s:receive_async_result(s:handler, s:param)
      unlet s:handler s:param
    endfunction
    call s:Job.start(a:cmd, {'on_exit': function('s:unsafe_closure')})
  else
    let cmd = a:cmd
    let vimproc = vimproc#pgroup_open(cmd)
    call vimproc.stdin.close()

      " 1つのインスタンスを使いまわしているので2回呼ばれるとアウト
    let s:vimproc = vimproc
    let s:result = ""

    let param = twibill#json#encode(a:param)

    augroup vimproc-async-receive-test
      execute "autocmd! CursorHold,CursorHoldI * call"
            \ "s:receive_async_result(" . string(a:handler) . "," . param . ")"
    augroup END
  endif
endfunction
"
" コマンドの終了チェック関数
"
function! s:receive_async_result(handler, param)
  if !has_key(s:, "vimproc")
    return
  endif

  let vimproc = s:vimproc

  try
    if !vimproc.stdout.eof
      let s:result .= vimproc.stdout.read(1000, 0)
    endif

    if !vimproc.stderr.eof
      let s:result .= vimproc.stderr.read(1000, 0)
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      return 0
    endif
  catch
    echom v:throwpoint
  endtry

  call function(a:handler)(s:result, a:param)

  augroup vimproc-async-receive-test
    autocmd!
  augroup END

  call vimproc.stdout.close()
  call vimproc.stderr.close()
  call vimproc.waitpid()
  unlet s:vimproc
  unlet s:result
endfunction

