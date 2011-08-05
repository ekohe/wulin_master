
(function($) {
  function FilterPanel(grid, loader, trigger) {
    var filterWidthOffset = -3; // 2 pixels padding on the left and one pixel for the border on the left
    
    // private
    var $grid;
    var $loader;
    var $trigger;
    var currentFiltersApplied;
    
    function init() {
      $grid = grid;
      $loader = loader;
      $trigger = trigger;
      
      generateFilters();
      
      $grid.onColumnsReordered = function() { generateFilters(); };
      $grid.onColumnsResized = function() { generateFilters(); };
      
      trigger.click(function() {
        if ($($grid.getSecondaryHeaderRow()).is(":visible"))
            $grid.hideSecondaryHeaderRow();
        else
        {
            $grid.showSecondaryHeaderRow();
            
            // This corrects the scrollLeft of the filter secondary header row.
            // The problem is that if the user scrolls on the left then click on filter, the
            //   filters wouldn't have scrolled while there were hidden so they appear shifted.
            // This corrects this problem by setting the scrollLeft value of the filters panel
            //   to the scrollLeft of the header row
            secondaryHeaderScroller = $($grid.getSecondaryHeaderRow()).parent()[0];
            secondaryHeaderScroller.scrollLeft = $(secondaryHeaderScroller).prev()[0].scrollLeft;
        }
        return false;
      });
		}
		
		function generateFilters() {
		  storeCurrentFilters();
		  
      html = "";
      totalColumnsCount = $grid.getColumns().length;
      $.each($grid.getColumns(), function(i, value) {
        value = '';
        field = this.field;
        // Try to get the value of this filter if any
        $.each(currentFiltersApplied, function() {
          if (this.id==field)
            value = this.value;
        });

        cssClass = "";
        if (i==(totalColumnsCount-1)) {
          cssClass = "lastColumn";
        }
        html += "<input type=\"text\" id=\""+field+"\" style=\"width:"+(parseInt(this.width)+filterWidthOffset)+"px\" value=\""+value+"\" class=\""+cssClass+"\"></input>";
      });
      
      // Empty the current filters applied array
      currentFiltersApplied = [];
      
      // Fills up and display the secondary row
      $($grid.getSecondaryHeaderRow()).html(html).show();

      // Hook between the filter input box and the data loader setFilter
      $("input", $($grid.getSecondaryHeaderRow())).keyup(function(e) {
        $loader.setFilter($(this).attr('id'), $(this).val());
      });
		}

		// This method store the current filters applied to the currentFiltersApplied array
		// We store the filters value so that after resizing or reordering of the columns, we can 
		//  generate the filters boxes with the same values
		function storeCurrentFilters() {
		  currentFiltersApplied = [];
		  $.each($("input", $($grid.getSecondaryHeaderRow())), function() {
        if ($(this).val()!='')
		      currentFiltersApplied.push({id:$(this).attr('id'), value:$(this).val()});
		  });
		}
		
		init();

		return {};
	}

	// Slick.FilterPanel
	$.extend(true, window, { Slick: { FilterPanel: FilterPanel }});
})(jQuery);