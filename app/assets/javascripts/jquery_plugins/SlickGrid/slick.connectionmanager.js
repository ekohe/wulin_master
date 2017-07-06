(function($) {
  function ConnectionManager(remoteModel) {
    // Keeps all the requests available in an array
    var requests = [];
    var $progress_bar;

    function createConnection(grid, url, indicator, clientOnSuccess, clientOnError, currentRequestVersionNumber) {
      var existingRequest = getConnection(url);

      // Just return if connection already exists.
      if (existingRequest !== null) { return; }

      // Ekohe Add: Use progress bar in grid header as indicator
      var $header = grid.container.find('.slick-header');
      $progress_bar = $('<div class="progress"><div class="indeterminate"></div></div>').appendTo($header);
      if (grid.getDataLength() == 0) {
        grid.renderLoadingRows({top: 0, bottom: 30});
      }

      var newRequest = $.ajax({url: url,
                           success: onSuccess,
                           complete: complete,
                           dataType: 'json',
                           error: onError});

      newRequest.clientOnSuccess = clientOnSuccess;
      newRequest.clientOnError = clientOnError;
      // Ekohe Edit: Use progress bar in grid header as indicator
      // newRequest.indicator = indicator;
      newRequest.indicator = $progress_bar;
      newRequest.url = url;
      newRequest.loader = grid.loader;
      newRequest.versionNumber = currentRequestVersionNumber; // Set the version number

      // Ekohe Delete: Use progress bar in grid header as indicator
      // showIndicator(indicator);

      requests.push(newRequest);
    }

    function complete(request, textStatus) {
      // Remove request
      // var requestIndex = requests.indexOf(request);
      // if(requestIndex!=-1) requests.splice(requestIndex, 1);
      requests = $.grep(requests, function(n, i){
        return n.url != request.url;
      });
    }

    function onSuccess(data, textStatus, request) {
      // Ekohe Edit: Use progress bar in grid header as indicator
      // hideIndicator(request.indicator);
      $progress_bar.remove();
      $('.slick-row.loading').remove();
      if (request.versionNumber < request.loader.lastRequestVersionNumber) {
        return;
      }
      request.loader.lastRequestVersionNumber = request.versionNumber; // Update lastRequestVersionNumber
      request.clientOnSuccess(data, textStatus, request);
    }

    function onError(request, textStatus, errorThrown) {
      request.clientOnError(request, textStatus, errorThrown);
      // Remove request
      var requestIndex = requests.indexOf(request);
      if(requestIndex!=-1) requests.splice(requestIndex, 1);
    }

    function is_empty(){
      return requests.length === 0;
    }

    function showIndicator(indicator) {
      var requestCount = indicator.data('requestCount');
      if (requestCount > -1) { indicator.show(); }
      indicator.data('requestCount', requestCount+1);
      updateIndicatorStats(indicator);
    }

    function hideIndicators(indicators) {
      for (var i = 0;i < indicators.length;i++) {
        hideIndicator(indicators[i]);
      }
    }

    function hideIndicator(indicator) {
      var requestCount = indicator.data('requestCount');
      if (requestCount == 1) { indicator.fadeOut(); }
      indicator.data('requestCount', requestCount-1);
      updateIndicatorStats(indicator);
    }

    function updateIndicatorStats(indicator) {
      var requestCount = indicator.data('requestCount');
      var stats = indicator.find(".loading_stats");

      if (requestCount === 0) {
        stats.text("");
      } else {
        stats.text("Loading " + (indicator.loadingSize * requestCount) + " rows");
      }
    }

    function getConnection(url) {
      for (var i = 0; i < requests.length; i++){
        if (requests[i].url == url)
          return requests[i];
      }
      return null;
    }

    function removeConnection(url){
      for (var i = 0; i < requests.length; i++){
        if (requests[i].url == url)
          return requests.splice(i,1);
      }
      return null;
    }

    return {
      // properties
      "requests": requests,
      "remoteModel": remoteModel,

      // functions
      "createConnection": createConnection,
      "is_empty": is_empty,
      "removeConnection": removeConnection
    };
  }
  $.extend(true, window, { ConnectionManager: ConnectionManager});
})(jQuery);
