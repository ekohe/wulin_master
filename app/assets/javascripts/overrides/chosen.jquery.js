Chosen.prototype.set_up_html = function() {
  var container_classes, container_div, container_props, dd_top, dd_width, sf_width;
  this.container_id = this.form_field.id.length ? this.form_field.id.replace(/[^\w]/g, '_') : this.generate_field_id();
  this.container_id += "_chzn";
  container_classes = ["chzn-container"];
  container_classes.push("chzn-container-" + (this.is_multiple ? "multi" : "single"));
  if (this.inherit_select_classes && this.form_field.className) {
    container_classes.push(this.form_field.className);
  }
  if (this.is_rtl) {
    container_classes.push("chzn-rtl");
  }
  this.f_width = this.form_field_jq.outerWidth();
  container_props = {
    id: this.container_id,
    "class": container_classes.join(' '),
    style: 'width: ' + this.f_width + 'px;',
    title: this.form_field.title
  };
  container_div = $("<div />", container_props);
  if (this.is_multiple) {
    container_div.html('<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + this.default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop" style="left:-9000px;"><ul class="chzn-results"></ul></div>');
  } else {
    container_div.html('<a href="javascript:void(0)" class="chzn-single chzn-default" tabindex="-1"><span>' + this.default_text + '</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" autocomplete="off" /></div><ul class="chzn-results"></ul></div>');
  }
  this.form_field_jq.hide().after(container_div);
  this.container = $('#' + this.container_id);
  this.dropdown = this.container.find('div.chzn-drop').first();
  dd_top = this.container.height();
  dd_width = this.f_width - get_side_border_padding(this.dropdown);
  this.dropdown.css({
    "width": dd_width + "px",
    "top": dd_top + "px"
  });
  this.search_field = this.container.find('input').first();
  this.search_results = this.container.find('ul.chzn-results').first();
  this.search_field_scale();
  this.search_no_results = this.container.find('li.no-results').first();
  if (this.is_multiple) {
    this.search_choices = this.container.find('ul.chzn-choices').first();
    this.search_container = this.container.find('li.search-field').first();
  } else {
    this.search_container = this.container.find('div.chzn-search').first();
    this.selected_item = this.container.find('.chzn-single').first();
    sf_width = dd_width - get_side_border_padding(this.search_container) - get_side_border_padding(this.search_field);
    this.search_field.css({
      "width": sf_width + "px"
    });
  }
  this.results_build();
  this.set_tab_index();
  return this.form_field_jq.trigger("liszt:ready", {
    chosen: this
  });
};

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

get_side_border_padding = function(elmt) {
  var side_border_padding;
  return side_border_padding = elmt.outerWidth() - elmt.width() + 1;
};
// ---------------- support disabled options ---------------------------