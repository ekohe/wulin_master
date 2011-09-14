(function($) {
	function ConnectionManager(remoteModel) {
	  // Keeps all the requests available in an array
    var requests = [];

    function createConnection(url, indicator, clientOnSuccess, clientOnError) {
      var existingRequest = getConnection(url);
      
      // Just return if connection already exists.
      if (existingRequest != null) { return; }
      
      var newRequest = $.ajax({url: url,
                           success: onSuccess,
                           dataType: 'json',
                           error: onError});
                           
      newRequest.clientOnSuccess = clientOnSuccess;
      newRequest.clientOnError = clientOnError;
      newRequest.indicator = indicator;      
      newRequest.url = url;
      
      showIndicator(indicator);

      requests.push(newRequest);
    }
        
    function onSuccess(data, textStatus, request) {
      hideIndicator(request.indicator);
      request.clientOnSuccess(data, textStatus, request);
      // Remove request
      var requestIndex = requests.indexOf(request);
      if(requestIndex!=-1) requests.splice(requestIndex, 1);
    }
    
    function onError(request, textStatus, errorThrown) {
      request.clientOnError(request, textStatus, errorThrown);
      // Remove request
      var requestIndex = requests.indexOf(request);
      if(requestIndex!=-1) requests.splice(requestIndex, 1);
    }
    
    function is_empty(){
      return requests.length == 0;
    }
    
    function showIndicator(indicator) {
      var requestCount = indicator.data('requestCount');
      if (requestCount > -1) { indicator.show(); }
      indicator.data('requestCount', requestCount+1);
      updateIndicatorStats(indicator);
    }

    function hideIndicators(indicators) {
      for (var i = 0;i < indicators.length;i++)
        hideIndicator(indicators[i]);      
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
      
      if (requestCount == 0) {
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
		}
	}
	$.extend(true, window, { ConnectionManager: ConnectionManager})
})(jQuery);
