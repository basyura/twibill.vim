
function! twibill#util#divide_url(url)
  let url = a:url
  if stridx(url, '.json?') == -1
    return []
  endif

  let url   = a:url
  let param = {}

  let url_param = split(url, '.json?')
  let url = url_param[0] . '.json'
  for kv in split(url_param[1], '&')
    let pair = split(kv, '=')
    let param[pair[0]] = pair[1]
  endfor
  return [url, param]
endfunction
