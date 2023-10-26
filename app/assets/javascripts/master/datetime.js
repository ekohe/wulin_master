const defaultYear = () => {
  const { DEFAULT_YEAR } = window;
  return DEFAULT_YEAR && DEFAULT_YEAR.length === "yyyy".length
    ? DEFAULT_YEAR
    : new Date().getFullYear();
};
const defaultMonth = () => {
  const { DEFAULT_MONTH } = window;
  return DEFAULT_MONTH && DEFAULT_MONTH.length === 2 ? DEFAULT_MONTH : (new Date().getMonth() + 1).toString().padStart(2, '0');
};
const isFeb29 = (event, buffer, caretPos) =>
  [buffer.join("").substring(0, caretPos), event.key].join("") === "29/02";

// Config of Inputmask
function ConfigInputmask() {
  Inputmask.extendAliases({
    wulinDateTime: {
      alias: "datetime",
      showMaskOnHover: false,
      yearrange: { minyear: 1900, maxyear: 2100 },
      positionCaretOnClick: "none",
      placeholder: `dd/mm/${defaultYear()} 12:00`,
      onKeyDown: function(event, buffer, caretPos, opts) {
        const [date, time] = opts.placeholder.split(" ");
        if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
          opts.placeholder = `dd/mm/yyyy ${time}`;
        }
      },
      onBeforeMask: function(value, opts) {
        const fromPreviousValue = (value) => {
          const year = value.split(" ")[0].split("/")[2];
          const hh_mm = value.split(" ")[1];
          return `dd/mm/${year} ${hh_mm}`;
        };

        if (value.length === "dd/mm/yyyy hh:mm".length) {
          opts.placeholder = fromPreviousValue(value);
        }
      }
    }
  });

  Inputmask.extendAliases({
    wulinDate: {
      alias: "date",
      showMaskOnHover: false,
      yearrange: { minyear: 1900, maxyear: 2100 },
      positionCaretOnClick: "none",
      placeholder: `dd/mm/${defaultYear()}`,
      onKeyDown: function(event, buffer, caretPos, opts) {
        if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
          opts.placeholder = `dd/mm/yyyy`;
        }
      },
      onBeforeMask: function(value, opts) {
        const fromPreviousValue = (value) => {
          const year = value.split(" ")[0].split("/")[2];
          return `dd/mm/${year}`;
        };

        if (value.length === "dd/mm/yyyy".length) {
          opts.placeholder = fromPreviousValue(value);
        }
      }
    }
  });

  Inputmask.extendAliases({
    wulinTime: {
      alias: "hh:mm",
      showMaskOnHover: false,
      positionCaretOnClick: "none"
    }
  });
}

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
  allowInput: true
};

const fpConfigDateTime = fpMergeConfigs({}, fpConfigInit, {
  dateFormat: "d/m/Y H:i",
  enableTime: true,
  time_24hr: true,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date(`${yyyy}-${mm}-${dd}T${time}`);
  },
  onOpen: (selectedDates, dateStr, instance) => {
    instance.jumpToDate(`01/${defaultMonth()}/${defaultYear()} 12:00`);
    instance.update(dateStr);
  }
});

const fpConfigDate = fpMergeConfigs({}, fpConfigInit, {
  maxDate: "31/12/2100",
  minDate: "01/01/1900",
  dateFormat: "d/m/Y",
  enableTime: false,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    const [dd, mm, yyyy] = date.split("/");
    return new Date(`${yyyy}-${mm}-${dd}T00:00:00`);
  },
  onOpen: (selectedDates, dateStr, instance) => {
    const jumpDate =
      instance.config.mode === "range"
        ? instance.config.minDate
        : `01/${defaultMonth()}/${defaultYear()}`;
    instance.jumpToDate(jumpDate);
    instance.update(dateStr);
  }
});

const fpConfigTime = fpMergeConfigs({}, fpConfigInit, {
  noCalendar: true,
  enableTime: true,
  dateFormat: "H:i",
  time_24hr: true,
  onOpen: (selectedDates, dateStr, instance) => {
    dateStr = dateStr.length === "hh:mm".length ? dateStr : "12:00";
    $(instance.input).val(dateStr);
  }
});

/* Config of flatpickr in form */

const fpConfigForm = fpMergeConfigs({}, fpConfigInit, {
  clickOpens: true,
  onOpen: (selectedDates, dateStr, instance) => {
    $(instance.input).trigger("focus");
    setTimeout(() => {
      instance.open();
    }, 200);
  },
  onClose: (selectedDates, dateStr, instance) => {
    const cancelInvalidInputStr = (dateStr, instance) => {
      const notValidReg = /[a-z]/;
      if (notValidReg.test(dateStr)) {
        $(instance.input).val("");
      }
    };
    const dropLabels = (input) =>
      input.labels.forEach((label) => $(label).removeClass("active"));
    const liftLabels = (input) =>
      input.labels.forEach((label) => $(label).addClass("active"));

    // mode is in ['single', 'multiple', 'range', undefined], undefined would behave as 'single'
    instance.instanceConfig.mode !== "range" && cancelInvalidInputStr(dateStr, instance);
    $(instance.input).val()
      ? liftLabels(instance.input)
      : dropLabels(instance.input);
  }
});

const fpConfigFormDateTime = fpMergeConfigs({}, fpConfigForm, fpConfigDateTime);

const fpConfigFormDate = fpMergeConfigs({}, fpConfigForm, fpConfigDate);

const fpConfigFormTime = fpMergeConfigs({}, fpConfigForm, fpConfigTime);
