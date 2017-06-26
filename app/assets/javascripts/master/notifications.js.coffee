notifications = []
duration = 3 # Seconds

container = ->
  $('#notificationContainer')

isContainerCreated = ->
  container().length > 0

buildNotificationHtml = (message) ->
  component = $('<div/>')
  component.addClass('notification')
  component.html(message)
  component.css('display', 'none')
  component

initializeContainer = ->
  if isContainerCreated()
    return true
  containerElement = $('<div/>')
  containerElement.attr('id', 'notificationContainer')
  $('body').append(containerElement)

discardNotification = (notification) ->
  removeNotification = ->
    notification.remove()
  notification.slideUp('fast', -> removeNotification())

window.saveMessage = (content, type) ->
  nowDate = new Date();
  message = {
    content: content,
    type: type || 'success',
    time: nowDate.getHours() + ':' + nowDate.getMinutes()
  }
  $li = $('<li class="notification-item collection-item"></li>').prependTo($('#notification-list'))
  $icon = $('<i class="material-icons left"></i>').appendTo($li)
  $('<div>' + message.content + '</div>').appendTo($li)
  $('<div class="right">' + message.time + '</div>').appendTo($li)
  $('#notification-btn').removeClass('disabled')
  if message.type == 'info'
    $icon.text('error_outline')
  else if message.type == 'success'
    $icon.text('done')
    $icon.addClass('green-text')
  else
    $icon.text('error')
    $icon.addClass('red-text')

window.displayNewNotification = (message, type, always) ->
  window.saveMessage(message, type)
  initializeContainer()
  notification = buildNotificationHtml(message)
  container().append(notification)
  notification.slideDown('fast')
  notification.bind('click', -> discardNotification(notification))
  timedDiscard = ->
    discardNotification(notification)
  setTimeout(timedDiscard, duration*1000) unless always
  true
