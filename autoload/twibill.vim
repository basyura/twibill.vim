let s:save_cpo = &cpo
set cpo&vim

let s:request_token_url = 'https://twitter.com/oauth/request_token'
let s:access_token_url  = 'https://twitter.com/oauth/access_token'
let s:authorize_url     = 'https://twitter.com/oauth/authorize'
let s:api_url           = 'https://api.twitter.com/1'

let s:consumer_key    = 'udAowgINoQh37TJH0pjmuQ'
let s:consumer_secret = 'SToI3ECedpxN9QG4R8iaLG4xsAJbzrOWuDnl7DF4'

let s:apis = [
      \ 'update_status           /statuses/update                post',
      \ 'remove_status           /statuses/destroy/%s            delete',
      \ 'public_timeline         /statuses/public_timeline',
      \ 'home_timeline           /statuses/home_timeline',
      \ 'friends_timeline        /statuses/friends_timeline',
      \ 'replies                 /statuses/replies',
      \ 'mentions                /statuses/mentions',
      \ 'user_timeline           /statuses/user_timeline/%s',
      \ 'show                    /statuses/show/%s',
      \ 'friends                 /statuses/friends/%s',
      \ 'followers               /statuses/followers/%s',
      \ 'retweet                 /statuses/retweet/%s            post',
      \ 'retweets                /statuses/retweets/%s',
      \ 'retweeted_by_me         /statuses/retweeted_by_me',
      \ 'retweeted_to_me         /statuses/retweeted_to_me',
      \ 'retweets_of_me          /statuses/retweets_of_me',
      \ 'user                    /users/show/%s',
      \ 'direct_messages         /direct_messages',
      \ 'sent_direct_messages    /direct_messages/sent',
      \ 'send_direct_message     /direct_messages/new            post',
      \ 'remove_direct_message   /direct_messages/destroy/%s     delete',
      \ 'follow                  /friendships/create/%s          post',
      \ 'leave                   /friendships/destroy/%s         delete',
      \ 'friendship_exists       /friendships/exists',
      \ 'followers_ids           /followers/ids/%s',
      \ 'friends_ids             /friends/ids/%s',
      \ 'favorites               /favorites/%s',
      \ 'favorite                /favorites/create/%s            post',
      \ 'remove_favorite         /favorites/destroy/%s           delete',
      \ 'verify_credentials      /account/verify_credentials     get',
      \ 'end_session             /account/end_session            post',
      \ 'update_delivery_device  /account/update_delivery_device post',
      \ 'update_profile_colors   /account/update_profile_colors  post',
      \ 'limit_status            /account/rate_limit_status',
      \ 'update_profile          /account/update_profile         post',
      \ 'enable_notification     /notifications/follow/%s        post',
      \ 'disable_notification    /notifications/leave/%s         post',
      \ 'block                   /blocks/create/%s               post',
      \ 'unblock                 /blocks/destroy/%s              delete',
      \ 'block_exists            /blocks/exists/%s               get',
      \ 'blocking                /blocks/blocking                get',
      \ 'blocking_ids            /blocks/blocking/ids            get',
      \ 'saved_searches          /saved_searches                 get',
      \ 'saved_search            /saved_searches/show/%s         get',
      \ 'create_saved_search     /saved_searches/create          post',
      \ 'remove_saved_search     /saved_searches/destroy/%s      delete',
      \ 'create_list             /%s/lists                       post',
      \ 'update_list             /%s/lists/%s                    put',
      \ 'delete_list             /%s/lists/%s                    delete',
      \ 'list                    /%s/lists/%s',
      \ 'lists                   /%s/lists',
      \ 'lists_followers         /%s/lists/memberships',
      \ 'list_statuses           /%s/lists/%s/statuses',
      \ 'list_members            /%s/%s/members',
      \ 'add_member_to_list      /%s/%s/members                  post',
      \ 'remove_member_from_list /%s/%s/members                  delete',
      \ 'list_following          /%s/%s/subscribers',
      \ 'follow_list             /%s/%s/subscribers              post',
      \ 'remove_list             /%s/%s/subscribers              delete',
      \ ]

let s:twibill = {}

function! s:twibill.get(url, ctx, param)
  let res = oauth#get(a:url, a:ctx, {}, a:param)
  return json#decode(res.content)
endfunction

function! s:twibill.post(url, ctx, param)
  let res = oauth#post(a:url, a:ctx, {}, a:param)
  return json#decode(res.content)
endfunction

function! s:twibill.update(text)
  return self.update_status({"status" : a:text})
endfunction

function! s:setup()
  for line in s:apis
    let info = split(line, '\s\+')

    let api_config = {
          \ 'method'      : info[0], 
          \ 'url'         : info[1], 
          \ 'http_method' : len(info) == 2 ? 'get' : info[2]
          \ }

    let s:twibill[api_config.method . '_config'] = api_config

    function! s:twibill[api_config.method](...)

      " to get method name by func name ...
      let func_name = split(expand('<sfile>'))[-1]
      if func_name =~ '\.\.'
        let func_name = split(func_name, '\.\.')[-1]
      endif
      let func_name = "function('" . func_name . "')"
      let api = get(self, func_name, "")
      if api == ""
        for key in keys(self)
          if string(self[key]) == func_name
            let api = key
            let self[func_name] = api
            break
          endif
        endfor
      endif

      let api_config = self[api . '_config']
      let url = s:api_url . api_config.url . '.json'

      let num = len(split(url, '%s', 1)) - 1
      for v in range(num) 
        let url = substitute(url, "%s", a:000[v] , "")
      endfor

      let param = (len(a:000) != 0 && type(a:000[-1]) == 4) ? a:000[-1] : {}
      let ctx = {
            \ 'consumer_key'        : self.config.consumer_key ,
            \ 'consumer_secret'     : self.config.consumer_secret ,
            \ 'access_token'        : self.config.access_token ,
            \ 'access_token_secret' : self.config.access_token_secret
            \ }
      if api_config.http_method == 'get'
        return self.get(url, ctx, param)
      else
        return self.post(url, ctx, param)
      endif
    endfunction
  endfor
endfunction

call s:setup()

"
" config : {
"   'consumer_key'    = 'your consumer_key'
"   'consumer_secret' = 'your consumer_secret'
" }
"
function! twibill#access_token(...)

  let config = a:0 ? a:1 : {}
  let config.consumer_key    = get(config, 'consumer_key'   , s:consumer_key)
  let config.consumer_secret = get(config, 'consumer_secret', s:consumer_secret)

  let ctx = oauth#request_token(s:request_token_url, config)

  execute "OpenBrowser " . s:authorize_url . "?oauth_token=" . ctx.request_token
  
	echo "now launched your browser to authenticate"

  let pin = input("Enter Twitter OAuth PIN: ")

  return oauth#access_token(s:access_token_url, ctx , {'oauth_verifier' : pin})
endfunction
"
" config : {
" 'accsess_token'        : 'your access token' ,
" 'accsess_token_secret' : 'your access token secret' ,
" }
"
"
function! twibill#new(config)
  let twibill = copy(s:twibill)

  let config = copy(a:config)
  let config.consumer_key    = get(a:config, 'consumer_key'   , s:consumer_key)
  let config.consumer_secret = get(a:config, 'consumer_secret', s:consumer_secret)
  let twibill.config = config

  return twibill
endfunction

let &cpo = s:save_cpo
