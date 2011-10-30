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

for line in s:apis
  let info = split(line, ' ')
  function! s:twibill[info[0]](...)
    let url = s:api_url . info[1] . '.xml'
    " fixme!
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
    let res = oauth#get(url, ctx, param)
    let xml = xml#parse(res.content)
    return xml
  endfunction
endfor

function! twibill#access_token()

  let ctx = oauth#request_token(
        \ s:request_token_url, 
        \ {'consumer_key' : s:consumer_key , 'consumer_secret' : s:consumer_secret})

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
