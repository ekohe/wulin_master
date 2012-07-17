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
    var self = this;
    var currentFiltersApplied;
    
    function init() {
      $grid = grid;
      $loader = loader;
      
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
        if($(this).hasClass('toolbar_icon_disabled')) return false;
        
        if ($($grid.getHeaderRow()).is(":visible")) {
            $grid.hideHeaderRowColumns();
            trigger(self.onFilterPanelClosed, {filterData:currentFiltersApplied});
        } else {   
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
		  var ua = navigator.userAgent.toLowerCase();
      // storeCurrentFilters();

      html = "";
      columns = $grid.getColumns();
      totalColumnsCount = columns.length;
      
      setCurrentFilters(currentFilters);
      setFilter();
      $.each(columns, function(i, value) {
        var value = '', field = this.field, inputHtml = '', inputWidth, cssClass = "";
        // Try to get the value of this filter if any
        $.each(currentFiltersApplied, function() {
          if (this.id==field)
            value = this.value;
        });

        if (i==(totalColumnsCount-1)) {
          cssClass = "lastColumn";
        }
        
        inputWidth = $.browser.mozilla ? parseInt(this.width)+filterWidthOffset + 1 : parseInt(this.width)+filterWidthOffset - 1;
        
        if (!$.browser.msie && (ua.indexOf("windows") != -1 || ua.indexOf("win32") != -1 || ua.indexOf("linux") != -1)) {
          inputWidth += 2;
        }
        
        inputHtml += '<input type="text" id="' + field + '" style="width:' + inputWidth + 'px;border-width:1px;height:20px;border-bottom-color:#DDD;" value="' + value + '" class="' + cssClass + '"';
        
        if (this.filterable == false) {
          inputHtml += ' disabled="disabled"';
        }
        
        inputHtml += '></input>';
        html += inputHtml;
      });
      
      // Fills up and display the secondary row
      $($grid.getHeaderRow()).html(html).show();
      
      var delay = (function(){
        var timer = 0;
        return function(callback, ms){
          clearTimeout (timer);
          timer = setTimeout(callback, ms);
        };
      })();
      
      // Hook between the filter input box and the data loader setFilter
      // Applay filter after 1000ms
      $("input", $($grid.getHeaderRow())).keyup(function(e) {
        var inputE = this;
        delay(function(){
          storeCurrentFilters();
          $loader.addFilter($(inputE).attr('id'), $(inputE).val());
          trigger(self.onFilterLoaded, {filterData:currentFiltersApplied});
        }, 1000 );
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
      var originalFilters = $loader.getFilters();
      if (currentFiltersApplied.length != 0) {
        $.each(currentFiltersApplied, function() {
          if(this['operator'] == undefined) this['operator'] = 'equals'
          originalFilters.push([this['id'], this['value'], this['operator']]);
        });

        $loader.setFilterWithoutRefresh(originalFilters);
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
        'onFilterPanelClosed':                new Slick.Event(),
        
        // Methods
        'generateFilters':                    generateFilters, 
        "applyCurrentFilters":                applyCurrentFilters,
        "setCurrentFilters":                  setCurrentFilters
    });
		
		init();
	}
}(jQuery));