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

//position flatpickr Calendar inside an modal
const positionCalendar = (self) => {
	let position = self.element.getBoundingClientRect()
	let top = position.y + position.height
	let left = position.x
	// verify if viewport bottom space is enough to contain calendar
	if ((window.innerHeight - position.bottom) < $(self.calendarContainer).height()) {
		top = position.y - $(self.calendarContainer).height()
	}
	$(self.calendarContainer).css({ top: `${top}px`, left: `${left}px` })
	//don't allow popup to scroll
	$(self.element).closest(".modal-content").css("overflow", "hidden")
}

const modalScrool = (instance) => {
	$(instance.element).closest('.modal-content').css("overflow", "")
}

//pass this option to flatpick to set position
//e.g
//flatpickr($.extend({}, fpConfigFormDate, onCalendarOpenClose));
const onCalendarOpenClose = {
	onOpen: function (selectedDates, dateStr, instance) {
		positionCalendar(instance)
		window.addEventListener('resize', () => {
			positionCalendar(instance)
		})
	},
	onClose: function (selectedDates, dateStr, instance) {
		modalScrool(instance)
	}
}