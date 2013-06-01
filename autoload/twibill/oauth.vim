" oauth
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5849.txt

let s:save_cpo = &cpo
set cpo&vim

function! twibill#oauth#request_token(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = twibill#sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_version"] = "1.0"
  for key in keys(params)
    let query[key] = params[key]
  endfor
  let query_string = "POST&"
  let query_string .= twibill#http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= twibill#http#encodeURI(twibill#http#encodeURI(query))
  let hmacsha1 = twibill#hmac#sha1(twibill#http#encodeURI(a:ctx.consumer_secret) . "&", query_string)
  let query["oauth_signature"] = twibill#base64#b64encodebin(hmacsha1)
  let res = twibill#http#post(a:ctx, a:url, query, {})
  let a:ctx.request_token = twibill#http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let a:ctx.request_token_secret = twibill#http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return a:ctx
endfunction

function! twibill#oauth#access_token(url, ctx, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = twibill#sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:ctx.request_token
  let query["oauth_token_secret"] = a:ctx.request_token_secret
  let query["oauth_version"] = "1.0"
  for key in keys(params)
    let query[key] = params[key]
  endfor
  let query_string = "POST&"
  let query_string .= twibill#http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= twibill#http#encodeURI(twibill#http#encodeURI(query))
  let hmacsha1 = twibill#hmac#sha1(twibill#http#encodeURI(a:ctx.consumer_secret) . "&" . twibill#http#encodeURI(a:ctx.request_token_secret), query_string)
  let query["oauth_signature"] = twibill#base64#b64encodebin(hmacsha1)
  let res = twibill#http#post(a:ctx, a:url, query, {})
  let a:ctx.access_token = twibill#http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let a:ctx.access_token_secret = twibill#http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return a:ctx
endfunction

function! twibill#oauth#get(url, ctx, ...)
  let data = call('s:create_request_param', [a:ctx, a:url, "GET"] + a:000)
  let res  = twibill#http#get(a:url, data[1], data[0])
  return res
endfunction

function! twibill#oauth#post(url, ctx, ...)
  let data = call('s:create_request_param', [a:ctx, a:url, "POST"] + a:000)
  let res  = twibill#http#post(a:ctx, a:url, data[1], data[0])
  return res
endfunction

function! twibill#oauth#stream(ctx, url, method, ...)
  let url  = a:url
  " todo {}
  let data = call('s:create_request_param', [a:ctx, url, a:method, {}] + a:000)

  let header = data[0]
  let query  = data[1]
  if a:method == 'GET'
    let getdatastr = twibill#http#encodeURI(query)
    if strlen(getdatastr)
      let url .= "?" . getdatastr
    endif
    let command = 'curl -L -s -k -i '
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(header)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(header[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . header[key] . quote
    endif
    endfor
    let command .= " ".quote.url.quote
    let file = ''
  else
    let postdatastr = twibill#http#encodeURI(query)
    let command = 'curl -L -s -k -i -X ' . a:method
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(header)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(header[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . header[key] . quote
      endif
    endfor
    let file = tempname()
    call writefile(split(postdatastr, "\n"), file, "b")
    let command .= " ".quote.url.quote
    let command = command . " --data-binary @" . quote.file.quote
    echomsg command
  endif

  let vimproc = vimproc#ptyopen(command)
  call vimproc.stdin.close()

  "if file != ''
    "call delete(file)
  "endif

  return vimproc
endfunction

function! s:create_request_param(ctx, url, method, ...)
  let params   = a:0 > 0 ? a:000[0] : {}
  let getdata  = a:0 > 1 ? a:000[1] : {}
  let headdata = a:0 > 2 ? a:000[2] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = twibill#sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"]     = a:ctx.consumer_key
  let query["oauth_nonce"]            = nonce
  let query["oauth_request_method"]   = a:method
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"]        = time_stamp
  let query["oauth_token"]            = a:ctx.access_token
  let query["oauth_version"]          = "1.0"
  if type(params) == 4
    for key in keys(params)
      let query[key] = params[key]
    endfor
  endif
  if type(getdata) == 4
    for key in keys(getdata)
      let query[key] = getdata[key]
    endfor
  endif
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= twibill#http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= twibill#http#encodeURI(twibill#http#encodeURI(query))
  let hmacsha1 = twibill#hmac#sha1(twibill#http#encodeURI(a:ctx.consumer_secret) . "&" . twibill#http#encodeURI(a:ctx.access_token_secret), query_string)

  " bug ?
  if hmacsha1 == ''
    echomsg "hmacsha1 is empty. retried"
    let hmacsha1 = twibill#hmac#sha1(twibill#http#encodeURI(a:ctx.consumer_secret) . "&" . twibill#http#encodeURI(a:ctx.access_token_secret), query_string)
  endif

  let query["oauth_signature"] = twibill#base64#b64encodebin(hmacsha1)
  if type(getdata) == 4
    for key in keys(getdata)
      call remove(query, key)
    endfor
  endif
  let auth = 'OAuth '
  for key in sort(keys(query))
    let auth .= key . '="' . twibill#http#encodeURI(query[key]) . '", '
  endfor
  let auth = auth[:-3]
  let headdata["Authorization"] = auth

  return [headdata, getdata]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
