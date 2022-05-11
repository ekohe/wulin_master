// Config of Inputmask
const currentYear = () => new Date().getFullYear();
const isFeb29 = (event, buffer, caretPos) =>
  [buffer.join("").substring(0, caretPos), event.key].join("") === "29/02";

Inputmask.extendAliases({
  wulinDateTime: {
    alias: "datetime",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
    placeholder: `dd/mm/${currentYear()} hh:mm`,
    onKeyDown: function (event, buffer, caretPos, opts) {
      if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
        const [date, time] = opts.placeholder.split(" ");
        opts.placeholder = `dd/mm/yyyy ${time}`;
      }
    },
    onBeforeMask: function (value, opts) {
      if (value.length === "dd/mm/yyyy hh:mm".length) {
        const yearFromPreviousValue = value.split(" ")[0].split("/")[2];
        const hh_mmFromPreviousValue = value.split(" ")[1];
        opts.placeholder = `dd/mm/${yearFromPreviousValue} ${hh_mmFromPreviousValue}`;
      }
    },
  },
});

Inputmask.extendAliases({
  wulinDate: {
    alias: "date",
    yearrange: { minyear: 1900, maxyear: 2100 },
    positionCaretOnClick: "none",
    placeholder: `dd/mm/${currentYear()}`,
    onKeyDown: function (event, buffer, caretPos, opts) {
      if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
        opts.placeholder = "dd/mm/yyyy";
      }
    },
    onBeforeMask: function (value, opts) {
      if (value.length === "dd/mm/yyyy".length) {
        const yearFromPreviousValue = value.split(" ")[0].split("/")[2];
        opts.placeholder = `dd/mm/${yearFromPreviousValue}`;
      }
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
});

const fpConfigTime = fpMergeConfigs({}, fpConfigInit, {
  noCalendar: true,
  enableTime: true,
  dateFormat: "H:i",
  time_24hr: true,
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

const fpConfigFormTime = Object.assign(
  fpMergeConfigs({}, fpConfigForm, fpConfigTime),
  {
    onOpen: (selectedDates, dateStr = "12:00", instance) => {
      instance.update(dateStr);
    },
  }
);
