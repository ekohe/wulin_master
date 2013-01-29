$.difference = function(ary1, ary2){
  var dif = [];
  if(ary2.length >= ary1.length) {
    $.grep(ary2, function(el) {
      if ($.inArray(el, ary1) == -1) dif.push(el);
    });
  } else {
    $.grep(ary1, function(el) {
      if ($.inArray(el, ary2) == -1) dif.push(el);
    });
  }

  return dif;
};