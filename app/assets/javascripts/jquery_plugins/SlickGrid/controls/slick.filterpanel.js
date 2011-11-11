
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
      
      $grid.onColumnsReordered.subscribe(function(){ 
        generateFilters(); 
      });
      $grid.onColumnsResized.subscribe(function(){
        generateFilters();
      });
      
      trigger.click(function() {
        if ($($grid.getHeaderRow()).is(":visible"))
            $grid.hideHeaderRowColumns();
        else
        {
            $grid.showHeaderRowColumns();
            
            // This corrects the scrollLeft of the filter secondary header row.
            // The problem is that if the user scrolls on the left then click on filter, the
            //   filters wouldn't have scrolled while there were hidden so they appear shifted.
            // This corrects this problem by setting the scrollLeft value of the filters panel
            //   to the scrollLeft of the header row
            headerScroller = $($grid.getHeaderRow()).parent()[0];
            headerScroller.scrollLeft = $(headerScroller).prev()[0].scrollLeft;
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
        html += "<input type=\"text\" id=\""+field+"\" style=\"width:"+(parseInt(this.width)+filterWidthOffset) +
        "px; border-style: solid none solid solid;border-width: 1px 0 1px 1px;border-color:#AAA;height:20px\" value=\""+value+"\" class=\""+cssClass+"\"></input>";
      });
      
      // Empty the current filters applied array
      currentFiltersApplied = [];
      
      // Fills up and display the secondary row
      $($grid.getHeaderRow()).html(html).show();

      // Hook between the filter input box and the data loader setFilter
      $("input", $($grid.getHeaderRow())).keyup(function(e) {
        $loader.setFilter($(this).attr('id'), $(this).val());
      });
		}

		// This method store the current filters applied to the currentFiltersApplied array
		// We store the filters value so that after resizing or reordering of the columns, we can 
		//  generate the filters boxes with the same values
		function storeCurrentFilters() {
		  currentFiltersApplied = [];
		  $.each($("input", $($grid.getHeaderRow())), function() {
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