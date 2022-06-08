/***
 * A plugin to add row detail panel
 * Original StackOverflow question & article making this possible (thanks to violet313)
 * https://stackoverflow.com/questions/10535164/can-slickgrids-row-height-be-dynamically-altered#29399927
 * http://violet313.org/slickgrids/#intro
 *
 *
 * USAGE:
 *
 * Add the slick.rowDetailView.(js|css) files and register the plugin with the grid.
 *
 * AVAILABLE ROW DETAIL OPTIONS:
 *    cssClass:         A CSS class to be added to the row detail
 *    loadOnce:         Booleang flag, when True will load the data once and then reuse it.
 *    preTemplate:      Template that will be used before the async process (typically used to show a spinner/loading)
 *    postTemplate:     Template that will be loaded once the async function finishes
 *    process:          Async server function call
 *    panelRows:        Row count to use for the template panel
 *    useRowClick:      Boolean flag, when True will open the row detail on a row click (from any column), default to False
 *
 * AVAILABLE PUBLIC OPTIONS:
 *    init:                 initiliaze the plugin
 *    destroy:              destroy the plugin and it's events
 *    collapseAll:          collapse all opened row detail panel
 *    getColumnDefinition:  get the column definitions
 *    getOptions:           get current plugin options
 *    setOptions:           set or change some of the plugin options
 *
 * THE PLUGIN EXPOSES THE FOLLOWING SLICK EVENTS:
 *    onAsyncResponse:  This event must be used with the "notify" by the end user once the Asynchronous Server call returns the item detail
 *       Event args:
 *          itemDetail: Item detail returned from the async server call
 *          detailView:  An explicit view to use instead of template (Optional)
 *
 *    onAsyncEndUpdate: Fired when the async response finished
 *       Event args:
 *         grid:        Reference to the grid.
 *         itemDetail:  Column definition.
 *
 *    onBeforeRowDetailToggle: Fired before the row detail gets toggled
 *       Event args:
 *         grid:        Reference to the grid.
 *         item:  Column definition.
 *
 *    onAfterRowDetailToggle: Fired after the row detail gets toggled
 *       Event args:
 *         grid:        Reference to the grid.
 *         item:  Column definition.
 *
 */

 /*
  * Ekohe fork:
  *
  * 1. Change to deal with Ekohe version of remotemodel instead dataviw
  * 2. Make showing trigger column optional
  * 3. Add the feature to handle if we could hide the original row
  */

