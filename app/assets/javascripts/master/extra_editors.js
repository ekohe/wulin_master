(function($) {

    var ExtraEditors = {
			BelongsToFormatter : function(row, cell, value, columnDef, dataContext) {
					return dataContext[columnDef.id][columnDef.optionTextAttribute];
			},
			
			BelongsToEditor : function(args) {
				var $select;
				var choices = args.column.choices;
				var optionTextAttribute = args.column.optionTextAttribute;
				var width = args.position.width;
				var horizontalMargin = 4;
				var defaultValue;
        
				this.init = function() {
					$select = $("<select class='chzn-select'></select>");
					$select.css('width', width-horizontalMargin);
          $select.appendTo(args.container);
          $select.focus();
					var options = "";
					$.each(choices, function() {
						options += "<option value="+this.id+">"+this[optionTextAttribute]+"</option>";
					});
					$select.html(options);
					
					// FIXME
					// Fix keyboard enter bug stupidly, find a better way please.
          setTimeout(function(){
                      $(".grid_container .chzn-drop").css('left', '0');
                      }, 80);
				};
				
				this.destroy = function() {
		        // remove all data, events & dom elements created in the constructor
            $select.remove();
		    };

		    this.focus = function() {
		        // set the focus on the main input control (if any)
            $select.focus();
		    };

		    this.isValueChanged = function() {
		        // return true if the value(s) being edited by the user has/have been changed
						return ($select.val() != defaultValue);
		    };

		    this.serializeValue = function() {
		        // return the value(s) being edited by the user in a serialized form
		        // can be an arbitrary object
		        // the only restriction is that it must be a simple object that can be passed around even
		        // when the editor itself has been destroyed
						var obj = {id: $select.val()};
						obj[optionTextAttribute] = $('option:selected', $select).text();
		        return obj;
		    };

		    this.loadValue = function(item) {
		        // load the value(s) from the data item and update the UI
		        // this method will be called immediately after the editor is initialized
		        // it may also be called by the grid if if the row/cell being edited is updated via grid.updateRow/updateCell
            defaultValue = item[args.column.id].id;
						$select.val(defaultValue);
            $select.select();
						$select.chosen().trigger("chzn:open");
		    };

		    this.applyValue = function(item,state) {
		        // deserialize the value(s) saved to "state" and apply them to the data item
		        // this method may get called after the editor itself has been destroyed
		        // treat it as an equivalent of a Java/C# "static" method - no instance variables should be accessed
            item[args.column.id].id = state.id;
            item[args.column.id][optionTextAttribute] = state[optionTextAttribute];
		    };

		    this.validate = function() {
		        // validate user input and return the result along with the validation message, if any
		        // if the input is valid, return {valid:true,msg:null}
            return {
                valid: true,
                msg: null
            };
		    };
				
				this.getCell = function(){
          return $select.parent();
        }

				this.init();
			}
		};
		
    $.extend(window, ExtraEditors);

})(jQuery);