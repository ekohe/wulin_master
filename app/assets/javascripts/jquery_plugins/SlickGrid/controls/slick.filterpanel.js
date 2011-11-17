(function($) {
  // Slick.FilterPanel
  $.extend(true, window, {
      Slick: {
          FilterPanel: FilterPanel
      }
  });
  function FilterPanel(grid, loader, triggerElement, currentFilters) {
    var filterWidthOffset = -3; // 2 pixels padding on the left and one pixel for the border on the left
    
    // private
    var $grid;
    var $loader;
    var $triggerElement;
    var self = this;
    var currentFiltersApplied;
    
    function init() {
      $grid = grid;
      $loader = loader;
      $triggerElement = triggerElement;
      
      generateFilters();
      
      $grid.onColumnsReordered.subscribe(function(){ 
        generateFilters(); 
      });
      $grid.onColumnsResized.subscribe(function(){
        generateFilters();
      });
      
      if (currentFilters) {
        $grid.showHeaderRowColumns();
      }
      
      triggerElement.click(function() {
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
		
		function trigger(evt, args, e) {
        e = e || new Slick.EventData();
        args = args || {};
        args.filterPanel = self;
        return evt.notify(args, e, self);
    }
		
		function generateFilters() {
		  var inputWidth, columns, inputElement;
      // storeCurrentFilters();

      html = "";
      columns = $grid.getColumns();
      totalColumnsCount = columns.length;
      
      setCurrentFilters(currentFilters);
      $.each(columns, function(i, value) {
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
        inputWidth = $.browser.mozilla ? parseInt(this.width)+filterWidthOffset + 1 : parseInt(this.width)+filterWidthOffset - 1
        html += "<input type=\"text\" id=\""+field+"\" style=\"width:"+ inputWidth +
        "px;border-width: 1px;height:20px;border-bottom-color:#DDD;\" value=\""+value+"\" class=\""+cssClass+"\"></input>";
      });
      
      // Fills up and display the secondary row
      $($grid.getHeaderRow()).html(html).show();
      // Hook between the filter input box and the data loader setFilter
      $("input", $($grid.getHeaderRow())).keyup(function(e) {
        storeCurrentFilters();
        $loader.addFilter($(this).attr('id'), $(this).val());
        trigger(self.onFilterLoaded, {filterData:currentFiltersApplied});
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
		
		function setFilter() {
      var newFilters = [];
      if (currentFiltersApplied.length != 0) {
        $.each(currentFiltersApplied, function() {
          newFilters.push([this['id'], this['value']]);
        });
        if ($loader.isDataLoaded()) {
          $loader.setFilter(newFilters);
        } else {
          setTimeout(function(){
            $loader.setFilter(newFilters);}, 50)
        }
	    }
		}
		
		function setCurrentFilters(filters) {
		  currentFiltersApplied = [];
		  if (filters) {
  		  $.each(filters, function(k, v) {
          if (v !='')
  		      currentFiltersApplied.push({id: k, value: v});
  		  });
	    }
		}
		
		function applyCurrentFilters(currentFilters) {
		  if (currentFilters) {
		    grid.showHeaderRowColumns();
		  }
		}
		
		$.extend(this, {
        // Events
        "onFilterLoaded":                     new Slick.Event(),
        
        // Methods
        "applyCurrentFilters":                applyCurrentFilters,
        "setCurrentFilters":                  setCurrentFilters
    });
		
		init();
	}
}(jQuery));