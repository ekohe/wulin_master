let notifications = [];
const duration = 3; // Seconds

const container = () => $('#notification-container');

const isContainerCreated = () => container().length > 0;

const buildNotificationHtml = (message) => {
  const component = $('<div/>');
  component.addClass('notification');
  component.html(message);
  component.css('display', 'none');
  return component;
};

const initializeContainer = () => {
  if (isContainerCreated()) {
    return true;
  }
  const containerElement = $('<div/>');
  containerElement.attr('id', 'notification-container');
  $('body').append(containerElement);
};

const discardNotification = (notification) => {
  const removeNotification = () => notification.remove();
  notification.slideUp('fast', () => removeNotification());
};

window.saveMessage = (content, type) => {
  const nowDate = new Date();
  const hour = ('0' + nowDate.getHours()).slice(-2);
  const minute = ('0' + nowDate.getMinutes()).slice(-2);
  const message = {
    content: content,
    type: type || 'success',
    time: hour + ':' + minute
  };
  const $li = $('<li class="notification-item collection-item"></li>').prependTo($('#activity_menu-list'));
  const $icon = $('<i class="material-icons left"></i>').appendTo($li);
  $('<div>' + message.content + '</div>').appendTo($li);
  $('<div class="right">' + message.time + '</div>').appendTo($li);
  $('#activity_menu').removeClass('disabled');
  if (message.type == 'info') {
    $icon.text('error_outline');
  } else if (message.type == 'success') {
    $icon.text('done');
    $icon.addClass('green-text');
  } else {
    $icon.text('error');
    $icon.addClass('red-text');
  }
};

window.displayNewNotification = (message, type, always) => {
  window.saveMessage(message, type);
  initializeContainer();
  const notification = buildNotificationHtml(message);
  container().append(notification);
  notification.slideDown('fast');
  notification.bind('click', () => discardNotification(notification));
  const timedDiscard = () => discardNotification(notification);
  if (!always) {
    setTimeout(timedDiscard, duration * 1000);
  }
  return true;
};
