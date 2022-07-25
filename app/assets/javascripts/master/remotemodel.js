// Remote model with pagination

(function($) {
  function RemoteModel(path, initialFilters, columns) {
    // private
    var loadingSize = 200;
    var preemptiveLoadingSize = 100;
    var pageSize = 0;
    var pageNum = 0;
    var totalRows = 0;
    var aggregation = ''; // Ekohe Add
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

      // Connect the grid and the loader
      grid.onViewportChanged.subscribe(function(e, args) {
        var vp = grid.getViewport();
        // when the grid rendered, onViewportChanged will be triggerd, if eagerLoading is false and no data loaded yet, we don't load the initial data
        if(grid.options.eagerLoading === false && grid.getData().length === 0) return false;
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

      // Reset data since data is not updated automatically when row detail view added
      grid.setData(args.data);

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

      var url = path + "&offset=" + offset + "&count=" + count;

      // filters, ordering, extra parameters - not specific to the viewport
      url += conditionalURI();

      // Decide which columns will be queried
      //  Add new params[:columns]
      url += appendVisibleColumnsListToURL();

      return [url, normalLoadingMode];
    }

    function generateFindByIDsUrl(ids) {

      var url = path + "&checkbox_record_ids=" + ids.join()

      // filters, ordering, extra parameters - not specific to the viewport
      url += conditionalURI()

      // Decide which columns will be queried
      //  Add new params[:columns]
      url += appendVisibleColumnsListToURL()

      return url
    }

    function appendVisibleColumnsListToURL() {
      return '&columns=' + visibleColumnNames();
    }

    function visibleColumnNames() {
      var columnNames = [];

      $.each(grid.allColumns, function (_, column) {
        if (column['column_name'] !== undefined) {
          columnNames.push(column['column_name']);
        }
      });
      return columnNames;
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

        if (fromPage > toPage) {
          return [0,0];
        }

        var alreadyLoaded = true;

        for (var i=fromPage; i<=toPage; i++) {
          if (typeof(data[i*loadingSize]) == 'undefined') {
            alreadyLoaded = false;
          }
        }

        if (alreadyLoaded) {
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

    function ensureData(from, to) {
      // Event triggered before the ajax request
      // Ekohe Edit: Move it from onViewportChanged subscribing in setGrid to here,
      // beforeRemoteRequest hook may need to run before every ajax request
      beforeRemoteRequest.notify();

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

      // Ekohe Add: Save row length without filter
      rowsWithoutFilter = parseInt(resp.totalNoFilter, 10);

      // Load as we scroll
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
      aggregation = resp['aggregation'] || '';

      // Exclude detail selector from columns
      var detailSelector = $.grep(columns, function(c) { return c.id === '_detail_selector' })[0];
      var indexDetailSelector = columns.indexOf(detailSelector);
      if (indexDetailSelector > -1) { columns.splice(indexDetailSelector, 1); }

      if (resp.rows) {
        if (resp.rows.length < loadingSize) {
          data[from+loadingSize] = null;
        }
        for (var i = 0; i < resp.rows.length; i++) {
          var j = parseInt(from, 10) + parseInt(i, 10);
          var obj = {};
          // If we used checkbox, the index will increase by 1, we should get the item by adjust the indexOffset
          var indexOffset = 0
          if (grid.getOptions().checkbox.enable) {
            indexOffset = 1 // start from column after checkbox
          }
          $.each(columns, function(index, value) {
            // checkbox don't need value
            if (value.id != "_checkbox_selector") {
              var item = resp.rows[i][index - indexOffset]
              // match the column and the response data (compare column name and response data key)
              if (item && typeof item == "object" && !(item instanceof Array)) {
                $.extend(true, obj, item)
              } else {
                obj[value.id] = item
              }
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
      dataIsLoaded({from:from, to:to, data:data});

      // Updating pager
      onPagingInfoChanged.notify(getPagingInfo());
    }

    function onFindByIDsSuccess(resp, textStatus, request) {
      // Exclude detail selector from columns
      const detailSelector = $.grep(columns, function(c) {
        return c.id === "_detail_selector"
      })[0]
      const indexDetailSelector = columns.indexOf(detailSelector)
      if (indexDetailSelector > -1) {
        columns.splice(indexDetailSelector, 1)
      }

      if (resp.rows) {
        for (var i = 0; i < resp.rows.length; i++) {
          const obj = {}
          var indexOffset = 0
          if (grid.getOptions().checkbox.enable) {
            indexOffset = 1 // start from column after checkbox
          }
          $.each(columns, function(index, value) {
            if (value.id != "_checkbox_selector") {
              const item = resp.rows[i][index - indexOffset]
              // match the column and the response data (compare column name and response data key)
              if (item && typeof item == "object" && !(item instanceof Array)) {
                $.extend(true, obj, item)
              } else {
                obj[value.id] = item
              }
            }
          })
          const j = Object.values(data).findIndex((row) => row.id === obj.id)
          if (j != null) {
            data[j] = obj
            data[j].slick_index = j
            // Loading data
            grid.invalidateRow(j)
          }
        }
      }

      // keep oldData as a clone of data, never get deleted
      this.loader.oldData = deep_clone(data)

      // Reset data since data is not updated automatically when row detail view added
      grid.setData(data)

      grid.render()

      onDataLoaded.notify()
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

    function reloadRowsByIds(ids) {
      beforeRemoteRequest.notify()

      var url = generateFindByIDsUrl(ids)

      connectionManager.createConnection(
        grid,
        url,
        loadingIndicator,
        onFindByIDsSuccess,
        onError,
        currentRequestVersionNumber
      )
    }

    function removeRowsByIds(ids) {
      for (var i = 0; i < ids.length; i++) {
        var index = grid.getRowByRecordId(ids[i]).index
        delete data[index]
        grid.invalidateRow(index)
        totalRows -= 1
      }
      new_data = {}
      j = 0
      for (i = 0; i < data.length; i++) {
        if (data[i]) {
          new_data[j] = data[i]
          j++
        }
      }
      new_data.length = j
      new_data.getItemMetadata = data.getItemMetadata
      // loader.oldData should also update because getDataItem() in render() will get data from it
      grid.loader.oldData = new_data
      data = new_data

      // Reset data since data is not updated automatically when row detail view added
      grid.setData(new_data)

      grid.updateRowCount()

      grid.render()

      onDataLoaded.notify()
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
        rowsWithoutFilter: rowsWithoutFilter,
        aggregation,
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
      "reloadRowsByIds": reloadRowsByIds,
      "removeRowsByIds": removeRowsByIds,
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
