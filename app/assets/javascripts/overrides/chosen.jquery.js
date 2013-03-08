Chosen.prototype.search_results_mouseup = function(evt) {
  var target;
  target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).parents(".active-result").first();
  if (target.length) {
    this.result_highlight = target;
    this.result_select(evt);
    // return this.search_field.focus();
  }
};

Chosen.prototype.search_field_disabled = function() {
  this.is_disabled = this.form_field_jq[0].disabled;
  if (this.is_disabled) {
    this.container.addClass('chzn-disabled');
    if (this.search_field[0]) this.search_field[0].disabled = true;
    if (!this.is_multiple) {
      this.selected_item.unbind("focus", this.activate_action);
    }
    return this.close_field();
  } else {
    this.container.removeClass('chzn-disabled');
    if (this.search_field[0]) this.search_field[0].disabled = false;
    if (!this.is_multiple) {
      return this.selected_item.bind("focus", this.activate_action);
    }
  }
};
// ---------------- support disabled options ---------------------------
AbstractChosen.prototype.result_add_option = function(option) {
  var classes, style;
  option.dom_id = this.container_id + "_o_" + option.array_index;
  classes = option.selected && this.is_multiple ? [] : ["active-result"];
  if (option.selected) {
    classes.push("result-selected");
  }
  if (option.group_array_index != null) {
    classes.push("group-option");
  }

  // --------- support disable -------------
  if (option.disabled) {
    classes.push("disabled");
  }
  // ---------------------------------------

  if (option.classes !== "") {
    classes.push(option.classes);
  }
  style = option.style.cssText !== "" ? " style=\"" + option.style + "\"" : "";
  return '<li id="' + option.dom_id + '" class="' + classes.join(' ') + '"' + style + '>' + option.html + '</li>';
};

Chosen.prototype.result_select = function(evt) {
  var high, high_id, item, position;
  if (this.result_highlight) {
    high = this.result_highlight;
    high_id = high.attr("id");
    this.result_clear_highlight();
    if (this.is_multiple) {
      this.result_deactivate(high);
    } else {
      this.search_results.find(".result-selected").removeClass("result-selected");
      this.result_single_selected = high;
      this.selected_item.removeClass("chzn-default");
    }
    high.addClass("result-selected");
    position = high_id.substr(high_id.lastIndexOf("_") + 1);
    item = this.results_data[position];

    // -------------------- support disabled -------------------
    if(this.form_field.options[item.options_index].disabled){
      return false;
    }
    //----------------------------------------------------------

    item.selected = true;
    this.form_field.options[item.options_index].selected = true;
    if (this.is_multiple) {
      this.choice_build(item);
    } else {
      this.selected_item.find("span").first().text(item.text);
      if (this.allow_single_deselect) {
        this.single_deselect_control_build();
      }
    }
    if (!((evt.metaKey || evt.ctrlKey) && this.is_multiple)) {
      this.results_hide();
    }
    this.search_field.val("");
    if (this.is_multiple || this.form_field_jq.val() !== this.current_value) {
      this.form_field_jq.trigger("change", {
        'selected': this.form_field.options[item.options_index].value
      });
    }
    this.current_value = this.form_field_jq.val();
    return this.search_field_scale();
  }
};
// ---------------- support disabled options ---------------------------