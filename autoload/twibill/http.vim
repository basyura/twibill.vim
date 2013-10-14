" http
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:

let s:save_cpo = &cpo
set cpo&vim


function! twibill#http#get(url, ...)
  let getdata = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
  let url = a:url
  let getdatastr = twibill#http#encodeURI(getdata)
  if strlen(getdatastr)
    let url .= "?" . getdatastr
  endif
  let command = 'curl -L -s -k -i '
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(headdata)
    if has('win32')
      let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
    else
      let command .= " -H " . quote . key . ": " . headdata[key] . quote
	endif
  endfor
  let command .= " ".quote.url.quote
  "echomsg command
  let res = system(command)
  if res == ''
    return {
    \ 'header'  : '',
    \ 'content' : "{'error' : 'http connection error'}"
    \}
  endif
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
  \ "header" : split(res[0:pos], '\r\?\n'),
  \ "content" : content
  \}
endfunction


function! twibill#http#stream(url, ...)
  let getdata  = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
  let url = a:url
  let getdatastr = twibill#http#encodeURI(getdata)
  if strlen(getdatastr)
    let url .= "?" . getdatastr
  endif
  let command = 'curl -L -s -k -i '
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(headdata)
    if has('win32')
      let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
    else
      let command .= " -H " . quote . key . ": " . headdata[key] . quote
	endif
  endfor
  let command .= " ".quote.url.quote
  return vimproc#plineopen2(command)
endfunction

function! twibill#http#post(ctx, url, query, headdata)
  let url      = a:url
  let postdata = a:query
  let headdata = a:headdata
  let method   = "POST"
  if type(postdata) == 4
    let postdatastr = twibill#http#encodeURI(postdata)
  else
    let postdatastr = postdata
  endif
  let command = 'curl -L -s -k -i -X '.method
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(headdata)
    if has('win32')
      let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
    else
      let command .= " -H " . quote . key . ": " . headdata[key] . quote
	  endif
  endfor
  let command .= " ".quote.url.quote
  let file = tempname()
  call writefile(split(postdatastr, "\n"), file, "b")
  " async post
  if get(a:ctx, 'isAsync', 0)
    let res = twibill#async#system(
          \ command . " --data-binary @" . substitute(quote.file.quote, '\\', '/', "g"),
          \ s:local("async_post_finish"), {'file' : file})
    return { "header"  : "", "content" : "{'isAsync' : 1}" }
  endif
  " sync post
  let res = system(command . " --data-binary @" . quote.file.quote) | call delete(file)
  if get(g:, 'twibill_debug', 0)
    echo a:query
    echomsg command
    echomsg res
    let ret = input("enter to continue")
  endif
  return s:parse_response(res)
endfunction
"
"
"
function! twibill#http#decodeURI(str)
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=nr2char("0x".submatch(1))', 'g')
  return ret
endfunction

function! twibill#http#escape(str)
  return substitute(a:str, '[^a-zA-Z0-9_.~/-]', '\=s:urlencode_char(submatch(0))', 'g')
endfunction

function! twibill#http#encodeURI(items)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . twibill#http#encodeURI(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:urlencode_char(submatch(0))', 'g')
  endif
  return ret
endfunction

function! twibill#http#encodeURIComponent(items)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . twibill#http#encodeURIComponent(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let items = iconv(a:items, &enc, "utf-8")
    let len = strlen(items)
    let i = 0
    while i < len
      let ch = items[i]
      if ch =~# '[0-9A-Za-z-._~!''()*]'
        let ret .= ch
      elseif ch == ' '
        let ret .= '+'
      else
        let ret .= '%' . substitute('0' . s:nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction
"
"
"
function! s:parse_response(res)
  let res = a:res
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established' 
        \ || res =~ '^HTTP/1.\d 100 Continue'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
    \ "header" : split(res[0:pos], '\r\?\n'),
    \ "content" : content
    \}
endfunction
"
" 非同期コマンド終了時に呼ばれる関数
"
function! s:async_post_finish(result, param)
  let res     = s:parse_response(a:result)
  let content = twibill#json#decode(res.content)
  call delete(a:param.file)
  if has_key(content, 'error')
    redraw | echohl ErrorMsg | echo 'tweetvim - ' . content.error | echohl None
    return 0
  else
    echo 'tweetvim - async post ok'
  endif
  return 1
endfunction
"
" 外部の s:関数を使用する場合に必要
"
function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
"
"
"
function! s:local(funcname)
  return "<SNR>".s:SID()."_".a:funcname
endfunction
"
"
"
function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  elseif a:nr < 0x10000
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  elseif a:nr < 0x200000
    return nr2char(a:nr/262144%16+240).nr2char(a:nr/4096/16+128).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  elseif a:nr < 0x4000000
    return nr2char(a:nr/16777216%16+248).nr2char(a:nr/262144%16+128).nr2char(a:nr/4096/16+128).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/1073741824%16+252).nr2char(a:nr/16777216%16+128).nr2char(a:nr/262144%16+128).nr2char(a:nr/4096/16+128).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:nr2hex(nr)
  let n = a:nr
  let r = ""
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

function! s:urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
