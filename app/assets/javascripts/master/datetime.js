// Config of Inputmask

Inputmask.extendAliases({
  wulinDateTime: {
    alias: "datetime",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
  },
});

Inputmask.extendAliases({
  wulinDate: {
    alias: "date",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
  },
});

Inputmask.extendAliases({
  wulinTime: {
    alias: "hh:mm",
    positionCaretOnClick: "none",
  },
});

// Config of flatpickr

const fpConfigInit = {
  allowInput: true,
};

const fpConfigDateTime = Object.assign({}, fpConfigInit, {
  dateFormat: "d/m/Y H:i",
  enableTime: true,
  time_24hr: true,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date([`${yyyy}-${mm}-${dd}`, time].join(" "));
  },
});

const fpConfigDate = Object.assign({}, fpConfigInit, {
  maxDate: "31/12/2100",
  minDate: "01/01/1900",
  dateFormat: "d/m/Y",
  enableTime: false,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date(`${yyyy}-${mm}-${dd}`);
  },
});

const fpConfigTime = Object.assign({}, fpConfigInit, {
  noCalendar: true,
  enableTime: true,
  dateFormat: "H:i",
  time_24hr: true,
});

/* Config of flatpickr in form */

const fpConfigForm = Object.assign({}, fpConfigInit, {
  clickOpens: true,
  onOpen: (selectedDates, dateStr, instance) => {
    instance.update(dateStr);
  },
});

const fpConfigFormDateTime = Object.assign({}, fpConfigForm, fpConfigDateTime);

const fpConfigFormDate = Object.assign({}, fpConfigForm, fpConfigDate);

const fpConfigFormTime = Object.assign({}, fpConfigForm, fpConfigTime, {
  onOpen: (selectedDates, dateStr = "12:00", instance) => {
    instance.update(dateStr);
  },
});
