// Remote model with pagination

(function($) {
  function RemoteModel(path, initialFilters, columns) {
    // private
    var loadingSize = 200;
    var preemptiveLoadingSize = 100;
    var pageSize = 0;
    var pageNum = 0;
    var totalRows = 0;
    var rowsWithoutFilter = -1; // Ekohe Add
    var data = {length:0};
    var oldData = {length:0};
    var sortcol = null;
    var sortdir = 1;
    var h_request = null;
    var req = null; // ajax request
    var req_page;
    var params = [];
    var pagingOptionsChanged = false;
    var grid;
    var loadingIndicator = null;
    var mainIndicator = null;
    var initedFilter = false;
    var filters = [];
    var lastRequestVersionNumber = 0;
    var currentRequestVersionNumber = 0;
    var self = this;

    if(initialFilters) {
      for(var i = 0; i < initialFilters.length; i++) {
        filters.push([initialFilters[i]['column'], initialFilters[i]['value'], initialFilters[i]['operator']]);
      }
    }

    // Connection manager
    var connectionManager = new ConnectionManager();

    // events
    var beforeRemoteRequest = new Slick.Event();
    var onDataLoading = new Slick.Event();
    var onPagingInfoChanged = new Slick.Event();
    var onDataLoaded = new Slick.Event();

    function setGrid(newGrid) {
      grid = newGrid;

      //  Connect the grid and the loader
      grid.onViewportChanged.subscribe(function(e, args) {
        var vp = grid.getViewport();
        // when the grid rendered, onViewportChanged will be triggerd, if eagerLoading is false and no data loaded yet, we don't load the initial data
        if(grid.options.eagerLoading === false && grid.getData().length === 0) return false;
        // Event triggered before the ajax request
        beforeRemoteRequest.notify();
        ensureData(vp.top, vp.bottom);
      });

      grid.onSort.subscribe(function(e, args){
        setSort(args.sortCol.sortColumn, args.sortAsc ? 1 : -1);
      });
    }

    function rowsChanged() {
      var vp = grid.getViewport();
      ensureData(vp.top, vp.bottom);
    }

    function dataIsLoaded(args) {
      for (var i = args.from; i < args.to; i++) {
        grid.invalidateRow(i);
      }

      // Ekohe Add: Set data length without filter
      if (grid.loader.getFilters().length == 0) {
        grid.setDataLengthWithoutFilter(grid.getDataLength());
      }
      rowsWithoutFilter = grid.getDataLengthWithoutFilter();

      grid.updateRowCount();

      grid.render();

      onDataLoaded.notify();
    }

    function isDataLoaded(from,to) {
      for (var i=from; i<=to; i++) {
        if (data[i] === undefined || data[i] === null)
          return false;
      }

      return true;
    }


    function clear() {
      for (var key in data) {
        delete data[key];
      }
      data.length = 0;
    }

    function generateUrl(from, to) {
      // pagination - specific to the grid viewport
      var paginationOptions = getPaginationOptions(from, to);
      var offset = paginationOptions[0];
      var count = paginationOptions[1];
      var normalLoadingMode = true;
      if (count === 0) {
        // Nothing to load, try to see if there is a need to load data preemptively
        paginationOptions = getPaginationOptions(from-preemptiveLoadingSize, to+preemptiveLoadingSize);
        offset = paginationOptions[0];
        count = paginationOptions[1];

        if (count === 0) {
          // the current data on the view is loaded and no preemptive loading to do
          return null;
        }

        // Preemptive loading mode
        normalLoadingMode = false;
      }
      if (initedFilter || filters.length > 0) {
        path = path.replace(/filters.*?&/g,'').replace(/&filters.*/g,'');
      } else {
        initedFilter = true;
      }
      var url = path + "&offset=" + offset + "&count=" + count;

      // filters, ordering, extra parameters - not specific to the viewport
      url += conditionalURI();
      return [url, normalLoadingMode];
    }

    function conditionalURI() {
      // Sorting
      if (sortcol === null) {
        sortcol = "";
      }
      var url = "&sort_col="+encodeURIComponent(sortcol);
      if (sortdir>0) {
        url += "&sort_dir=ASC";
      } else {
        url += "&sort_dir=DESC";
      }

      // Filters
      $.each(filters, function(index, value) {
        url += "&filters[][column]="+encodeURIComponent(value[0])+"&filters[][value]="+encodeURIComponent(value[1])+"&filters[][operator]="+encodeURIComponent(value[2]);
      });

      // Parameters
      $.each(params, function(index, value) {
        url += "&"+encodeURIComponent(value[0])+"="+encodeURIComponent(value[1]);
      });

      return url;
    }

    // Returns offset, count
    function getPaginationOptions(from, to) {
      // 2 cases, whether we are in load-as-scroll mode or the per page mode
      if (pageSize === 0) {
        // Load as we scroll
        if (from < 0)
          from = 0;

        fromPage = Math.floor(from / loadingSize);

        toPage = Math.floor(to / loadingSize);


        // Increment fromPage if the page at fromPage is already loaded until we find an area that hasn't been loaded yet
        while (data[fromPage * loadingSize] !== undefined && fromPage < toPage)
          fromPage++;

        // Decrement toPage if the page at fromPage is already loaded until we find an area that hasn't been loaded yet
        while (data[toPage * loadingSize] !== undefined && fromPage < toPage)
          toPage--;

        // if (fromPage > toPage || ((fromPage == toPage) && data[fromPage*loadingSize] !== undefined)) {
        if (fromPage > toPage || ((fromPage == toPage) && data[fromPage*loadingSize])) {
          return [0,0];
        }

        for (var i=fromPage; i<=toPage; i++)
          data[i*loadingSize] = null; // null indicates a 'requested but not available yet'

        return [(fromPage * loadingSize), (((toPage - fromPage) * loadingSize) + loadingSize)];
      } else {
        // Per page
        if (pagingOptionsChanged === false) {
          return [0,0];
        }
        pagingOptionsChanged = false;
        fromPage = pageNum;
        toPage = pageNum;

        // for (var i=fromPage; i<=toPage; i++)
        //   data[i*loadingSize] = null; // null indicates a 'requested but not available yet'
        return [(pageNum * pageSize), pageSize];
      }
    }

    function ensureData(from,to) {
      var urlData = generateUrl(from, to);

      // Nothing to load, just return.
      if(urlData === null) { return; }
      var url = urlData[0];
      var normalLoading = urlData[1];

      // Ekohe Edit: Stop passing indicator to connection (Create progress bar as indicator in connection instead)
      // Store loading size to provide stats. If pageSize is not zero then we are coming from a pager request.
      // loadingIndicator.loadingSize = (pageSize === 0 ? loadingSize : pageSize);
      connectionManager.createConnection(grid, url, loadingIndicator, onSuccess, onError, currentRequestVersionNumber);
    }


    function onError(request, textStatus, errorThrown) {
      //
    }

    function onSuccess(resp, textStatus, request) {
      var from;
      var to;

      if (pageSize === 0) {
        from = resp.offset;
        to = resp.offset + resp.count;
        data.length = parseInt(resp.total, 10);
      } else {
        from = 0;
        to = parseInt(resp.count, 10);
        data.length = to;
      }

      totalRows = parseInt(resp.total, 10);
      if (resp.rows) {
        for (var i = 0; i < resp.rows.length; i++) {
          var j = parseInt(from, 10) + parseInt(i, 10);
          var obj = {};
          $.each(columns, function(index, value) {
            var item = resp.rows[i][index];
            // match the column and the response data (compare column name and response data key)
            if(item && typeof(item) == 'object' && !(item instanceof Array)) {
              $.extend(true, obj, item);
            } else {
              obj[value.id] = item;
            }
          });
          data[j] = obj;
          data[j].slick_index = j;
        }
      }
      req = null;

      // keep oldData as a clone of data, never get deleted
      this.loader.oldData = deep_clone(data);

      // Loading data
      dataIsLoaded({from:from, to:to});

      // Updating pager
      onPagingInfoChanged.notify(getPagingInfo());
    }

    function getColumns() {
      return columns;
    }

    function getKeys(h) {
      var keys = [];
      for (var key in h)
        keys.push(key);
      return keys;
    }

    function reloadData(from,to) {
      if(!from && !to){
        var position = decideCurrentPosition();
        from = position[0];
        to = position[1];
      }
      var i;
      if (from && to) {
        for (i=from; i<=to; i++)
          delete data[i];
      } else {
        for (i=0; i<=data.length; i++)
          delete data[i];
      }

      ensureData(from,to);
    }

    function decideCurrentPosition(){
      var currentRow, from;
      if(grid.operatedIds && grid.operatedIds.length > 0) {
        var gridRow = grid.getRowByRecordId(grid.operatedIds[grid.operatedIds.length-1]);
        if(!gridRow) return [null, null];
        currentRow = gridRow.index - 1;
        from = parseInt(currentRow / 200, 10) * 200;
        return [from, currentRow];
      } else {
        return [null, null];
      }
    }

    function setSort(column,dir) {
      if (sortcol != column || sortdir != dir) {
        currentRequestVersionNumber++;
        sortcol = column;
        sortdir = dir;
      }
      refresh();
    }

    function setSortWithoutRefresh(column, dir) {
      if (sortcol != column || sortdir != dir) {
        currentRequestVersionNumber++;
        sortcol = column;
        sortdir = dir;
      }
    }

    function getSortColumn() {
      return sortcol;
    }

    function getSortDirection() {
      return sortdir;
    }

    function setFilter(filterFn) {
      if (filters != filterFn) {
        currentRequestVersionNumber++;
        filters = filterFn;
      }
      refresh();
    }

    function setFilterWithoutRefresh(filterFn) {
      if (filters != filterFn) {
        currentRequestVersionNumber++;
        filters = filterFn;
      }
    }

    function addFilterWithoutRefresh(column, string, operator) {
      if(typeof(operator)==='undefined') operator = 'equals';

      // If the string is an empty string and operator is 'equals', then removing the filter if existing
      if (string === '' && operator == 'equals') {
        var newFilters = [];
        $.each(filters, function(index,filter) {
          if (filter[0]!=column)
            newFilters.push(filter);
        });
        if (filters != newFilters) {
          currentRequestVersionNumber++;
          filters = newFilters;
        }
      } else {
        var updated = 0;
        // Try to update existing filter
        $.map(filters, function(filter) {
          if (filter[0]==column) {
            filter[1] = string;
            filter[2] = operator;
            updated = 1;
            return;
          }
        });
        // Add new filter
        if (updated === 0) {
          filters.push([column, string, operator]);
          currentRequestVersionNumber++;
        }
      }
    }

    function addFilter(column, string, operator) {
      addFilterWithoutRefresh(column, string, operator);
      refresh();
    }

    function addFiltersWithoutRefresh(filters) {
      $.each(filters, function(index, filter) {
        addFilterWithoutRefresh(filter[0], filter[1], filter[2]);
      });
    }

    function addFilters(filters) {
      addFiltersWithoutRefresh(filters);
      refresh();
    }

    function getFilters() {
      return filters;
    }

    function setParam(column, string, _refresh) {
      if (_refresh === undefined) _refresh = true;
      // If the string is an empty string, then removing the param if existing
      if (string === '') {
        var newParams = [];
        $.each(params, function(index,param) {
          if (param[0]!=column)
            newParams.push(param);
        });
        if (params != newParams) {
          currentRequestVersionNumber++;
          params = newParams;
        }
        if (_refresh) refresh(); // Only clear if it was found
        return;
      }

      var updated = 0;
      // Try to update existing param
      $.map(params, function(param) {
        if (param[0]==column) {
          param[1] = string;
          updated = 1;
          return;
        }
      });

      // Add new param
      if (updated === 0)
        params.push([column, string]);
        currentRequestVersionNumber++;

      if (_refresh) refresh();
    }

    function getParams() {
      return params;
    }

    function getParam(key) {
      var value = null;
      $.each(params, function(i) {
        if (params[i][0]==key) {
          value = params[i][1];
        }
      });
      return value;
    }

    function setLoadingIndicator(indicator) {
      loadingIndicator = indicator;
    }

    function setMainIndicator(indicator) {
      mainIndicator = indicator;
    }

    function refresh() {
      pagingOptionsChanged = true;
      clear();
      rowsChanged();
    }

    function setPagingOptions(args) {
      pagingOptionsChanged = false;

      if ((args.pageSize !== undefined) && (args.pageSize!=pageSize)) {
        currentRequestVersionNumber++;
        pageSize = args.pageSize;
        pagingOptionsChanged = true;
      }

      var newPageNum = Math.min(args.pageNum, Math.ceil(totalRows / pageSize));

      if ((args.pageNum !== undefined) && (pageNum!=newPageNum)) {
        currentRequestVersionNumber++;
        pageNum = newPageNum;
        pagingOptionsChanged = true;
      }

      // If we click "All" on pager, this is where we are
      if ((args.pageNum === undefined) && (args.pageSize === 0)) {
        currentRequestVersionNumber++;
        pageNum = 0;
        pageSize = 0;
        pagingOptionsChanged = false;
      }

      // Dirty fix for cases where the numbers don't add up
      if (totalRows / pageSize < pageNum) {
        currentRequestVersionNumber++;
        pageNum = 0;
        pagingOptionsChanged = true;
      }

      refresh();
      onPagingInfoChanged.notify(getPagingInfo());
    }

    function getPagingInfo() {
      // Ekohe Edit: Add rowsWithoutFilter
      // return {pageSize:pageSize, pageNum:pageNum, totalRows:totalRows};
      return {
        pageSize: pageSize,
        pageNum: pageNum,
        totalRows: totalRows,
        rowsWithoutFilter: rowsWithoutFilter
      };
    }

    return {
      // properties
      "data": data,
      "oldData": oldData,
      "connectionManager": connectionManager,
      "currentRequestVersionNumber": currentRequestVersionNumber,
      "lastRequestVersionNumber": lastRequestVersionNumber,

      // methods
      "clear": clear,
      "isDataLoaded": isDataLoaded,
      "ensureData": ensureData,
      "reloadData": reloadData,
      "setSort": setSort,
      "setSortWithoutRefresh": setSortWithoutRefresh,
      "getSortColumn": getSortColumn,
      "getSortDirection": getSortDirection,
      "getFilters": getFilters,
      "setFilterWithoutRefresh": setFilterWithoutRefresh,
      "setFilter": setFilter,
      "addFilterWithoutRefresh": addFilterWithoutRefresh,
      "addFilter": addFilter,
      "addFiltersWithoutRefresh": addFiltersWithoutRefresh,
      "addFilters": addFilters,
      "getParams": getParams,
      "getParam": getParam,
      "setParam": setParam,
      "setGrid": setGrid,
      "conditionalURI": conditionalURI,
      'getColumns': getColumns,

      // events
      "beforeRemoteRequest": beforeRemoteRequest,
      "onDataLoading": onDataLoading,
      "onPagingInfoChanged":  onPagingInfoChanged,
      "onDataLoaded": onDataLoaded,

      // pager
      "getPagingInfo": getPagingInfo,
      "setPagingOptions": setPagingOptions,

      "setLoadingIndicator": setLoadingIndicator,
      "setMainIndicator": setMainIndicator
    };
  }

  // WulinMaster.Data.RemoteModel
  $.extend(true, window, { WulinMaster: { Data: { RemoteModel: RemoteModel }}});
})(jQuery);
