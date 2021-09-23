(function($) {
  // WulinMaster.FilterPanel
  $.extend(true, window, {
    WulinMaster: {
      FilterPanel: FilterPanel
    }
  });

  // function FilterPanel(grid, loader, triggerElement, currentFilters) {
  function FilterPanel(grid, loader, currentFilters) {
    var filterWidthOffset = -3; // 2 pixels padding on the left and one pixel for the border on the left
    // private
    var $grid;
    var $loader;
    var self = this;
    var currentFiltersApplied = [];

    function init() {
      $grid = grid;
      $loader = loader;

      generateFilters();

      $grid.onColumnsReordered.subscribe(function(){
        // Ekohe Add: Event hander defined in init() not works onColumnsReordered
        setupEventHander();
        $grid.setupColumnSort();
        generateFilters();
      });
      $grid.onColumnsResized.subscribe(function(){
        generateFilters();
      });

      $grid.onColumnsFrozen.subscribe(function() {
        currentFiltersApplied.forEach(item => {
          console.log(item)
          let input = $grid.getHeaders().find(`.slick-header-column input[data-id=${item.id}]`)
          if (input.length > 0) {
            $(input).val(item.value)
          }
        })

        setupEventHander()
      });

      // Ekohe Edit: Abstract event handers to method
      setupEventHander();
    }

    // Ekohe Add
    function setupEventHander() {

      var delay = (function(){
        var timer = 0;
        return function(callback, ms){
          clearTimeout (timer);
          timer = setTimeout(callback, ms);
        };
      })();

      // Ekohe Edit: Use new MD headers instead of headerRow
      // $input = $("input", $($grid.getHeaderRow()));
      // $input = $($grid.getHeaders()).find('input');

      // Hook between the filter input box and the data loader setFilter
      // Applay filter after 1000ms
      $($grid.getHeaders()).off('keyup', 'input').on('keyup', 'input', function(e) {
        var containerWidth = $grid.container.innerWidth();
        var $viewPort = $($grid.getCanvasNode()).parent();
        var inputLeft = $(this).position().left + $(this).outerWidth();
        var inputRight = $(this).position().left - $viewPort.scrollLeft() + $(this).outerWidth();
        var ignoreKeyCodes = [9, 224, 13];

        if ((containerWidth - inputRight) < 0) {
          $viewPort.scrollLeft(inputLeft - containerWidth);
        }

        if (ignoreKeyCodes.indexOf(e.which) == -1) {
          delay(function(){
            updateCurrentFilters();
            applyCurrentFilters(currentFilters);
            setCurrentFilter();

            trigger(self.onFilterLoaded, {filterData:currentFiltersApplied});
          }, 1000);
        }
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
      var $headerRow = $($grid.getHeaderRow());
      // Ekohe Add: Use new MD headers instead of headerRow
      var $headers = $($grid.getHeaders());
      var headerWidth = $($grid.getCanvasNode()).width() + 16;      // 16 is the vertical scrollbar width
      var ua = navigator.userAgent.toLowerCase();

      html = "";
      columns = $grid.getColumns();
      totalColumnsCount = columns.length;

      applyCurrentFilters(currentFilters);
      setOriginalFilter();

      // Ekohe Add: Use new MD headers instead of headerRow
      if (currentFiltersApplied.length > 0) {
        $.each(currentFiltersApplied, function(i, v) {
          var filteredHeaderCol = $headers.find('input[data-id="'+ v.id +'"]');
          // There will be a problem when two inputs need focus at the same time
          // Now we are only focus last one input
          filteredHeaderCol.focus();
          filteredHeaderCol.val(v.value);
        })
      }

      $.each(columns, function(i, v) {
        var field = v.id, inputHtml = '', inputWidth, cssClass = "";
        var value = '';
        // Try to get the value of this filter if any
        $.each(currentFiltersApplied, function() {
          if (this.id==field)
            value = this.value;
        });

        if (i==(totalColumnsCount-1)) {
          cssClass = "lastColumn";
        }

        // inputWidth = $.browser.mozilla ? parseInt(this.width, 10)+filterWidthOffset + 1 : parseInt(this.width, 10)+filterWidthOffset - 1;
        inputWidth = parseInt(this.width, 10)+filterWidthOffset - 1;

        // if (!$.browser.msie && (ua.indexOf("windows") != -1 || ua.indexOf("win32") != -1 || ua.indexOf("linux") != -1)) {
        //   inputWidth += 2;
        // }

        inputHtml += '<input type="text" id="' + field + '" style="width:' + inputWidth + 'px;border-width:1px;height:20px;border-bottom-color:#DDD;" value="' + value + '" class="' + cssClass + '"';

        if (this.filterable === false) {
          inputHtml += ' disabled="disabled"';
        }

        inputHtml += '></input>';
        html += inputHtml;
      });

      $grid.renderFilteredInputs();
    }

    // This method update the current filters applied to the currentFiltersApplied array
    // We store the filters value so that after resizing or reordering of the columns, we can
    //  generate the filters boxes with the same values
    function updateCurrentFilters() {
      currentFilters = {};
      // Ekohe Edit: Use new MD headers instead of headerRow
      // $.each($("input", $($grid.getHeaderRow())), function() {
      $.each($("input", $($grid.getHeaders())), function() {
        if ($(this).val() !== '') {
          currentFilters[$(this).attr('data-id')] = $(this).val();
        }
      });
    }

    function setOriginalFilter() {
      var originalFilters = $loader.getFilters();
      if (currentFiltersApplied.length !== 0) {
        $.each(currentFiltersApplied, function() {
          if(this['operator'] === undefined) this['operator'] = 'equals';
          var newFilter = [this['id'], this['value'], this['operator']];
          if(!$(originalFilters).arrayDeepInclude(newFilter)) {
            originalFilters.push([this['id'], this['value'], this['operator']]);
          }
        });

        $loader.setFilterWithoutRefresh(originalFilters);
      }
    }

    function setCurrentFilter(){
      var filters = [];
      // add current filters
      if (currentFiltersApplied.length > 0) {
        $.each(currentFiltersApplied, function(){
          filters.push([this['id'], this['value'], 'equals']);
        });
      }
      // add masters
      if ($grid.master) {
        if ($grid.master instanceof Array) {
          $.each($grid.master, function(){
            filters.push(this);
          });
        } else {
          filters.push([$grid.master.filter_column, $grid.master.filter_value, $grid.master.filter_operator || "equals"]);
        }
      }
      $loader.setFilter(filters);
    }

    function applyCurrentFilters(filters) {
      currentFiltersApplied = [];
      if (filters) {
        $.each(filters, function(k, v) {
          if (v !== '')
            currentFiltersApplied.push({id: k, value: v});
        });
      }
    }

    function reapply() {
      currentFiltersApplied = [];
      updateCurrentFilters();
      applyCurrentFilters(currentFilters);
      setCurrentFilter();
    }

    $.extend(this, {
        // Events
        "onFilterLoaded":                     new Slick.Event(),
        'onFilterPanelClosed':                new Slick.Event(),

        // Methods
        'trigger':                            trigger,          // Ekohe Add
        'setCurrentFilter':                   setCurrentFilter, // Ekohe Add
        'setupEventHander':                   setupEventHander, // Ekohe Add
        'generateFilters':                    generateFilters,
        "applyCurrentFilters":                applyCurrentFilters,
        "updateCurrentFilters":               updateCurrentFilters,
        "reapply":                            reapply
    });

    init();
  }
}(jQuery));
