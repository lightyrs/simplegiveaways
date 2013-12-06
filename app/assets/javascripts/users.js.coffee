SG.Users =

  initialize: ->
    @initPagesPoller() if @pagesPollerEl().length

  initPagesPoller: ->
    @pollTimer = setInterval (=> @pollPages()), 2500

  pollPages: ->
    $.ajax
      url: SG.Paths.userPages
      dataType: 'json',
      success: (response, status) =>
        @pagesTargetEl().html(response.html) if response.html.length
        if response.complete
          clearInterval(@pollTimer)
          @pagesPollerEl().transition(complete: => @pagesPollerEl().remove())

  pagesTargetEl: -> $('#user_facebook_pages')

  pagesPollerEl: -> $('#pages_poller')