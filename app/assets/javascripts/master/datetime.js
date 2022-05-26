// Config of Inputmask
const defaultYear = () => {
  const { DEFAULT_YEAR } = window;
  return DEFAULT_YEAR && DEFAULT_YEAR.length === "yyyy".length
    ? DEFAULT_YEAR
    : new Date().getFullYear();
};
const isFeb29 = (event, buffer, caretPos) =>
  [buffer.join("").substring(0, caretPos), event.key].join("") === "29/02";

Inputmask.extendAliases({
  wulinDateTime: {
    alias: "datetime",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
    onKeyDown: function (event, buffer, caretPos, opts) {
      const [date, time] = opts.placeholder.split(" ");
      if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
        opts.placeholder = `dd/mm/yyyy ${time}`;
      }
    },
    onBeforeMask: function (value, opts) {
      const fromPreviousValue = (value) => {
        const year = value.split(" ")[0].split("/")[2];
        const hh_mm = value.split(" ")[1];
        return `dd/mm/${year} ${hh_mm}`;
      };

      opts.placeholder =
        value.length === "dd/mm/yyyy hh:mm".length
          ? fromPreviousValue(value)
          : `dd/mm/${defaultYear()} 12:00`;
    },
  },
});

Inputmask.extendAliases({
  wulinDate: {
    alias: "date",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
    onKeyDown: function (event, buffer, caretPos, opts) {
      if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
        opts.placeholder = `dd/mm/yyyy`;
      }
    },
    onBeforeMask: function (value, opts) {
      const fromPreviousValue = (value) => {
        const year = value.split(" ")[0].split("/")[2];
        return `dd/mm/${year}`;
      };

      opts.placeholder =
        value.length === "dd/mm/yyyy".length
          ? fromPreviousValue(value)
          : `dd/mm/${defaultYear()}`;
    },
  },
});

Inputmask.extendAliases({
  wulinTime: {
    alias: "hh:mm",
    positionCaretOnClick: "none",
  },
});

// Config of flatpickr

/**
 *  use fpMergeConfigs method to avoid configs overriding each other's hooks
 *  use Object.assign(target, source) or $.extend(target, source) if you do want to override `target` hooks with `source`
 * @param configs: Array of fpConfig
 */
const fpMergeConfigs = (...configs) => {
  /**
   * Assign normal options while merge hooks into an array
   *
   * e.g. target = {a : 'a', onOpen: () => 'onOpen1'}
   *      source = {a: 'aa', onOpen: () => 'onOpen2'}
   *      mergeConfig(target, source) will produce:
   *      {a: 'aa', onOpen: [() => 'onOpen1', () => 'onOpen2']}
   */
  const mergeConfigs = (target, source) => {
    const isHook = (key) => /^on/.test(key);

    const all = Object.assign({}, target, source);

    const allHooks = Object.fromEntries(
      Object.keys(all)
        .filter((k) => isHook(k))
        .map((k) => [k, []])
    );

    const targetHooks = Object.entries(target).filter(([k, v]) => isHook(k));
    const sourceHooks = Object.entries(source).filter(([k, v]) => isHook(k));

    targetHooks.forEach(([k, v]) => (allHooks[k] = [allHooks[k], v].flat()));
    sourceHooks.forEach(([k, v]) => (allHooks[k] = [allHooks[k], v].flat()));

    return Object.assign(all, allHooks);
  };

  return configs.reduce(mergeConfigs, {});
};

const fpConfigInit = {
  allowInput: true,
};

const fpConfigDateTime = fpMergeConfigs({}, fpConfigInit, {
  dateFormat: "d/m/Y H:i",
  enableTime: true,
  time_24hr: true,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date([`${yyyy}-${mm}-${dd}`, time].join(" "));
  },
  onOpen: (selectedDates, dateStr, instance) => {
    instance.jumpToDate(`01/01/${defaultYear()} 12:00`);
    instance.update(dateStr);
  },
});

const fpConfigDate = fpMergeConfigs({}, fpConfigInit, {
  maxDate: "31/12/2100",
  minDate: "01/01/1900",
  dateFormat: "d/m/Y",
  enableTime: false,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date(`${yyyy}-${mm}-${dd}`);
  },
  onOpen: (selectedDates, dateStr, instance) => {
    instance.jumpToDate(`01/01/${defaultYear()}`);
    instance.update(dateStr);
  },
});

const fpConfigTime = fpMergeConfigs({}, fpConfigInit, {
  noCalendar: true,
  enableTime: true,
  dateFormat: "H:i",
  time_24hr: true,
  onOpen: (selectedDates, dateStr, instance) => {
    dateStr = dateStr.length === "hh:mm".length ? dateStr : "12:00";
    $(instance.input).val(dateStr);
  },
});

/* Config of flatpickr in form */

const fpConfigForm = fpMergeConfigs({}, fpConfigInit, {
  clickOpens: true,
  onOpen: (selectedDates, dateStr, instance) => {
    instance.update(dateStr);
  },
});

const fpConfigFormDateTime = fpMergeConfigs({}, fpConfigForm, fpConfigDateTime);

const fpConfigFormDate = fpMergeConfigs({}, fpConfigForm, fpConfigDate);

const fpConfigFormTime = fpMergeConfigs({}, fpConfigForm, fpConfigTime);
