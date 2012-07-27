jQuery ->

  _sg = simpleGiveaways

  giveaway_hash = _sg.giveaway_hash.table
  giveaway_object = giveaway_hash.giveaway.table
  paths = _sg.paths

  $new_session = null
  $entry_id = null
  $request_count = null
  $wall_post_count = null
  $just_liked = false
  $referrer_id = "#{giveaway_hash.referrer_id}" or ""
  $modal = $("#giveaway_modal")
  $loader = $modal.find(".loader")

  $("#giveaway_image").click ->
    Giveaway.modal.hide()

  fb_init_options =
    status: true
    cookie: true
    xfbml: true
    channelUrl: 'http://simplegiveaways.com/channel.html'

  $(document).fb _sg.config.fb_app_id, fb_init_options

  $(document).on 'fb:initialized', ->

    FB.getLoginStatus (response) ->

      FB.Canvas.setSize height: "#{giveaway_hash.tab_height}"

      FB.Event.subscribe 'edge.create', (href, widget) ->
        $just_liked = true
        console.log($just_liked)
        console.log(href)
        console.log(widget)
        Giveaway.step.one.hide()
        Giveaway.step.two.show()

        Giveaway.onLike()

      $("#enter_giveaway a").click (e) ->
        console.log(Giveaway.eligible)
        if Giveaway.eligible or $just_liked
          console.log(Giveaway.eligible)
          console.log($just_liked)
          Giveaway.entry.eligible()
        else
          Giveaway.modal.show()
        e.preventDefault()

      Giveaway.step.two.find("a").live "click", (e) ->
        e.preventDefault()
        Giveaway.entry.statusCheck()

    console.log(Giveaway.eligible)

  Giveaway =

    modal: $modal

    step:
      one: $modal.find(".step.one")
      two: $modal.find(".step.two")
      three: $modal.find(".step.three")

    loader: $loader

    eligible: "#{giveaway_hash.has_liked}"

    onLike: ->
      $.ajax
        type: "POST"
        url: "#{paths.likes}"
        dataType: "json"
        data: "like[giveaway_id]=#{giveaway_object.id}"
        success: (data, textStatus, jqXHR) ->
          console.log "This like brought to you by Filter Mania 2.0!!!"

    entry:

      loader: ->
        $modal.find(".step").hide()
        $loader.show()
        $modal.show()

      error: (error) ->
        $loader.hide()
        Giveaway.step.two.hide()
        Giveaway.step.three.show().find(".entry-status").html "<p>" + error + "</p>"
        Giveaway.share.listener()

      success: ->
        $loader.hide()
        Giveaway.step.two.hide()
        Giveaway.step.three.show()
        Giveaway.share.listener()

      submit: (access_token, json) ->
        Giveaway.entry.loader()
        if json
          console.log json
          access_token = eval("(" + access_token + ")")
          console.log access_token
        $.ajax
          type: "POST"
          url: "#{paths.giveaway_entry}"
          dataType: "json"
          data: "access_token=" + access_token + "&has_liked=" + Giveaway.eligible + "&ref_id=" + $referrer_id
          statusCode:
            201: (response) ->
              console.log(response)
              Giveaway.entry.success()
              $entry_id = response
              $wall_post_count = 0
              $request_count = 0

            406: (response) ->
              Giveaway.entry.error "You have already entered the giveaway.<br />Entry is limited to one per person."
              $entry = jQuery.parseJSON(response.responseText)
              console.log $entry
              $entry_id = $entry.id
              $wall_post_count = parseInt($entry.wall_post_count)
              $request_count = parseInt($entry.request_count)

            412: ->
              $loader.hide()
              Giveaway.step.one.show()

            404: ->
              Giveaway.entry.error "There was an unexpected error.<br />Please reload the page and try again."

            424: ->
              Giveaway.entry.error "There was an unexpected error.<br />Please reload the page and try again."

      statusCheck: ->
        FB.getLoginStatus (response) ->
          if response.authResponse
            Giveaway.entry.submit response.authResponse.accessToken
          else
            FB.login
              scope: "email, user_location, user_birthday, user_likes, publish_stream, offline_access"
            , (response) ->
              if response.authResponse
                $new_session = response.authResponse.accessToken
                Giveaway.entry.submit response.authResponse.accessToken, true
              else
                Giveaway.entry.error "You must grant permissions in order to enter the giveaway."

      eligible: ->
        console.log("entry.eligible #{$new_session}")
        Giveaway.entry.loader()
        if $new_session?
          Giveaway.entry.submit $new_session, true
        else
          Giveaway.entry.statusCheck()

    share:
      listener: ->
        $("a.wall-post").click (e) ->
          Giveaway.share.as_wall_post()
          e.preventDefault()

        $("a.app-request").click (e) ->
          Giveaway.share.as_app_request()
          e.preventDefault()

      callback: (json) ->
        $.ajax
          type: "PUT"
          url: "#{paths.giveaway_entry}/#{$entry_id}"
          dataType: "text"
          data: json
          statusCode:
            202: ->

            406: ->

            404: ->
              Giveaway.entry.error "There was an unexpected error.<br />Please reload the page and try again."

      dialog: (data) ->
        FB.ui data, (response) ->
          if response and response.post_id
            json = entry:
              wall_post_count: $wall_post_count + 1

            Giveaway.share.callback json
            console.log "Post was published." + $entry_id
          else if response and response.to
            json = entry:
              request_count: $request_count + response.to.length

            Giveaway.share.callback json
            console.log "Request was sent." + $entry_id
          else
            console.log "Nothing was shared." + $entry_id

      as_wall_post: ->
        Giveaway.share.dialog
          method: "feed"
          name: "#{giveaway_hash.current_page.name}"
          link: "#{giveaway_object.giveaway_url}" + "&app_data=ref_" + $entry_id
          picture: "#{giveaway_object.feed_image_url}"
          caption: "#{giveaway_object.title}"
          description: "#{giveaway_object.description}"

      as_app_request: ->
        Giveaway.share.dialog
          title: "Share this giveaway to receive a bonus entry."
          method: "apprequests"
          message: "#{giveaway_object.description}"
          data:
            referrer_id: $entry_id.toString()
            giveaway_id: "#{giveaway_object.id}"