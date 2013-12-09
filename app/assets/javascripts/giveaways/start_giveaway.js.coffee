SG.Giveaways.Start =

  initialize: ->
    @initStartModal() if @modalEl().length
    @triggerStartModal() if @justSubscribed()

  initStartModal: ->
    @modalEl().modal
      debug: false
      closable: false
      onApprove: =>
        @moveForward()
        false
    .modal 'attach events', '#start_giveaway'

  triggerStartModal: ->
    @modalEl().find(".modal-step[data-modal-step='1']").hide()
    @modalEl().find(".modal-step[data-modal-step='2']").show()
    $('#start_giveaway').trigger 'click'

  justSubscribed: -> SG.userJustSubscribed.length

  moveForward: ->
    current = @currentStepEl()
    next = @nextStepEl()
    if next.find('#no_subscription').length
      @redirectToSubPlans()
    else if next.find("#trigger_start_giveaway").length
      @startGiveaway()
    else
      current.hide()
      next.show()

  redirectToSubPlans: ->
    $.ajax
      url: SG.Paths.subscriptionPlans
      type: 'POST'
      data:
        starting: true
      success: =>
        top.location.href = SG.Paths.subscriptionPlans

  startGiveaway: ->
    $('#step_one form').submit()

  currentStep: ->
    @currentStepEl().data('modal-step')

  currentStepEl: ->
    @modalEl().find('.modal-step:visible')

  nextStep: ->
    parseInt(@currentStep()) + 1

  nextStepEl: ->
    @modalEl().find(".modal-step[data-modal-step='#{@nextStep()}']").first()

  denyButtonEl: -> @modalEl().find('.deny.button')

  approveButtonEl: -> @modalEl().find('.approve.button')

  modalEl: -> $('.ui.modal.start-giveaway')
