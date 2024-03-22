const defaultYear = () => {
  const { DEFAULT_YEAR } = window;
  return DEFAULT_YEAR && DEFAULT_YEAR.length === "yyyy".length
    ? DEFAULT_YEAR
    : new Date().getFullYear();
};
const defaultMonth = () => {
  const { DEFAULT_MONTH } = window;
  return DEFAULT_MONTH && DEFAULT_MONTH.length === "mm".length
    ? DEFAULT_MONTH
    : String(new Date().getMonth() + 1).padStart("mm".length, "0");
};
const wulinMasterDateFormat = () => {
  const { DATE_FORMAT } = window;
  return DATE_FORMAT;
};
const USDateFormat = () => {
  return wulinMasterDateFormat() == 'us';
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
      placeholder: `dd/${defaultMonth()}/${defaultYear()} 12:00`,
      onKeyDown: function(event, buffer, caretPos, opts) {
        const [date, time] = opts.placeholder.split(" ");
        if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
          opts.placeholder = `dd/mm/yyyy ${time}`;
        }
      },
      onBeforeMask: function(value, opts) {
        const fromPrefilledValue = (value) => {
          const year = value.split(" ")[0].split("/")[2];
          const month = value.split(" ")[0].split("/")[1];
          const hh_mm = value.split(" ")[1];
          return `dd/${month}/${year} ${hh_mm}`;
        };

        if (value.length === "dd/mm/yyyy hh:mm".length) {
          opts.placeholder = fromPrefilledValue(value);
        } else {
          opts.placeholder = `dd/${defaultMonth()}/${defaultYear()} 12:00`;
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
      placeholder: `dd/${defaultMonth()}/${defaultYear()}`,
      onKeyDown: function(event, buffer, caretPos, opts) {
        if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
          opts.placeholder = `dd/mm/yyyy`;
        }
      },
      onBeforeMask: function(value, opts) {
        const fromPrefilledValue = (value) => {
          const year = value.split(" ")[0].split("/")[2];
          const month = value.split(" ")[0].split("/")[1];
          return `dd/${month}/${year}`;
        };

        if (value.length === "dd/mm/yyyy".length) {
          opts.placeholder = fromPrefilledValue(value);
        } else {
          opts.placeholder = `dd/${defaultMonth()}/${defaultYear()}`;
        }
      }
    }
  });

  Inputmask.extendAliases({
    wulinUSDate: {
      alias: "mm/dd/yyyy",
      showMaskOnHover: false,
      yearrange: { minyear: 1900, maxyear: 2100 },
      positionCaretOnClick: "none",
      placeholder: `mm/dd/${defaultYear()}`,
      onKeyDown: function(event, buffer, caretPos, opts) {
        if (caretPos === 4 && isFeb29(event, buffer, caretPos)) {
          opts.placeholder = `mm/dd/yyyy`;
        }
      },
      onBeforeMask: function(value, opts) {
        const fromPrefilledValue = (value) => {
          const year = value.split(" ")[0].split("/")[2];
          const month = value.split(" ")[0].split("/")[1];
          return `${month}/dd/${year}`;
        };

        if (value.length === "mm/dd/yyyy".length) {
          opts.placeholder = fromPrefilledValue(value);
        } else {
          opts.placeholder = `dd/${defaultMonth()}/${defaultYear()}`;
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
    try {
      return new Date(`${yyyy}-${mm}-${dd}T00:00:00`);
    } catch (e) {
      return null;
    }
  },
  onOpen: (selectedDates, dateStr, instance) => {
    const jumpDate =
      instance.config.mode === "range"
        ? instance.config.minDate
        : `01/01/${defaultYear()}`;
    instance.jumpToDate(jumpDate);
    instance.update(dateStr);
  }
});

const fpConfigUSDate = fpMergeConfigs({}, fpConfigInit, {
  maxDate: "12/31/2100",
  minDate: "01/01/1900",
  dateFormat: "m/d/Y",
  enableTime: false,
  parseDate: (str) => {
    const [date, time] = str.split(" ");
    let [mm, dd, yyyy] = date.split("/");
    try {
      return new Date(`${yyyy}-${mm}-${dd}T00:00:00`);
    } catch (e) {
      return null;
    }
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

const fpConfigFormUSDate = fpMergeConfigs({}, fpConfigForm, fpConfigUSDate);

const fpConfigFormTime = fpMergeConfigs({}, fpConfigForm, fpConfigTime);
