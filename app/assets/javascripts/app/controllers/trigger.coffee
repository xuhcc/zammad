class Index extends App.ControllerContent
  requiredPermission: 'admin.trigger'
  constructor: ->
    super

    new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Trigger'
      defaultSortBy: 'name'
      pageData:
        title: 'Triggers'
        home: 'triggers'
        object: 'Trigger'
        objects: 'Triggers'
        navupdate: '#triggers'
        notes: [
          'Triggers are ...'
        ]
        buttons: [
          { name: 'New Trigger', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      large: true
    )

App.Config.set('Trigger', { prio: 3300, name: 'Trigger', parent: '#manage', target: '#manage/trigger', controller: Index, permission: ['admin.trigger'] }, 'NavBarAdmin')
