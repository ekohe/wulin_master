# WulinMaster

[![Join the chat at https://gitter.im/ekohe/wulin_master](https://badges.gitter.im/ekohe/wulin_master.svg)](https://gitter.im/ekohe/wulin_master?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

WulinMaster is a grid plugin base on Ruby on Rails and [SlickGrid](https://github.com/mleibman/SlickGrid). It provides powerful generator
and other tools to make grids easy to build as well as flexible configurations.

## Table of contents

- [Installation](#installation)
  - [1. Add `gem wulin_master` to your Gemfile](#1-add-gem-wulinmaster-to-your-gemfile)
  - [2. Run bundler command to install the gem](#2-run-bundler-command-to-install-the-gem)
  - [3. Run the generator to install the base building](#3-run-the-generator-to-install-the-base-building)
  - [5. Update Rails' default configs](#5-update-rails-default-configs)
  - [6. Include Wulin Master Javascript and Stylesheets](#6-include-wulin-master-javascript-and-stylesheets)
- [Getting Started](#getting-started)
  - [1. Generate resource files](#1-generate-resource-files)
  - [2. Run migration](#2-run-migration)
  - [3. Add grids](#3-add-grids)
  - [4. Add screens](#4-add-screens)
  - [5. Add controllers](#5-add-controllers)
- [Usage](#usage)
  - [1. Grid configuration](#1-grid-configuration)
  - [2. Panel configuration](#2-panel-configuration)
  - [3. Screen configuration](#3-screen-configuration)
- [Contributing](#contributing)
- [License](#license)

## Installation

### 1. Add `gem wulin_master` to your Gemfile

```bash
gem 'wulin_master', git: 'http://github.com/ekohe/wulin_master', branch: 'develop'
```

### 2. Run bundler command to install the gem

```bash
bundle install
```

### 3. Run the generator to install the base building

```bash
bundle exec rails g wulin_master:install
```

This will create:

```bash
create  app/controllers/homepage_controller.rb
create  config/initializers/wulin_master.rb
route  root :to => 'homepage#index'
```

Now, you can config wulin_master in `config/initializers/wulin_master.rb`

### 5. Update Rails' default configs

Remove the rails default view layout for wulin_master using its own layout

In config/application.rb, add `autoload_paths` for screens folder:

```
config.autoload_paths += Dir[Rails.root.join('app', 'screens', '{**}')]
config.autoload_paths += Dir[Rails.root.join('app', 'grids', '{**}')]
```

### 6. Include Wulin Master Javascript and Stylesheets

Add to your app/assets/config/manifest.js

```
//= link master/master.js
//= link master.css
```

to your application.js

```
//= require 'master/master.js'
```

and to your application.css

```
 *= require 'master'
```

## Getting Started

### 1. Generate resource files

Assume generating a new grid called `post`, run generator as:

```bash
bundle exec rails g wulin_master:screen_and_grid post name:string age:integer
```

This will create:

```bash
create  db/migrate/20170919093453_create_posts.rb
create  app/controllers/posts_controller.rb
create  app/screens/post_screen.rb
create  app/grids/post_grid.rb
create  app/models/post.rb
create  app/views/posts
route  resources :posts
```

`name:string age:integer` are the columns of the grid, in the format of `[field:type field:type]`.

### 2. Run migration

```bash
bundle exec rake db:migrate
```

This will create `grid_states` table for wulin_master to store the grid states for each user, including column's width/order/visibility, sort column and filter states.

### 3. Add grids

Create your first grid as the following:

``` ruby
# app/grids/post_grid.rb

class PostGrid < WulinMaster::Grid
  title 'Posts'   # Title

  model Post      # ActiveRecord model

  path '/posts'   # Path corresponding to `resources :posts` in routes.rb

  # Style options
  fill_window false
  width: '500px'
  height: '500px'

  # Other options
  cell_editable false
  eager_loading true

  # Define the grid row height
  row_height 30

  # Toolbar items shown as Material Design icons (https://material.io/icons/)
  action :publish_post, icon: :publish
  action :see_author, icon: :user
  ...

  # Call this method to add default toolbar items (Create/Edit/Delete/Import/Export)
  load_default_actions

  # Behaviours act as grid event handler
  behavior :highlight
  behavior :show_total_price
  ...

  # Define the grid columns
  column :title, sortable: true, visible: true, editable: true
  column :category, width: 100, label: "Category"
  column :created_at, editor: "TimeCellEditor"
  ...

  # Define dynamic edit form
  edit_form :version1 do |form|
    form << :name
  end

  edit_form :version2, class: 'version2_toolbar', icon: 'add' do |form|
    form << :code
  end

  # It defines two edit forms as well as toolbar items: version1, version2,
  # including different columns. The options `class: 'version2_toolbar', icon: 'add'`
  # is the same to action method arguments. Clicking toolbar `version1` will popup
  # form version1 including column [:name], while `version2` will trigger the popup
  # with column [:code].
end
```

### 4. Add screens

A screen can have one or multiple grids.

``` ruby
# app/screens/post_screen.rb:

class PostScreen < WulinMaster::Screen
  title 'All Posts'

  path '/posts'

  grid PostGrid
end
```

### 5. Add controllers

Add controllers inherited from `WulinMaster::ScreenController` and tell the controller which screen it controls. You can also define customized callbacks of your own.

```ruby
# app/controllers/posts_controller.rb

class PostsController < WulinMaster::ScreenController
  controller_for_screen PostScreen

  add_callback :query_filters_ready, :add_scope
  add_callback :query_ready, :state_filter

  protected

  # Add scope to query
  # @query here is an ActiveRecord class
  def add_scope
    @query = (params[:add_scope] == 'true' ? @query.scope : @query)
  end

  # Set filter for grid source
  # @query here is a ActiveRecord::Relation object
  def state_filter
    @query = @query.where(state: params[:state] || 'ok')
  end
end
```

### 6. Add Indexes

When searching by a string column, Wulin is generating this query:

```sql
SELECT * FROM "my_table" WHERE (UPPER(cast((my_table.my_column) as text)) LIKE UPPER('my_search%'));
```

For large table this will take a while to perform without proper index. To solve that you can speed up the queries by adding a trigram index like this:

```sql
CREATE INDEX trgm_index_my_table_on_my_column ON my_table USING gin ((UPPER(cast((my_table.my_column) as text))) gin_trgm_ops);
```

## Usage

### 1. Grid configuration

#### Basic grid configuration

A basic grid configuration needs to provide a model and columns. A title and path are optional, they will be assigned automatically according to the grid class name and model.

```ruby
#app/grids/post_grid.rb

class PostGrid < WulinMaster::Grid
  model Post

  title 'All posts'   # optional
  path '/blogs'       # optional

  column :title
  column :content
  column :author
end
```

#### Column options

A column can be a real field in the database table of the current model, or a virtual attribute of the model or other models. You can attach one or more options to define attributes for the column.

`:visible`

Default is `true`. If set `false`, the column will be invisible initially (can make it visible from column picker).

`:always_include`

Default is `false`. if set, this column will be available in the data even if not visible.

`:editable`

Default is `true`. If set, `false`, the grid cell of this column can not be edited.

`:sortable`

Default is `true`. If set `false`, this column can not be sorted.

`:default_sort_asc`

Default is `true`. If set `false`, this column default sort direction is DESC.

`:formable`

Whether to show the column in the `create` and `update` form or not. You can either set it to true or false, or pass an array `[:new, :edit]` for one or both of them.

```ruby
class PostGrid < WulinMaster::Grid
  ...
  column :author, formable: true          # author column will appear in both create and update form.
  column :title, formable: [:new, :edit]  # same to `formable: true`.
  column :content, formable: [:new]       # content column will appear in only create form.
  ...
end
```

`:auto_fill`

Default is `false`. If set `true`, the column will appear in the `new`/`edit` form in readonly.

`:label`

Sets the title displayed on the column header. If not set, the column label will be the same as the column name.

`:width`

Sets the initial width of the column. Default is `150`.

`:source`

Indicates the data source (the attribute name of the DB).

```ruby
class PostGrid < WulinMaster::Grid
  ...
  column :author_email, source: :email, through: :author  # source = :email (of Author)
  column :email, through: :author                         # source = :email (of Author)
  column :author, source: :name                           # source = :name  (of Author)
  column :author                                          # source = :name  (of Author)
  column :title                                           # source = :title (of Post)
  ...
end
```

`:through`

Indicates the model when a column comes from another model:

```ruby
class PostGrid < WulinMaster::Grid
  ...
  column :author_name, source: :name, through: :author
  ...
end
```

`:join_aliased_as`

When the grid needs to show two or more columns which come from the same table and the same column, you can define `:join_aliased_as` for one column to set the alias. This will avoid conflict when doing sql join.

`:sort_column`

Indicates the column that should be used for sorting when it is not the column itself.

`:sql_expression`

This option is special and rarely used. It is only used when you want to perform a special sql operation, like the 'sorting' or 'filtering' virtual attributes by sql.

`:sql_type`

This option is only used when the column is a virtual attribute column. Since it is not a real column in the database, we can not know its type of db level. So if you want to enable this column to be editable in the `create` or `edit` form, you have to explicitly specify its `:sql_type`.

`:editor`

By default, if the column is editable, the type of cell editor is determined from the column types such as `string`, `integer`, `boolean` etc. Therefore you don't need to specify the editor manually for general cases. However in some cases you have to define the `:editor`. For example, `SelectEditor` renders a dropdown of possible values of the column, `TimeCellEditor` renders a time-picker for the column which is of `datetime` type, etc.

You can define a new type of editor by yourself. All editor definitions can be found in `editor.js`

`:formatter`

This option defines how the value is displayed in the grid cell. For example, `MoneyFormatter` renders the number value as money format, etc.

You can also define a new formatter by yourself. The formatter definitions are all located in `slick.editor.js`.

`:choices`

This option should be used together with `SelectEditor`, it specifies the options of the dropdown. Its value can be an array, a url path which can return a response of array, or a hash in very rare cases.

`:choices_columm`

This option should also be used together with `SelectEditor`. Its value should be another column name in the grid, and the value of the column for the current record is an array, so that the current dropdown will load the array items as options.

`:file`

If the column is a file field, like image or any file, you should add this option and set it to true. It will use `file_field` in the `new`/`edit` form.

`:password`

If this column is a password or password_confirmation, you should add this option and set it to true. It will use `password_field` in the `new`/`edit` form.

`:depend_column`

This option should be used when the `:choices` option is specifying a hash value. When you choose a value, say 'k1', from the column that `:depend_column` specifies, then when you edit the current column, the dropdown will display options which are the values of key 'k1' in the choices hash. Here is an example:

```ruby
class ServiceGrid < WulinMaster::Grid
  UNIT_OPTIONS = ["piece", "match", "mn", "slot", "match-day", "match-period", "pkg"]
  UNIT_SCALE_OPTIONS = {'piece' => [],
                        'match' => [],
                        'mn' => ['10','30','60'],
                        'slot' => ['pre','post'],
                        'match-day' => [],
                        'match-period' => [],
                        'pkg' => []}
  ...
  column :unit, choices: UNIT_OPTIONS, editor: 'SelectEditor'
  column :unit_scale, choices: UNIT_SCALE_OPTIONS, depend_column: :unit, editor: 'SelectEditor'
  ...
end
```

For the example above, if you choose 'mn' for `:unit column`, the available values for `:unit_scale` will be ['10','30','60'].

`:currency`

This option should be used when the :formatter is 'MoneyFormatter', you can specify it as '$' or '€', or other types of currencies.

`:position_of_currency`

This option should be used when the :formatter is 'MoneyFormatter'. The expected values are 'before' and 'after' to customize the position of currency sign relative to the value. Default is `after`.

`:precision`

This option could be used when the :formatter is 'MoneyFormatter'. it control the precicion of the money.

`:dynamic_options`

This option is only useful for some relation columns. For example, `Post` belongs to `Category`. In the `Post` grid, the category cell editor should be a drop-down. If `:dynamic_options` is set to `true` for the category column in the `Post` grid, it will be a `Add new option` option at the bottom of the category drop-down. When you click on the `Add new option` option, the create category form pops up, and you can create a new category there. Then the drop-down will choose the created category automatically.

`:distinct`

This option is only useful for the text column.

`:style`

Set inline css to the cell that belongs to the specified column. Example: `style: 'text-align:center'`

`:style_class`

Set the css class to the cell that belongs to the specified column. Example: `style_class: 'red'`

#### Grid styles

The style configuration methods are all defined in the `WulinMaster::ComponentStyling` module (both grid and panel components). You can use these methods in a grid class file, or as an option of grid in a screen class file, like:

```ruby
class PostGrid < WulinMaster::Grid
  width "50%"
  height "30%"
end
```
or

```ruby
class PostScreen < WulinMaster::Screen
  grid PostGrid, width: "50%", height: "30%"
end
```

The following are the available style methods:

`:height`

Sets the height of the component. The value can be a number (default unit is `px`) or a percentage string.

`:width`

Sets the width of the component. The value can be a number (default unit is `px`) or a percentage string.

`:css`

Sets the whole style of the component. The value is a string of css styles, such as `width:300px;height:200px;float:left`

`:fill_window`

Determines whether the component fills the whole window or not. The default value is true.

#### Grid options

The option configuration of the grid can set some attributes of the grid. These methods can be used in a grid class file, or as an option of a grid in a screen class file, like the usage of grid styles. The available option methods are as follows:

`:cell_editable`

Sets whether the whole grid is editable or not. The default is `true`.

`:column_sortable`

Sets whether all columns are sortable or not. The default is `true`.

`:hide_header`

Sets the grid hide header or not. The default is `false`.

`:eager_loading`

Sets the grid load data or not when rendered. The default is `true`. If set to `false`, the grid will not load data until filters are set.

`:multi_select`

The default is `true`, which means multiple rows in the grid are selectable. If set to `false`, only one row is selectable.

`:color_theme`

Sets color theme for a specific grid. The default color theme comes from  `app_config.yml` under the `config` folder. WulinMaster supports all [colors](https://materializecss.com/color.html) provided by [MeterializeCSS](https://materializecss.com/)

```yml
# config/app_config.yml

wulin_master:
  color_theme: 'blue'
```

```ruby
# app/grids/post_grid.rb

class PostGrid < WulinMaster::Grid
  color_theme 'red'
end
```

`:background_color`

Apart from `color_theme`, we can also set the background color using `background_color`. Same as `color_theme`, the supported colors are listed  [here](https://materializecss.com/color.html).

`:estimate_count`

Normally, WulinMaster uses the `#count` method of ActiveRecord which uses basic query `SELECT COUNT(*) FROM TABLE_NAME` to count the rows listed in a grid. However we also provide an optimized version by using the benefit of [count estimate](https://wiki.postgresql.org/wiki/Count_estimate) for the same performance when persisting your data in a PostgresSQL database. The method can also be used only when the data volume is incredibly large by setting the `threshold` parameter as `estimate_count threshold: 1000000`.

`:default_sorting_state`

Sets the default sorting state for the grid. Usage: `default_sorting_state column: 'name', direction: 'ASC'`

`:row_detail`

Sets to show the row detail panel. You can specify the options as follows:

```ruby
row_detail cssClass: 'company_row_detail', panelRows: 5, useRowClick: true, showTriggerColumn: false, loadingTemplate: '<span class="red-text">Loading...</span>', postTemplate: :company
```

- **cssClass**: A CSS class to be added to the row detail. Default: `detailView-toggle`
- **panelRows**: Row count to use for the row detail panel. Default: `4`
- **hideRow**: Boolean flag. When `true` will hide the current row on a row click (from any column). Default: `false`
- **useRowClick**: Boolean flag. When `true` will open the row detail on a row click (from any column). Default: `false`
- **showTriggerColumn**: Boolean flag. When `false` will hide the column to trigger the row detail panel. Default: `true`
- **loadingTemplate**: Template (html) that will be used before the async process, typically used to show a spinner/loading. Default: `Loading...`
- **postTemplate**: Template that will be loaded once the async function finishes. Should be defined as a javascript method with item data as the parameter passed as a property of a global object named `RowDetailTemplates` which return the html code. Default: `<div class="row-detail"> ID: ' + item.id + '</div>`. You can also define your own templates within the host app's assets:
  ```js
  var RowDetailTemplates = $.extend({}, RowDetailTemplates, {
    company: function(item) {
      return '<div class="company-row-detail red-text"> Name: ' + item.name + '</div>';
    }
  });
  ```

#### Grid actions

If you want to set toolbar items on the grid, grid actions provide a convenient way to do that. Let's look at an example:

1.First, call the action method in the grid configuration file. For example, we want to add a 'print' button on the toolbar

```ruby
class PostGrid < WulinMaster::Grid
  ...
  action :print, title: 'Print Post', icon: :print
  ...
end
```

After this, you will see an icon appear on the grid toolbar, and the item css should be `print_action toolbar_icon_print`. A background image can be set for the css. Currently, the available options are 'title' and 'icon' which are used to set the action text and css for each.

2.Then, create a javascript file for the action. Write the click handler for it:

```js
// app/assets/javascripts/actions/print.js

WulinMaster.actions.Print = $.extend({}, WulinMaster.actions.BaseAction, {
  name: 'print',

  handler: function() {
    // write your logic when click the toolbar item
    alert("print");
  }
});

WulinMaster.ActionManager.register(WulinMaster.actions.Print);

```

You can add this js file anywhere in the application, but we recommend to put it in the `app/assets/javascripts/actions` folder

That's all, you have set up a simple print action.

In addition, you can call the `load_default_actions` method to add the default toolbar items of WulinMaster. The toolbar items are 'Create', 'Delete', 'Edit', 'Audit', 'Import' and 'Export'(if you have installed **WulinAudit**, **WulinImport** and **WulinAudit** gem).

Also, if you want to extend the WulinMaster gem or to create your own gems which include new actions and you want to make them to be default actions, you can call the API method `add_default_action`:

```ruby
# param1         : :import - action name
# param2 (option): { icon: :file_upload } - select default icon from https://material.io/icons/
# param3 (option): { global: true } - action available when no record is selected, such as Create, Import, Export etc.
WulinMaster::Grid.add_default_action :import, icon: :file_upload, global: true
```

#### Grid behaviors

WulinMaster grid has a lot of events such as `onDataLoaded`, `onViewportChanged`, etc. (see `slick.grid.js` for details). If you want to bind some event handlers, grid behavior gives you an easy and well-organized way. Let's look at an example:

1.First, call the `#behavior` method in a grid configuration file. We want to add the `show_total_price` behavior after the grid data has loaded.

```ruby
class OrderGrid < WulinMaster::Grid
  ...
  behavior :show_total_price
  ...
end
```

2.Then, create a javascript file for this behavior. Write the event and handler for it:

```js
// app/assets/javascripts/behaviors/show_total_price.js

WulinMaster.behaviors.ShowTotalPrice = $.extend({}, WulinMaster.behaviors.BaseBehavior, {
  event: "onDataLoaded",

  subscribe: function(target) {
    this.grid = target;
    var self = this;
    target.loader[this.event].subscribe(function(){ self.handler() });
  },

  unsubscribe: function() {
  },

  handler: function() {
    var total = 0.0;
    var dataset = this.grid.getData();
    for(var i in dataset) total += datas[i].price
    alert(total);
  },
});

WulinMaster.BehaviorManager.register("show_total_price", WulinMaster.behaviors.ShowTotalPrice);
```

You can add this js file anywhere in the application, but we recommend to put it in the *app/assets/javascripts/behaviors* folder

That's all, you have set up a simple behavior.

In addition, we already provide some behaviors in the `wulin_master` gem, which can be checked out in the *wulin_master/app/assets/javascripts/master/behaviors* folder. If you want to disable some default behaviors for the grid in your application, you are able to call the `remove_behaviors` method. Also, if you extend the WulinMaster gem or create your own gems which include new behaviors and you want to make them the default behavior for all grids, you can call the API method `add_default_behavior(YOUR_BEHAVIOR)` to configure that.

#### Configuration for different screens

In many cases, a grid may appear on different screens for different purposes, so it may have different styles, options, actions or behaviors across screens. This is easy to implement.

1.If you configure the grid in a screen class file, the grid options are only valid on this screen:

```ruby
class PostScreen < WulinMaster::Screen
  grid PostGrid, width: '30%', height: '50%', eager_loading: false, multi_select: false
  ...
end

class MagazineScreen < WulinMaster::Screen
  grid PostGrid
  ...
end
```

As above, the `PostGrid` options defined in `PostScreen` are only valid on the grid in `PostScreen`, without affecting the grid in `MagazineScreen`.

2.However, if you configure the grid in a grid class, you should specify which screens are available or not by using `:only` and `:except` option:

```ruby
class PostGrid < WUlinMaster::Grid
  ...
  width: '30%', only: [:MagazineScreen]
  action :print_post, except: [:MagazineScreen]
  behavior :show_author
  ...
end
```

As the example above, the `PostGrid`'s width will be '30%' only in `MagazineScreen`. The `print_post` action will appear in all screens except `MagazineScreen`, however, the `show_author` behavior has not been set the `:only` nor `:except` option, so it will be available to `PostGrid`s in all screens.

The `:only` and `:except` options can be appended to all methods of grid styles, options, actions and behaviors.

#### Configuration for different users

Permission management is a necessary aspect for the application. If you are using `wulin_permits` (the permission management plugin of the Wulin series), you can easily configure which screens or grid actions are visible for a certain kinds of users.

For screen permission, configuration is possible as such:

```ruby
submenu 'Orders' do
  # the "order#cud" is a auto-generated permission by wulin_permits, you can configure it in 'Roles Permissions' setting
  item CreateOrderScreen, authorized?: lambda { |user| user.has_permission_with_name?('order#cud') }
  item OrderScreen
end
```

For action permission:

```ruby
class ContactGrid < WulinMaster::Grid
   ...
   action :create
   action :edit
   action :delete, authorized?: lambda { |user| user.has_permission_with_name?("contacts#delete") }
   ...
end
```

#### Configuration for multi-level joins support to ActiveRecord

**Use case**: `Travel` belongs to `Position` and `Position` belongs to `Person`. We want to show the `first_name` field of a person in `Travel` grid with sorting and filtering available.

For the case above, we could work it around by configurations as following:

###### 1. Define the relationship to `person` for `Travel`

```ruby
# travel.rb

class Travel
  has_one :person, through: :position
end
```

###### 2. Define `first_name` through `person` in grid

```ruby
# travel_grid.rb

class TravelGrid < WulinMaster::Grid
  column :first_name, through: :person
end
```

### 2. Panel configuration

As one of WulinMaster components, `WulinMaster::Panel` can also be rendered in the screen as `WulinMaster::Grid`, however the configuration is much easier:

```ruby
# app/panels/order_booking_panel.rb

class OrderBookingPanel < WulinMaster::Panel
  fill_window false
  width '100%'
  height '50%'
  partial 'order_booking'
end
```

Panel configuration can use the same methods used in grid styles since they are defined in `WulinMaster::ComponentStyling` which are both included in `WulinMaster::Grid` and `WulinMaster::Panel`.

The special configure option for a Panel is `partial`. By default, the corresponding html partial file for a Panel should be put in *app/views/panel_partials*, and the file name should be the underscore version of panel class name. However if you want to use another partial name, you can set partial option manually.

### 3. Screen configuration

#### Basic screen configuration

The most basic screen configuration does not need to provide anything, it will request the url path which it gets from the screen class name. For example `OrderScreen` will request path `orders?screen=OrderScreen` unless you set path option, and will display nothing until you add grids and panels. They will be rendered on the screen one by one.

```ruby
class OrderScreen < WulinMaster::Grid
  path '/orders/booking'  # optional

  title 'Orders Booking'  # optional

  panel OrderBookingPanel, height: '50%'
  grid OrderGrid, height: '50%'
end
```

#### Grid and Panel options in screen

This has been explained in 'Grid configuration/Configuration section, describing the different screens'. The option you set for a panel or a grid in this screen class will be valid only in this screen.

#### Master-Detail grids

In many cases, we need to display two grids in one screen whose model relationship is `belong_to` and `has_many`. We have built a helper method `master_grid` in the wulin_master gem to enable you to easily implement this. Eg, you want to show `AuthorGrid` and `PostGrid` in one screen. w
When one author is selected in `AuthorGrid`, the `PostGrid` will show his/her posts.

```ruby
class ArticleScreen < WulinMaster::Screen
  title 'All Articles'
  path 'authors'

  grid AuthorGrid, height: '50%'
  grid PostGrid, height: '50%', master_grid: 'AuthorGrid', eager_loading: false
end
```

In the example above, `eager_loading` is set to `false` to prevent `PostGrid` from loading until an author is selected.

Sometimes, there is no existing master grid, but you still want to have the detail grid filtered by a given master id. In this case you can use `master_model` instead of `master_grid`. In fact, the two options both add a hidden column into detail grid in purpose of filtering, generally the column name is the foreign key name between the detail grid model and the master model. Let's make a small change in the previous example and use the `master_model` option:

```ruby
# article_screen.rb

class ArticleScreen < WulinMaster::Screen
  title 'All Articles'

  panel AuthorSelectionPanel
  grid PostGrid, height: '50%', master_model: 'author', eager_loading: false
  # Actually, the master_model option will add a hidden column 'author_id' into PostGrid
end
```

```js
// author_selection.js (using jQuery)

$('.#author_list').change(function(){
  var postGrid = gridManager.getGrid('post');
  var author_id = $(this).val();

  postGrid.master = {filter_column: 'author_id', filter_value: author_id};
  postGrid.loader.addFilter('author_id', author_id, 'equals');
});
```

In the above example, there is no `Author` grid, but supposing a dropdown list #author_list is located in AuthorSelectionPanel, when we select one author from the dropdown. The data in PostGrid will be be filtered by invoking the javascript method `addFilter`.

##### `add_detail` action

For Master-Detail relationship, wulin_master provides a build-in action `add_detail`. Once you use it on detail grid, you can get a new toolbar item which can help you to add one or more detail records for the selected master record.

```ruby
class AuthorPostGrid < WulinMaster::Grid
  ...
  action :add_detail, model: 'post', screen: 'AddPostScreen', icon: 'add', title: 'Add Posts'
end

class AddPostScreen < WulinMaster::Screen
  grid PostGrid, title: 'Available Posts', master_model: 'author'
end
```

In the code above, action `:add_detail` must have two necessary options, `model` and `screen`: `model` specifies what kind of record you want to add, `screen` is the screen that contains the grid which you can pick records from.

`add_detail` action can have the option `reload_master`. If set to true, the master grid will be reloaded automatically, when adding detail records is over. (This option can also be applied to `:delete` action when it is used as 'remove detail').

##### `detail_model` option

We often meet self-related models when we 'add detail'. Imagine that there is an `Employee` model, and an employee can have many subordinates which are also employees.

```ruby
class Employee < ActiveRecord::Base
  has_many :subordinates, through: :staff_relations    # staff_relations is the middle table
  has_many :bosses, through: :staff_relations
end
```

Now we can set grids to add subordinates for the selected employee, like the following code:

```ruby
class EmployeeGrid < WulinMaster::Grid
  ...
  action :add_detail, model: 'subordinates', screen: 'AddSubordinateScreen', title: 'Add Subordinates', icon: 'add', only: [:BossScreen]
end

class AddSubordinateScreen < WulinMaster::Screen
  grid EmployeeGrid, title: 'Available Employees', master_model: 'bosses', detail_model: 'subordinates'
end
```

In the code above, we must specify `detail_model` as 'subordinates' for `EmployeeGrid` in `AddSubordinateScreen`. Otherwise the `EmployeeGrid` will use the default model 'employee' to find the relationship, which will cause an error.

#### Define Inclusion-Exclusion grids

Inclusion-Exclusion grids is also a very common case. For example, there are 3 grids in the screen, the models of two grids has the relationships `has_and_belongs_to_many` or `has_many`, the third grid comes from the join table or through model. Let's look at following example:

    +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    | People Groups                                       |
    |-----------------------------------------------------|
    || Name    ||                                         |
    |-----------|                                         |
    | Managers  | *                                       |
    |-----------|                                         |
    | Employers |                                         |
    |-----------|                                         |
    |_ _ _ _ _ _| _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |
    |+++++++++++++++++++++++++++++++++++++++++++++++++++++|
    |  Exsiting People  |           |  Available People   |
    |-------------------|  _______  |---------------------|
    || Name            || | < Add | ||  Name             ||
    |-------------------|  -------  |---------------------|
    | Tom               |  _______  |  Alice              |
    |-------------------| |Remove>| |---------------------|
    | Mike              |  -------  |  Bob                |
    |-------------------|           |---------------------|
    |                   |           |  Jerry              |
    |                   |           |---------------------|
    +++++++++++++++++++++++++++++++++++++++++++++++++++++++

We have the `PeopleGroup` model, `People` model, they have a `has_many` relation with each other, their relation through model is `PeopleGroupsPeople`. We want to build the above screen to manage the groups. When we select a group, the left bottom grid will show people from this group, the right bottom grid will show people who are not in the group yet, and you can utilize the middle panel to add/remove people to/from the group. We can implement as the following:

```ruby
# app/grids/people_group_grid.rb
class PeopleGroupGrid < WulinMaster::Grid
  column :name
end

# app/grids/people_grid.rb
class PeopleGrid < WulinMaster::Grid
  column :name
end

# app/grids/people_groups_people_grid.rb
class PeopleGroupsPeopleGrid < WulinMaster::Grid
  column :people
end

# app/screens/people_group_screen.rb
class PeopleGroupScreen < WulinMaster::Screen
  path '/people_groups'

  grid PeopleGroupGrid, height: '50%'

  # People/PeopleGroup inclusion-exclusion
  grid PeopleGroupsPeopleGrid, height: '50%', width: '45%', title: 'Existing People', include_of: 'PeopleGroupGrid', eager_loading: false
  panel WulinMaster::InclusionExclusionPanel, height: '50%', width: '10%', inclusion_grid: 'PeopleGroupsPeopleGrid', exclusion_grid: 'PeopleGrid'
  grid PeopleGrid, height: '50%', width: '45%', title: 'Available Peoples', exclude_of: 'PeopleGroupGrid', eager_loading: false
end
```

In the configuration for the screen above, we use helper methods `include_of`, `exclude_of` to specify the inclusion and exclusion grids, also we used `WulinMaster::InclusionExclusionPanel` which is pre-defined in the wulin_master gem. However it has to know which is the inclusion grid and which is the exclusion grid by set options `inclusion_grid` and `exclusion_grid`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b new-feature`)
3. Commit your changes (`git commit -am 'Added an awesome feature'`)
4. Push to the branch (`git push origin new-feature`)
5. Create new Pull Request

## License

WulinMaster is released under the MIT license.
