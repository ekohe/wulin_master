// Get current year

var dateNow = new Date();
var yearNow = dateNow.getFullYear();

// Config of Inputmask

Inputmask.extendAliases({
  'wulinDateTime': {
    alias: 'datetime',
    placeholder: 'dd/mm/' + yearNow + ' 12:00',
    yearrange: { minyear: 1900, maxyear: 2100 },
  }
});

Inputmask.extendAliases({
  'wulinDate': {
    alias: 'date',
    placeholder: 'dd/mm/' + yearNow,
    yearrange: { minyear: 1900, maxyear: 2100 },
  }
});

Inputmask.extendAliases({
  'wulinTime': {
    alias: 'hh:mm',
    placeholder: '12:00',
  }
});

// Config of flatpickr

var fpConfigInit = {
  allowInput: true,
};

var fpConfigForm = $.extend({}, fpConfigInit, {
  clickOpens: true,
  onOpen: function(selectedDates, dateStr, instance) {
    instance.update(dateStr);
  },
});

var fpConfigFormDateBase = $.extend({}, fpConfigForm, {
  maxDate: '31/12/2100',
  minDate: '01/01/1900',
});

var fpConfigFormDateTime = $.extend({}, fpConfigFormDateBase, {
  enableTime: true,
  dateFormat: 'd/m/Y H:i',
  time_24hr: true,
});

var fpConfigFormDate = $.extend({}, fpConfigFormDateBase, {
  dateFormat: 'd/m/Y',
});

var fpConfigTime = $.extend({}, fpConfigForm, {
  noCalendar: true,
  enableTime: true,
  dateFormat: 'H:i',
  time_24hr: true,
  onOpen: function(selectedDates, dateStr, instance) {
    var time = dateStr || '12:00';
    instance.update(time);
  },
});
