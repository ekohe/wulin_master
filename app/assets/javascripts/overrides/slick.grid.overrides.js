// All the slick grid overrides located here
Slick.OldGrid = Slick.Grid;
Slick.Grid = function() {
  Slick.OldGrid.apply(this, arguments);
  
  this.isEditing = function (){
    return this.currentEditor != null;
  };

  this.getRows = function () {
    return this.rowsCache;
  };

  this.getRowAt = function(i){
    return this.rowsCache[i];
  };
  
  delete this.updateRowCount;
  
  this.updateRowCount =  function() {
    var newRowCount = this.gridDataGetLength() + (this.options.enableAddRow?1:0) + (this.options.leaveSpaceForNewRows?numVisibleRows-1:0);
    var oldH = h;

    // remove the rows that are now outside of the data range
    // this helps avoid redundant calls to .removeRow() when the size of the data decreased by thousands of rows
    var l = this.options.enableAddRow ? this.gridDataGetLength() : this.gridDataGetLength() - 1;
    for (var i in rowsCache) {
        if (i >= l) {
            this.removeRowFromCache(i);
        }
    }
    // hack for terra nova, 2011.09.09
    var hasHorizontalBar = ($viewport[0].scrollWidth != $viewport[0].clientWidth);
    th = Math.max(this.options.rowHeight * newRowCount, this.viewportH - (hasHorizontalBar ? scrollbarDimensions.height : 0));
    if (th < this.maxSupportedCssHeight) {
        // just one page
        h = ph = th;
        n = 1;
        cj = 0;
    }
    else {
        // break into pages
        h = this.maxSupportedCssHeight;
        ph = h / 100;
        n = Math.floor(th / ph);
        cj = (th - h) / (n - 1);
    }

    if (h !== oldH) {
        $canvas.css("height",h);
        scrollTop = $viewport[0].scrollTop;
    }

    var oldScrollTopInRange = (scrollTop + offset <= th - this.viewportH);

    if (th == 0 || scrollTop == 0) {
        page = offset = 0;
    }
    else if (oldScrollTopInRange) {
        // maintain virtual position
        scrollTo(scrollTop+offset);
    }
    else {
        // scroll to bottom
        scrollTo(th-this.viewportH);
    }

    if (h != oldH && this.options.autoHeight) {
        this.resizeCanvas();
    }
  };
}

