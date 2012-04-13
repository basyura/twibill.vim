" This is a port of rfc2104 hmac function.
" http://www.ietf.org/rfc/rfc2104.txt
" Last Change:  2010-02-13
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License: This file is placed in the public domain.

" @param mixed key List or String
" @param mixed text List or String
" @param Funcref hash   function digest_hex(key:List, text:List):String
" @param Number blocksize
function twibill#hmac#hmac(key, text, hash, blocksize)
  let key = (type(a:key) == type("")) ? s:str2bytes(a:key) : a:key
  let text = (type(a:text) == type("")) ? s:str2bytes(a:text) : a:text
  return s:Hmac(key, text, a:hash, a:blocksize)
endfunction

function twibill#hmac#md5(key, text)
  return twibill#hmac#hmac(a:key, a:text, 'md5#md5bin', 64)
endfunction

function twibill#hmac#sha1(key, txt)

  if exists('s:sha1_method')
    return call(s:sha1_method, [a:key, a:txt])
  endif

  let ret = s:sha1_ruby(a:key, a:txt)
  if ret != ''
    let s:sha1_method = 's:sha1_ruby'
    return ret
  endif

  let ret = s:sha1_python(a:key, a:txt)
  if ret != ''
    let s:sha1_method = 's:sha1_python'
    return ret
  endif

  let ret = s:sha1_perl(a:key, a:txt)
  if ret != ''
    let s:sha1_method = 's:sha1_perl'
    return ret
  endif

  let s:sha1_method = 's:sha1_vim'
  return s:sha1_vim(a:key, a:txt)
endfunction

function! s:sha1_ruby(key, txt)
  if !has('ruby')
    return ''
  endif
  try
ruby << EOF
  require 'openssl'
  key = VIM.evaluate("a:key")
  txt = VIM.evaluate("a:txt")
  digest = OpenSSL::Digest::Digest.new('sha1')
  result = OpenSSL::HMAC.hexdigest(digest, key, txt)
  VIM.command("let ret = '#{result}'")
EOF
    return ret
  catch
    return ''
  endtry
endfunction

function s:sha1_python(key, txt)
  if !has('python')
    return ''
  endif
  try
  python << EOF
import vim
import hashlib
import hmac
key = vim.eval("a:key")
txt = vim.eval('a:txt')
hex = hmac.new(key, txt, hashlib.sha1).hexdigest()
vim.command('let ret = "{0}"'.format(hex))
EOF
    return ret
  catch
    return ''
  endtry
endfunction

function! s:sha1_perl(key, txt)
  if !has('perl')
    return ''
  endif
  try
perl << EOF
  # http://adiary.blog.abk.nu/0274
  # license : PDS
  require Digest::SHA1;
	my $key = VIM::Eval('a:key');
  my $msg = VIM::Eval('a:txt');
  my $sha1 = Digest::SHA1->new;
	if (length($key) > 64) {
		$key = $sha1->add($key)->digest;
		$sha1->reset;
	}
	my $k_opad = $key ^ ("\x5c" x 64);
	my $k_ipad = $key ^ ("\x36" x 64);
	$sha1->add($k_ipad);
	$sha1->add($msg);
	my $hk_ipad = $sha1->digest;
	$sha1->reset;
	$sha1->add($k_opad, $hk_ipad);

	my $b64d = $sha1->hexdigest;
  VIM::DoCommand('let ret = "' . $b64d . '"');
EOF
	  return ret
  catch
    return ''
  endtry

endfunction

function! s:sha1_vim(key, txt)
    return twibill#hmac#hmac(a:key, a:txt, 'twibill#sha1#sha1bin', 64)
endfunction

" @param List key
" @param List text
" @param Funcref hash
" @param Number blocksize
function! s:Hmac(key, text, hash, blocksize)
  let key = a:key
  if len(key) > a:blocksize
    let key = s:hex2bytes(call(a:hash, [key]))
  endif
  let k_ipad = repeat([0], a:blocksize)
  let k_opad = repeat([0], a:blocksize)
  for i in range(a:blocksize)
    let k_ipad[i] = s:bitwise_xor(get(key, i, 0), 0x36)
    let k_opad[i] = s:bitwise_xor(get(key, i, 0), 0x5c)
  endfor
  let hash1 = s:hex2bytes(call(a:hash, [k_ipad + a:text]))
  let hmac = call(a:hash, [k_opad + hash1])
  return hmac
endfunction

function! s:str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:hex2bytes(str)
  return map(split(a:str, '..\zs'), 'str2nr(v:val, 16)')
endfunction

let s:xor = [
      \ [0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF],
      \ [0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6, 0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE],
      \ [0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5, 0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD],
      \ [0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4, 0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC],
      \ [0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3, 0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB],
      \ [0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2, 0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA],
      \ [0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1, 0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9],
      \ [0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0, 0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8],
      \ [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
      \ [0x9, 0x8, 0xB, 0xA, 0xD, 0xC, 0xF, 0xE, 0x1, 0x0, 0x3, 0x2, 0x5, 0x4, 0x7, 0x6],
      \ [0xA, 0xB, 0x8, 0x9, 0xE, 0xF, 0xC, 0xD, 0x2, 0x3, 0x0, 0x1, 0x6, 0x7, 0x4, 0x5],
      \ [0xB, 0xA, 0x9, 0x8, 0xF, 0xE, 0xD, 0xC, 0x3, 0x2, 0x1, 0x0, 0x7, 0x6, 0x5, 0x4],
      \ [0xC, 0xD, 0xE, 0xF, 0x8, 0x9, 0xA, 0xB, 0x4, 0x5, 0x6, 0x7, 0x0, 0x1, 0x2, 0x3],
      \ [0xD, 0xC, 0xF, 0xE, 0x9, 0x8, 0xB, 0xA, 0x5, 0x4, 0x7, 0x6, 0x1, 0x0, 0x3, 0x2],
      \ [0xE, 0xF, 0xC, 0xD, 0xA, 0xB, 0x8, 0x9, 0x6, 0x7, 0x4, 0x5, 0x2, 0x3, 0x0, 0x1],
      \ [0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1, 0x0]
      \ ]

function! s:bitwise_xor(a, b)
  let a = a:a < 0 ? a:a - 0x80000000 : a:a
  let b = a:b < 0 ? a:b - 0x80000000 : a:b
  let r = 0
  let n = 1
  while a || b
    let r += s:xor[a % 0x10][b % 0x10] * n
    let a = a / 0x10
    let b = b / 0x10
    let n = n * 0x10
  endwhile
  if (a:a < 0) != (a:b < 0)
    let r += 0x80000000
  endif
  return r
endfunction

