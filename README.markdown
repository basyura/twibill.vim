
twibill.vim
===========

twitter api wapper like a Rubytter.rb

dependencies
------------

  - webapi-vim (https://github.com/mattn/webapi-vim)
  - open-browser.vim (https://github.com/tyru/open-browser.vim)

how to use
----------

### oauth - get access token

    let ctx = twibill#access_token()
    "
    " open your browser to authenticate , and inpupt pin
    "
    echo ctx.access_token        "=> your access token
    echo ctx.access_token_secret "=> your access token secret

### get twibill instance

    let twibill = twibill#new({
      \ 'access_token' : your access token, 
      \ 'access_token_secret' : your access token secret })

### get statuses

    let xml = twibill.list_statuses('basyura', 'vim')
    for tweet in xml.childNodes('status')
      echo tweet.childNode('user').childNode('screen_name').value()
             \  . ' : ' . tweet.childNode('text').value()
    endfor

### update status

    call twibill.update('hello vim world')

supported api ?
---------------

    update_status           /statuses/update                post
    remove_status           /statuses/destroy/%s            delete
    public_timeline         /statuses/public_timeline
    home_timeline           /statuses/home_timeline
    friends_timeline        /statuses/friends_timeline
    replies                 /statuses/replies
    mentions                /statuses/mentions
    user_timeline           /statuses/user_timeline/%s
    show                    /statuses/show/%s
    friends                 /statuses/friends/%s
    followers               /statuses/followers/%s
    retweet                 /statuses/retweet/%s            post
    retweets                /statuses/retweets/%s
    retweeted_by_me         /statuses/retweeted_by_me
    retweeted_to_me         /statuses/retweeted_to_me
    retweets_of_me          /statuses/retweets_of_me
    user                    /users/show/%s
    direct_messages         /direct_messages
    sent_direct_messages    /direct_messages/sent
    send_direct_message     /direct_messages/new            post
    remove_direct_message   /direct_messages/destroy/%s     delete
    follow                  /friendships/create/%s          post
    leave                   /friendships/destroy/%s         delete
    friendship_exists       /friendships/exists
    followers_ids           /followers/ids/%s
    friends_ids             /friends/ids/%s
    favorites               /favorites/%s
    favorite                /favorites/create/%s            post
    remove_favorite         /favorites/destroy/%s           delete
    verify_credentials      /account/verify_credentials     get
    end_session             /account/end_session            post
    update_delivery_device  /account/update_delivery_device post
    update_profile_colors   /account/update_profile_colors  post
    limit_status            /account/rate_limit_status
    update_profile          /account/update_profile         post
    enable_notification     /notifications/follow/%s        post
    disable_notification    /notifications/leave/%s         post
    block                   /blocks/create/%s               post
    unblock                 /blocks/destroy/%s              delete
    block_exists            /blocks/exists/%s               get
    blocking                /blocks/blocking                get
    blocking_ids            /blocks/blocking/ids            get
    saved_searches          /saved_searches                 get
    saved_search            /saved_searches/show/%s         get
    create_saved_search     /saved_searches/create          post
    remove_saved_search     /saved_searches/destroy/%s      delete
    create_list             /%s/lists                       post
    update_list             /%s/lists/%s                    put
    delete_list             /%s/lists/%s                    delete
    list                    /%s/lists/%s
    lists                   /%s/lists
    lists_followers         /%s/lists/memberships
    list_statuses           /%s/lists/%s/statuses
    list_members            /%s/%s/members
    add_member_to_list      /%s/%s/members                  post
    remove_member_from_list /%s/%s/members                  delete
    list_following          /%s/%s/subscribers
    follow_list             /%s/%s/subscribers              post
    remove_list             /%s/%s/subscribers              delete

