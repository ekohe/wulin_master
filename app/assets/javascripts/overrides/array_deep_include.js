$.fn.arrayDeepInclude = function(obj) {
  var array = this.get();
  var include = false;
  if(!(array instanceof Array)) return false;
  
  if(obj instanceof Array) {
    for(var i in array) {
      if((array[i] instanceof Array) && !(array[i] > obj) && !(array[i] < obj)) {
        include = true;
        break;
      }
    }
    return include;
  } else {
    return array.indexOf(obj) != -1;
  }
}