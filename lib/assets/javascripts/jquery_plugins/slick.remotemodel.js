/***
 * A simple observer pattern implementation.
 */
function EventHelper() {
	this.handlers = [];

	this.subscribe = function(fn) {
    this.handlers.push(fn);
  };

	this.notify = function(args) {
    for (var i = 0; i < this.handlers.length; i++) {
      this.handlers[i].call(this, args);
    }
  };

	return this;
}

// find keys in a js hash object
function getKeys(h) {
  var keys = new Array();
  for (var key in h)
    keys.push(key);
  return keys;
}


(function($) {
	function RemoteModel(path, columns) {
		// private
		var loadingSize = 200;
		var preemptiveLoadingSize = 100;
		var pageSize = 0;
		var pageNum = 0;
		var totalRows = 0;
		var data = {length:0};
		var sortcol = null;
		var sortdir = 1;
		var h_request = null;
		var req = null; // ajax request
		var req_page;
		var filters = [];
		var params = [];
    var pagingOptionsChanged = false;
    var grid;
    var loadingIndicator = null;
    var mainIndicator = null;
    
    // Connection manager
    var connectionManager = new ConnectionManager();
    
    
		// events
		var onDataLoading = new EventHelper();
    var onPagingInfoChanged = new EventHelper();
    var onDataLoaded = new EventHelper();

    function setGrid(newGrid) {
      grid = newGrid;
      
      //  Connect the grid and the loader
      grid.onViewportChanged = function() {
        var vp = grid.getViewport();
        
        ensureData(vp.top, vp.bottom);
      };

      grid.onSort = function(sortCol, sortAsc) {
        setSort(sortCol.field, sortAsc ? 1 : -1);
      };
    }
    
    function rowsChanged() {
      var vp = grid.getViewport();
      ensureData(vp.top, vp.bottom);
    }
    
    function dataIsLoaded(args) {
      for (var i = args.from; i <= args.to; i++) {
        grid.removeRow(i);
      }

      grid.updateRowCount();
      grid.render();
      
      onDataLoaded.notify();
    }

		function isDataLoaded(from,to) {
			for (var i=from; i<=to; i++) {
				if (data[i] == undefined || data[i] == null)
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

      if (count==0) {
        // Nothing to load, try to see if there is a need to load data preemptively
        paginationOptions = getPaginationOptions(from-preemptiveLoadingSize, to+preemptiveLoadingSize);
        offset = paginationOptions[0];
        count = paginationOptions[1];

        if (count==0) {
          // the current data on the view is loaded and no preemptive loading to do
          return null;
        }
        
        // Preemptive loading mode
        normalLoadingMode = false;
      }
      var url = path+".json?offset="+offset+"&count="+count;
      
      // filters, ordering, extra parameters - not specific to the viewport
      url += conditionalURI();
      
      return [url, normalLoadingMode];
    }
    
    function conditionalURI() {
      // Sorting
      if (sortcol==null) {
        sortcol = "";
      } 
      
      var url = "&sort_col="+sortcol;
      if (sortdir>0) {
        url += "&sort_dir=ASC";
      } else {
        url += "&sort_dir=DESC";
      }

      // Filters
      $.each(filters, function(index, value) {
        url += "&filters[][column]="+value[0]+"&filters[][value]="+value[1];
      });

      // Parameters
      $.each(params, function(index, value) {
        url += "&"+value[0]+"="+value[1];
      });
      
      return url;
    }
    
    // Returns offset, count
    function getPaginationOptions(from, to) {
      // 2 cases, whether we are in load-as-scroll mode or the per page mode
      if (pageSize==0) {
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

  			if (fromPage > toPage || ((fromPage == toPage) && data[fromPage*loadingSize] !== undefined)) {
          return [0,0];
  			}
      
        for (var i=fromPage; i<=toPage; i++)
          data[i*loadingSize] = null; // null indicates a 'requested but not available yet'

        return [(fromPage * loadingSize), (((toPage - fromPage) * loadingSize) + loadingSize)];
      } else {
        // Per page
        if (pagingOptionsChanged==false) {
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
		  if(urlData == null) { return; }
		  
      var url = urlData[0];      
      var normalLoading = urlData[1];
            
      // Store loading size to provide stats. If pageSize is not zero then we are coming from a pager request.
      loadingIndicator.loadingSize = pageSize == 0 ? loadingSize : pageSize;
      connectionManager.createConnection(url, loadingIndicator, onSuccess, onError);
		}


		function onError(request, textStatus, errorThrown) {
      //
		}

		function onSuccess(resp, textStatus, request) {
		  var from;
		  var to;
		  
			if (pageSize==0) {
			  from = resp.offset;
			  to = resp.offset + resp.count;
        data.length = parseInt(resp.total);
	    } else {
			  from = 0;
			  to = parseInt(resp.count);
	      data.length = to;
	    }
	    
	    totalRows = parseInt(resp.total);
			for (var i = 0; i < resp.rows.length; i++) {
			  var j = parseInt(from)+parseInt(i);
			  var object = {};
			  $.each(columns, function(index, value) {
			    // match the column and the response data (compare column name and response data key)
			    for(k in resp.rows[i]){
			      var key = getKeys(resp.rows[i][k])[0];
			      if(value.id == key){
			        object[value.id] = resp.rows[i][k][key]
		          break;
		        }
			    }          
			  });
				data[j] = object;
				data[j].slick_index = j;
			}
      
			req = null;
			
      // Loading data
			dataIsLoaded({from:from, to:to});

			// Updating pager
			onPagingInfoChanged.notify(getPagingInfo());			
		}
    

		function reloadData(from,to) {
			for (var i=from; i<=to; i++)
				delete data[i];

			ensureData(from,to);
		}


		function setSort(column,dir) {
			sortcol = column;
			sortdir = dir;
			refresh();
		}
		
		function getSortColumn() {
		  return sortcol;
		}

    function getSortDirection() {
      return sortdir;
    }

		function setFilter(column, string) {
		  // If the string is an empty string, then removing the filter if existing
			if (string=='') {
			  var newFilters = [];
			  $.each(filters, function(index,filter) {
			    if (filter[0]!=column)
			      newFilters.push(filter);
			  });
			  filters = newFilters;
	      refresh(); // Only clear if it was found
			  return;
			}
						
      var updated = 0;
      // Try to update existing filter
		  $.map(filters, function(filter) {
		    if (filter[0]==column) {
	        filter[1] = string;
	        updated = 1;
	        return;
		    }
		  });
		  
		  // Add new filter
		  if (updated==0)
  		  filters.push([column, string]);
		
			refresh();
  	}
  	
  	function getFilters() {
  	  return filters;
  	}

		function setParam(column, string) {
		  // If the string is an empty string, then removing the param if existing
			if (string=='') {
			  var newParams = [];
			  $.each(params, function(index,param) {
			    if (param[0]!=column)
			      newParams.push(param);
			  });
			  params = newParams;
	      refresh(); // Only clear if it was found
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
		  if (updated==0)
  		  params.push([column, string]);
		
			refresh();
  	}

  	function getParams() {
  	  return params;
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
      if ((args.pageSize != undefined) && (args.pageSize!=pageSize)) {
        pageSize = args.pageSize;
        pagingOptionsChanged = true;
      }
      
      var newPageNum = Math.min(args.pageNum, Math.ceil(totalRows / pageSize));
      
      if ((args.pageNum != undefined) && (pageNum!=newPageNum)) {
        pageNum = newPageNum;
        pagingOptionsChanged = true;
      }
      
      // If we click "All" on pager, this is where we are
      if ((args.pageNum == undefined) && (args.pageSize == 0)) {
        pageNum = 0;
        pageSize = 0;
        pagingOptionsChanged = false;
      }
      
      // Dirty fix for cases where the numbers don't add up
      if (totalRows / pageSize < pageNum) {
        pageNum = 0
        pagingOptionsChanged = true;
      }
      
		  refresh();
      onPagingInfoChanged.notify(getPagingInfo());      
    }

    function getPagingInfo() {
      return {pageSize:pageSize, pageNum:pageNum, totalRows:totalRows};
    }

		return {
			// properties
			"data": data,
      "connectionManager": connectionManager,
      
			// methods
			"clear": clear,
			"isDataLoaded": isDataLoaded,
			"ensureData": ensureData,
			"reloadData": reloadData,
			"setSort": setSort,
			"getSortColumn": getSortColumn,
			"getSortDirection": getSortDirection,
			"getFilters": getFilters,
			"setFilter": setFilter,
			"getParams": getParams,
			"setParam": setParam,
			"setGrid": setGrid,
      "conditionalURI": conditionalURI,
      
			// events
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

	// Slick.Data.RemoteModel
	$.extend(true, window, { Slick: { Data: { RemoteModel: RemoteModel }}});
})(jQuery);
