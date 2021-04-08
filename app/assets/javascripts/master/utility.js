// format the num
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat
const formatNum = (number) => new Intl.NumberFormat().format(number);

// ('dd/mm/yyyy', 'hh:mm:ss') => datetime
// e.g.
// formatDate("08/04/2021", '10:11:00') => Thu Apr 08 2021 10:11:00 GMT+0800 (China Standard Time)
const formatDate = (date, time) => {
  let dayMonthYear = date.replace(/^(\d{1,2}\/)(\d{1,2}\/)(\d{4})$/, '$2$1$3');
  let finalDate = `${dayMonthYear} ${time}`;
  return new Date(finalDate);
};