(function ($) {
  // register namespace
  $.extend(true, window, {
    "Slick": {
      "Plugins": {
        "RowDetailView": RowDetailView
      }
    }
  });

  function RowDetailView(options) {
    var _grid;
    var _self = this;
    var _expandedRows = [];
    var _handler = new Slick.EventHandler();

    var _defaults = {
      columnId: "_detail_selector",
      cssClass: null,
      toolTip: "",
      hideRow: false, // Ekohe Add
      width: 30
    };

    // Ekohe Add
    var _dataView = {
      getIdxById: function(id) {
        return parseInt($.grep(Object.keys(this), function(key) {
          return this[key] && typeof this[key] === 'object' && 'id' in this[key] && this[key].id === id;
        }.bind(this))[0]);
      },
      getItem: function(row) {
        return this[row];
      },
      insertItem: function(idx, content) {
        this[idx] = content;
      },
      updateItem: function(id, item) {
        this[this.getIdxById(id)] = item;
        this.refresh();
      },
      deleteItem: function(id) {
        delete this[this.getIdxById(id)];
      },
      refresh: function() {
        _grid.setData(this);
        _grid.render();
      }
    };

    var _options = $.extend(true, {}, _defaults, options);

    function init(grid) {
      _grid = grid;
      // Ekohe Delete
      // _dataView = _grid.getData();

      // Update the minRowBuffer so that the view doesn't disappear when it's at top of screen + the original default 3
      _grid.getOptions().minRowBuffer = _options.panelRows + 3;

      _handler
        .subscribe(_grid.onClick, delayToHandleClick)
        // Ekohe Delete: scroll/sort works well with Ekohe version remotemodel. no need to handle here
        // .subscribe(_grid.onSort, handleSort)
        // .subscribe(_grid.onScroll, handleScroll);

      // Ekohe Detete: dataview not in use
      // _grid.getData().onRowCountChanged.subscribe(function () { _grid.updateRowCount(); _grid.render(); });
      // _grid.getData().onRowsChanged.subscribe(function (e, a) { _grid.invalidateRows(a.rows); _grid.render(); });

      // Ekohe Add: Use remotemodel
      _grid.loader.onDataLoaded.subscribe(function (e, a) {
        var oldMaxIdx = getMaxIdx(_dataView);
        var maxIdx = getMaxIdx(_grid.getData());

        $.extend(_dataView, _grid.getData());
        // if (_grid.loader.getFilters().length === 0) { collapseAll(); }
        // _expandedRows = [];

        // Remove element which over than new Data's length
        for (var idx = maxIdx + 1; idx <= oldMaxIdx; idx++) {
          delete _dataView[idx];
        }

        // Restore expanded item when new data appended
        if (oldMaxIdx < maxIdx) {
          for (var i = _expandedRows.length - 1; i >= 0; i--) {
            applyTemplateNewLineHeight(_expandedRows[i]);
            _dataView.refresh();
          }
        }
      });

      // subscribe to the onAsyncResponse so that the plugin knows when the user server side calls finished
      subscribeToOnAsyncResponse();
    }

    function destroy() {
      _handler.unsubscribeAll();
      _self.onAsyncResponse.unsubscribe();
      _self.onAsyncEndUpdate.unsubscribe();
      _self.onAfterRowDetailToggle.unsubscribe();
      _self.onBeforeRowDetailToggle.unsubscribe();
    }

    function getOptions(options) {
      return _options;
    }

    function setOptions(options) {
      _options = $.extend(true, {}, _options, options);
    }

    // Ekohe Add: Detect max idx of _dataView/getData()
    function getMaxIdx(data) {
      return parseInt(Object.keys(data).reverse().find(function(idx) {
        return (/\d+/.test(idx) && data[idx]);
      })) || 0;
    }

    // Ekohe Add: Support to dblClick to edit and just click to expand rowDetail
    function delayToHandleClick(e, args) {
      var isEditing = args.grid.isEditing
      var delay = 200
      var fn = function () { !isEditing() && handleClick(e, args) }

      if (!isEditing()) {
        setTimeout(fn, delay)
      }
    }

    function handleClick(e, args) {
      // clicking on a row select checkbox
      // Ekohe Edit
      // if (_options.useRowClick || _grid.getColumns()[args.cell].id === _options.columnId && $(e.target).hasClass("detailView-toggle")) {
      if (_options.useRowClick || _grid.getColumns()[args.cell].id === _options.columnId && $(e.target).parent().hasClass('detailView-toggle')) {
        // Disable show detail if some rows is select. Because the detail will add 3 rows. Which will make grid.getSelectedRows() can't get right select rows
        // And should disable show detail and show alert if we are clicking on checkbox
        if (_grid.getSelectedRows().length > 0 && _grid.getColumns()[args.cell].id != '_checkbox_selector') {
          M.toast({html: "Can't show detail when checkbox is selected.", displayLength: 5000})
        }
        var disableDetail = _grid.getSelectedRows().length > 0 || _grid.getColumns()[args.cell].id === '_checkbox_selector';
        // if editing, try to commit
        if (disableDetail || (_grid.getEditorLock().isActive() && !_grid.getEditorLock().commitCurrentEdit()) ) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return;
        }

        var item = _dataView.getItem(args.row);

        // trigger an event before toggling
        _self.onBeforeRowDetailToggle.notify({
          "grid": _grid,
          "item": item
        }, e, _self);

        toggleRowSelection(item);

        // trigger an event after toggling
        _self.onAfterRowDetailToggle.notify({
          "grid": _grid,
          "item": item
        }, e, _self);

        e.stopPropagation();
        e.stopImmediatePropagation();
      }
    }

    // Sort will just collapse all of the open items
    function handleSort(e, args) {
      collapseAll();
    }

    // If we scroll save detail views that go out of cache range
    function handleScroll(e, args) {

      var range = _grid.getRenderedRange();

      var start = (range.top > 0 ? range.top : 0);
      var end = (range.bottom > _dataView.getLength() ? range.bottom : _dataView.getLength());

      // Get the item at the top of the view
      var topMostItem = _dataView.getItemByIdx(start);

      // Check it is a parent item
      if (topMostItem && topMostItem._parent == undefined)
      {
        // This is a standard row as we have no parent.
        var nextItem = _dataView.getItemByIdx(start + 1);
        if(nextItem !== undefined && nextItem._parent !== undefined)
        {
          // This is likely the expanded Detail Row View
          // Check for safety
          if(nextItem._parent == topMostItem)
          {
            saveDetailView(topMostItem);
          }
        }
      }

      // Find the bottom most item that is likely to go off screen
      var bottomMostItem = _dataView.getItemByIdx(end - 1);

      // If we are a detailView and we are about to go out of cache view
      if (bottomMostItem && bottomMostItem._parent !== undefined)
      {
        saveDetailView(bottomMostItem._parent);
      }
    }

    // Toggle between showing and hiding a row
    function toggleRowSelection(row) {
      // Edit Delete
      // _grid.getData().beginUpdate();
      HandleAccordionShowHide(row);
      // Edit Delete
      // _grid.getData().endUpdate();
    }

    // Collapse all of the open items
    function collapseAll() {
      for (var i = _expandedRows.length - 1; i >= 0; i--) {
        collapseItem(_expandedRows[i]);
      }
    }

    // Saves the current state of the detail view
    function saveDetailView(item)
    {
      var view = $("#innerDetailView_" + item.id);
      if (view)
      {
        var html = $("#innerDetailView_" + item.id).html();
        if(html !== undefined)
        {
          item._detailContent = html;
        }
      }
    }

    // Colapse an Item so it is notlonger seen
    function collapseItem(item) {

      // Save the details on the collapse assuming onetime loading
      if (_options.loadOnce) {
        saveDetailView(item);
      }

      // Ekohe Edit: Check if there is really expanded
      var isReallyExpanded = true;
      for (var idx = 1; idx <= item._sizePadding; idx++) {
        var itemId = item.id + "." + idx;

        if (_dataView.getIdxById(itemId)) {
          _dataView.deleteItem(itemId);
        } else {
          isReallyExpanded = false;
        }
      }

      // Ekohe Add: Change the index of the remained items
      if (isReallyExpanded) {
        var idxParent = _dataView.getIdxById(item.id);
        var remainedItems = {};
        var maxIdx = getMaxIdx(_dataView);
        for (var idx = idxParent + item._sizePadding + 1; idx <= maxIdx; idx++) {
          remainedItems[idx - item._sizePadding] = _dataView[idx];
          delete _dataView[idx];
        }

        // Ekohe Add: Refresh the dataview
        $.extend(_dataView, remainedItems);
        _dataView.length -= item._sizePadding;
      }

      item._collapsed = true;
      item._sizePadding = 0;

      _dataView.updateItem(item.id, item);

      // Remove the item from the expandedRows
      _expandedRows = _expandedRows.filter(function (r) {
        return r.id !== item.id;
      });
    }

    // Expand a row given the dataview item that is to be expanded
    function expandItem(item) {
      item._collapsed = false;
      _expandedRows.push(item);

      // In the case something went wrong loading it the first time such a scroll of screen before loaded
      if (!item._detailContent) item._detailViewLoaded = false;

      // display pre-loading template
      if (!item._detailViewLoaded || _options.loadOnce !== true) {
        // Ekohe Edit: Use attribute instead of method so that template can be defined in wulin master's gird
        // item._detailContent = _options.preTemplate(item);
        item._detailContent = _options.preTemplate;
      } else {
        _self.onAsyncResponse.notify({
          "itemDetail": item,
          "detailView": item._detailContent
        }, undefined, this);
        applyTemplateNewLineHeight(item);
        _dataView.updateItem(item.id, item);

        return;
      }

      applyTemplateNewLineHeight(item);
      _dataView.updateItem(item.id, item);

      // Ekohe Add: Expand rowDetailView panel width
      $('.slick-pane-left').css('overflow', 'visible');
      $('.grid-canvas-left').css('position', 'absolute');

      // async server call
      _options.process(item);
    }

    /**
     * subscribe to the onAsyncResponse so that the plugin knows when the user server side calls finished
     * the response has to be as "args.itemDetail" with it's data back
     */
    function subscribeToOnAsyncResponse() {
      _self.onAsyncResponse.subscribe(function (e, args) {
        if (!args || !args.itemDetail) {
          throw 'Slick.RowDetailView plugin requires the onAsyncResponse() to supply "args.itemDetail" property.'
        }

        // If we just want to load in a view directly we can use detailView property to do so
        if (args.detailView) {
          args.itemDetail._detailContent = args.detailView;
        } else {
          args.itemDetail._detailContent = _options.postTemplate(args.itemDetail);
        }

        args.itemDetail._detailViewLoaded = true;

        var idxParent = _dataView.getIdxById(args.itemDetail.id);
        _dataView.updateItem(args.itemDetail.id, args.itemDetail);

        // trigger an event once the post template is finished loading
        _self.onAsyncEndUpdate.notify({
          "grid": _grid,
          "itemDetail": args.itemDetail
        }, e, _self);
      });
    }

    function HandleAccordionShowHide(item) {
      if (item) {
        // Ekohe Edit: expandItem when item._collapsed == null
        // if (!item._collapsed) {
        if (item._collapsed === false) {
          collapseItem(item);
        } else {
          // Ekohe Add
          collapseAll();

          expandItem(item);
        }
      }
    }

    //////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////
    var getPaddingItem = function (parent, offset) {
      var item = {};

      // Ekohe Edit
      // for (var prop in _grid.getData()) {
      for (var prop in parent) {
        item[prop] = null;
      }

      item.id = parent.id + "." + offset;

      //additional hidden padding metadata fields
      item._collapsed = true;
      item._isPadding = true;
      item._parent = parent;
      item._offset = offset;

      return item;
    }

    //////////////////////////////////////////////////////////////
    //create the detail ctr node. this belongs to the dev & can be custom-styled as per
    //////////////////////////////////////////////////////////////
    function applyTemplateNewLineHeight(item) {
      // the height seems to be calculated by the template row count (how many line of items does the template have)
      var rowCount = _options.panelRows;

      //calculate padding requirements based on detail-content..
      //ie. worst-case: create an invisible dom node now &find it's height.
      var lineHeight = 13; //we know cuz we wrote the custom css innit ;)
      item._sizePadding = Math.ceil(((rowCount * 2) * lineHeight) / _grid.getOptions().rowHeight);
      item._height = (item._sizePadding * _grid.getOptions().rowHeight);

      var idxParent = _dataView.getIdxById(item.id);

      // Ekohe Add: Change the index of the remained items
      var remainedItems = {};
      var maxIdx = getMaxIdx(_dataView);
      for (var idx = idxParent + 1; idx <= maxIdx; idx++) {
        remainedItems[idx + item._sizePadding] = _dataView[idx];
        delete _dataView[idx];
      }

      // Add fake items
      for (var idx = 1; idx <= item._sizePadding; idx++) {
        _dataView.insertItem(idxParent + idx, getPaddingItem(item, idx));
      }

      // Ekohe Add: Create new data by combining the fake items and remainedItems
      $.extend(_dataView, remainedItems);
      _dataView.length += item._sizePadding;
    }

    function getColumnDefinition() {
      return {
        id: _options.columnId,
        name: "",
        toolTip: _options.toolTip,
        field: "sel",
        width: _options.width,
        resizable: false,
        sortable: false,
        cssClass: _options.cssClass,
        formatter: detailSelectionFormatter
      };
    }

    function detailSelectionFormatter(row, cell, value, columnDef, dataContext) {

      if (dataContext._collapsed == undefined) {
        dataContext._collapsed = true,
        dataContext._sizePadding = 0,     //the required number of pading rows
        dataContext._height = 0,     //the actual height in pixels of the detail field
        dataContext._isPadding = false,
        dataContext._parent = undefined,
        dataContext._offset = 0
      }

      if (dataContext._isPadding == true) {
        //render nothing
      } else if (dataContext._collapsed) {
        // Ekohe Edit: Use Material Icons
        // return "<div class='detailView-toggle expand'></div>";
        if (columnDef.rowDetailIconVisible !== false) {
          return "<div class='detailView-toggle expand'><i class='material-icons'>add_circle_outline</i></div>";
        }
      } else {
        var html = [];
        var rowHeight = _grid.getOptions().rowHeight;
        var bottomMargin = 5;

        // Ekohe Add
        var hideRow = _options.hideRow;

        //V313HAX:
        //putting in an extra closing div after the closing toggle div and ommiting a
        //final closing div for the detail ctr div causes the slickgrid renderer to
        //insert our detail div as a new column ;) ~since it wraps whatever we provide
        //in a generic div column container. so our detail becomes a child directly of
        //the row not the cell. nice =)  ~no need to apply a css change to the parent
        //slick-cell to escape the cell overflow clipping.

        //sneaky extra </div> inserted here-----------------v

        // Ekohe Edit: Use Material Icons
        // html.push("<div class='detailView-toggle collapse'></div></div>");
        if (columnDef.rowDetailIconVisible !== false) {
          html.push("<div class='detailView-toggle collapse'><i class='material-icons'>remove_circle_outline</i></div>");
        }
        html.push("</div>");

        html.push("<div id='cellDetailView_", dataContext.id, "' class='dynamic-cell-detail' ");   //apply custom css to detail

        // Ekohe Edit: Rewrite detail Panel height
        //  1. Set total height of padding
        //  2. Shift detail below 1st row
        //  3. Set the max-height

        // html.push("style='height:", dataContext._height, "px;"); //set total height of padding
        // html.push("top:", rowHeight, "px'>");             //shift detail below 1st row
        // html.push("<div id='detailViewContainer_", dataContext.id, "'  class='detail-container' style='max-height:" + (dataContext._height - rowHeight + bottomMargin) + "px'>"); //sub ctr for custom styling

        if (hideRow == true) {
          html.push("style='height:", dataContext._height + rowHeight, "px;");
          html.push("top: 0px'>");
          var detailViewHeight = (dataContext._height + bottomMargin);
        } else {
          html.push("style='height:", dataContext._height, "px;");
          html.push("top:", rowHeight, "px'>");
          var detailViewHeight = (dataContext._height - rowHeight + bottomMargin);
        }
        html.push("<div id='detailViewContainer_", dataContext.id, "'  class='detail-container' style='max-height:" + detailViewHeight + "px'>");

        html.push("<div id='innerDetailView_" , dataContext.id , "'>" , dataContext._detailContent, "</div></div>");
        // &omit a final closing detail container </div> that would come next

        return html.join("");
      }
      return null;
    }

    function resizeDetailView(item) {
      if (!item) return;

      // Grad each of the dom items
      var mainContainer = document.getElementById('detailViewContainer_' + item.id);
      var cellItem = document.getElementById('cellDetailView_' + item.id);
      var inner = document.getElementById('innerDetailView_' + item.id);

      if (!mainContainer || !cellItem || !inner) return;

      for (var idx = 1; idx <= item._sizePadding; idx++) {
        _dataView.deleteItem(item.id + "." + idx);
      }

      var rowHeight = _grid.getOptions().rowHeight; // height of a row
      var lineHeight = 13; //we know cuz we wrote the custom css innit ;)

      // Get the inner Item height as this will be the actual size
      var itemHeight = inner.clientHeight;

      // Now work out how many rows
      var rowCount = Math.ceil(itemHeight / rowHeight) + 1;

      item._sizePadding = Math.ceil(((rowCount * 2) * lineHeight) / rowHeight);
      item._height = (item._sizePadding * rowHeight);

      // If the padding is now more than the original minRowBuff we need to increase it
      if (_grid.getOptions().minRowBuffer < item._sizePadding)
      {
        // Update the minRowBuffer so that the view doesn't disappear when it's at top of screen + the original default 3
        _grid.getOptions().minRowBuffer =item._sizePadding + 3;
      }

      mainContainer.setAttribute("style", "max-height: " + item._height + "px");
      if (cellItem) cellItem.setAttribute("style", "height: " + item._height + "px;top:" + rowHeight + "px");

      var idxParent = _dataView.getIdxById(item.id);
      for (var idx = 1; idx <= item._sizePadding; idx++) {
        _dataView.insertItem(idxParent + idx, getPaddingItem(item, idx));
      }
    }

    //////////////////////////////////////
    // Ekohe Add: Customized Getter/Setter

    function setPanelRows(panelRows) {
      _options.panelRows = panelRows;
    }

    $.extend(this, {
      "init": init,
      "destroy": destroy,
      "collapseAll": collapseAll,
      "getColumnDefinition": getColumnDefinition,
      "getOptions": getOptions,
      "setOptions": setOptions,
      "onAsyncResponse": new Slick.Event(),
      "onAsyncEndUpdate": new Slick.Event(),
      "onAfterRowDetailToggle": new Slick.Event(),
      "onBeforeRowDetailToggle": new Slick.Event(),
      "resizeDetailView": resizeDetailView,

      // Ekohe Add
      'setPanelRows': setPanelRows
    });
  }
})(jQuery);
