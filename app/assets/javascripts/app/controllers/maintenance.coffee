class Index extends App.ControllerContent
  requiredPermission: 'admin.maintenance'
  events:
    'change .js-modeSetting input': 'setMode'
    'change .js-loginSetting input': 'setLogin'
    'blur .js-Login': 'updateMessage'
    'submit .js-Message': 'sendMessage'

  elements:
    '.js-modeSetting input': 'modeSetting'
    '.js-loginSetting input': 'loginSetting'

  constructor: ->
    super

    @title 'Maintenance', true

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    localElement = $(App.view('maintenance')())
    localElement.find('.js-loginPreview').html( App.view('generic/login_preview')(
      logoUrl: @logoUrl()
    ))

    localElement.find('.js-textarea').ce({
      mode:      'richtext'
      multiline: true
      maxlength: 20000
    })

    @html localElement

  setMode: (e) =>
    value = @modeSetting.prop('checked')
    if value && !confirm('Sure?')
      @modeSetting.prop('checked', false)
      return value
    App.Setting.set('maintenance_mode', value)
    App.WebSocket.send(
      event:'maintenance'
      data:
        type: 'mode'
        on: value
    )

  setLogin: (e) =>
    value = @loginSetting.prop('checked')
    App.Setting.set('maintenance_login', value)

  updateMessage: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    App.Setting.set('maintenance_login_message', params.message)
    @notify
      type:      'success'
      msg:       App.i18n.translateContent('Update successful!')
      removeAll: true

  sendMessage: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    params.type = 'message'
    App.WebSocket.send(
      event:'maintenance'
      data: params
    )
    @notify
      type:      'success'
      msg:       App.i18n.translateContent('Sent successfully!')
      removeAll: true
    @render()

App.Config.set('Maintenance', { prio: 3600, name: 'Maintenance', parent: '#system', target: '#system/maintenance', controller: Index, permission: ['admin.maintenance'] }, 'NavBarAdmin')
