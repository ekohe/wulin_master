# WulinMaster

[![Join the chat at https://gitter.im/ekohe/wulin_master](https://badges.gitter.im/ekohe/wulin_master.svg)](https://gitter.im/ekohe/wulin_master?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

WulinMaster is a grid plugin base on Ruby on Rails and [SlickGrid](https://github.com/mleibman/SlickGrid). It provides powerful generator
and other tools to make grids easy to build as well as flexible configurations.

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

`:editable`

Default is `true`. If set, `false`, the grid cell of this column can not be edited.

`:sortable`

Default is `true`. If set `false`, this column can not be sorted.

`:formable`

To show the column in the `create` and `update` form or not. You can either set it to true or false, or pass an array `[:new, :edit]` for one or both of them.

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

Default is `false`, if set `true`, the column will appear in the `new`/`edit` form but readonly.

`:label`

Set the title displayed on the column header, if not set, the column label will be the same to column name.

`:width`

Set the initial width of the column, default is `150`.

`:source`

Indicate the the data source (the attribute name of the DB).

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

Indicate the model when the column comes from another model:

```ruby
class PostGrid < WulinMaster::Grid
  ...
  column :author_name, source: name, through: :author
  ...
end
```

`:join_aliased_as`

When the grid needs to show 2 or more columns which come from the same table and the same column, you can define `:join_aliased_as` for one column to set the alias to avoid conflict when doing sql join.

`:sort_column`

Indicate the column should be used for sorting when it is not the column it self.

`:sql_expression`

This option is special and rarely used. It is only used when you want to do some special sql operation, like 'sorting' or 'filtering' virtual attributes by sql.

`:sql_type`

This option is only used when the column is a virtual attribute column. Since it is not a real column in database, we can't know its type of db level. So if you want to make this column be editable in the `create` form or `edit` form, you have to explicitly specify its `:sql_type`.

`:editor`

By default, if the column is editable, the type of cell editor is decided from the column type: `string`, `integer`, `boolean` etc. So you don't need to specify the editor manually for general cases. But sometimes, you have to define the `:editor`. For example, `SelectEditor` renders a dropdown of possible values of the column, `TimeCellEditor` renders a time-picker for the column which is `datetime` type, etc.

You can define a new type of editor by yourself, the editor definitions are all located in `editor.js`

`:formatter`

This option defines how the value is displayed in the grid cell, for example: `MoneyFormatter` renders the number value as money format, etc.

And, you can also define a new formatter by yourself, the formatter definitions are all located in `slick.editor.js`.

`:choices`

This option should be used together with `SelectEditor`, it specifies the options of the dropdown. Its value can be an array, a url path which can return a response of array, or a hash in very rare cases.

`:choices_columm`

This option should also be used together with `SelectEditor`, its value should be another column name in the grid, and the value of the column for current record is an array, so that current dropdown will load the array items as options.

`:file`

If the column is a file field, like image or any file, you should add this option and set it to true. It will use `file_field` in the `new`/`edit` form.

`:password`

If this column is a password or password_confirmation, you should add this option and set it to true. It will use `password_field` in the `new`/`edit` form.

`:depend_column`

This option should be used when the `:choices` option specifying a hash value. When you choose a value, say 'k1', from the column that `:depend_column` specifies, then you edit the current column, the dropdown will display options which are the values of key 'k1' in the choices hash. Here is an example:

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

For above example, if you choose 'mn' for `:unit column`, the available values for `:unit_scale` will be ['10','30','60'].

`:currency`

This option should be used when the :formatter is 'MoneyFormatter', you can specify it as '$' or '€', or other type of currencies.

`:dynamic_options`

This option is only useful for some relation columns. For example, `Post` belongs to `Category`. In `Post` grid, category cell editor should be a drop-down. If set `:dynamic_options` to `true` for category column in `Post` grid, it will be a `Add new option` option at bottom of category drop-down. When you click `Add new option` option, create category form pops up, and you can create a new category there and then drop-down will be chosen the created category automatically.

`:distinct`

This option is only useful for text column.

`:style`

Set inline css to the cell belongs to the specified column. Example: `style: 'text-align:center'`

`:style_class`

Set css class to the cell belongs to the specified column. Example: `style_class: 'red'`

#### Grid styles

Now the style configuration methods are all defined in `WulinMaster::ComponentStyling` module (grid and panel are both component), you can use these methods in grid class file, or as an option of grid in screen class file, like:

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

Followings are the available style methods:

`:height`

Set the height of the component. The value can be a number (default unit is `px`) or a percentage string.

`:width`

Set the width of the component. The value can be a number (default unit is `px`) or a percentage string.

`:css`

Set the whole styles of the component. The value is a string of css styles, like `width:300px;height:200px;float:left`

`:fill_window`

Determine the component fill the whole window or not. The default value is true.

#### Grid options

The option configuration of grid can set some attributes of the grid. These methods can be used in grid class file, or as an option of grid in screen class file, like the usage of grid styles. Followings are the available option methods:

`:cell_editable`

Set the whole grid editable or not, default is `true`

`:column_sortable`

Set the all columns sortable or not, default is `true`

`:hide_header`

Set the grid hide header or not, default is `false`

`:eager_loading`

Set the grid load data or not when rendered, default is `true`. If set `false`, the grid won't load data until set filters.

`:multi_select`

Default is `true`, which means you can select multiple rows in the grid. If set `false`, you can only select one row.

`:color_theme`

Set color theme for a specific grid, default color theme comes from the  `app_config.yml` under the `config` folder. WulinMaster supports all [colors](https://materializecss.com/color.html) provided by [MeterializeCSS](https://materializecss.com/)

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

Apart from `color_theme`, we can also set back ground color using `background_color`. Same to `color_theme`, supported colors listed  [here](https://materializecss.com/color.html).

`:estimate_count`

Normally, WulinMaster uses `#count` method of ActiveRecord which simply uses basic query `SELECT COUNT(*) FROM TABLE_NAME` to count the rows listed in a grid, but we also provide an optimized version by using the benefit of [count estimate](https://wiki.postgresql.org/wiki/Count_estimate) to do that when you're persisting your data in a PostgresSQL database. You can also make it happen to use the method only when data volume is huge by setting `threshold` parameter as `estimate_count threshold: 1000000`.

`:default_sorting_state`

Set the default sorting state for the grid. Usage: `default_sorting_state column: 'name', direction: 'ASC'`

`:row_detail`

Set to show the row detail panel. You can specify options as followings:

```ruby
row_detail cssClass: 'company_row_detail', panelRows: 5, useRowClick: true, showTriggerColumn: false, loadingTemplate: '<span class="red-text">Loading...</span>', postTemplate: :company
```

- **cssClass**: A CSS class to be added to the row detail. Default: `detailView-toggle`
- **panelRows**: Row count to use for the row detail panel. Default: `4`
- **hideRow**: Boolean flag, when `true` will hide the current row on a row click (from any column). Default: `false`
- **useRowClick**: Boolean flag, when `true` will open the row detail on a row click (from any column). Default: `false`
- **showTriggerColumn**: Boolean flag, when `false` will hide the column to trigger the row detail panel. Default: `true`
- **loadingTemplate**: Template (html) that will be used before the async process, typically used to show a spinner/loading. Default: `Loading...`
- **postTemplate**: Template that will be loaded once the async function finishes. Should be defined as a javascript method with item data as parameter presented as a property of a global object named `RowDetailTemplates` which return html code. Default: `<div class="row-detail"> ID: ' + item.id + '</div>`. You can define your own templates within the host app's assets like
  ```js
  var RowDetailTemplates = $.extend({}, RowDetailTemplates, {
    company: function(item) {
      return '<div class="company-row-detail red-text"> Name: ' + item.name + '</div>';
    }
  });
  ```

#### Grid actions

If you want to set toolbar items on the grid, grid actions provide a convenient way to do that. Let's look an example:

1.First, call the action method in grid configuration file. For example, we want to add an 'print' button on the toolbar

```ruby
class PostGrid < WulinMaster::Grid
  ...
  action :print, title: 'Print Post', icon: :print
  ...
end
```

After this, you will see an icon appear on the grid toolbar, and the item css should be `print_action toolbar_icon_print`, you can set a backgroud image for the css. For now, the available options are 'title' and 'icon' which are used to set the action text and css for each.

2.Then, create a javascript file for the action, write the click handler for it:

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

You can add this js file anywhere in the application, but we recommend to put it in `app/assets/javascripts/actions` folder

That's all, you have set up a simple print action.

In addition, you can call `load_default_actions` method to add default toolbar items of WulinMaster, they are 'Create', 'Delete', 'Edit', 'Audit', 'Import' and 'Export'(if you have installed **WulinAudit**, **WulinImport** and **WulinAudit** gem).

Also, if you want to extend WulinMaster gem or to create your own gem which include some new actions and you want to make them to be default actions, you can call the API method `add_default_action` like:

```ruby
# param1         : :import - action name
# param2 (option): { icon: :file_upload } - select default icon from https://material.io/icons/
# param3 (option): { global: true } - action available when no record is selected, such as Create, Import, Export etc.
WulinMaster::Grid.add_default_action :import, icon: :file_upload, global: true
```

#### Grid behaviors

WulinMaster grid has a lot of events, like `onDataLoaded`, `onViewportChanged`, etc. (see `slick.grid.js` for details). If you want to bind some event handlers, grid behavior gives you an easy and well-organized way. Let's look at an example:

1.First, call the `#behavior` method in grid configuration file, we want to add an `show_total_price` behavior after grid data loaded.

```ruby
class OrderGrid < WulinMaster::Grid
  ...
  behavior :show_total_price
  ...
end
```

2.Then, create a javascript file for this behavior, write the event and handler for it:

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

You can add this js file anywhere in the application, but we recommend to put it in *app/assets/javascripts/behaviors* folder

That's all, you have set up a simple behavior.

In addition, we already provide some behaviors in `wulin_master` gem, you can check them out in *wulin_master/app/assets/javascripts/master/behaviors* folder.If you want to disable some default behaviors for the grid in your application, you are able to call `remove_behaviors` method. Also, if you extend WulinMaster gem or create your own gem which include some new behaviors and you want to make them to be default behavior for all grids, you can call the API method `add_default_behavior(YOUR_BEHAVIOR)` to do that.

#### Configuration for different screens

In many cases, a grid may appear on different screens for different purpose, so it may have different styles, options, actions or behaviors between screens. It is easy to implement that.

1.If you configure the grid in screen class file, the grid options are only valid on this screen, like:

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

2.But, if you configure the grid in grid class, you should specify which screens are available or not by using `:only` and `:except` option, like:

```ruby
class PostGrid < WUlinMaster::Grid
  ...
  width: '30%', only: [:MagazineScreen]
  action :print_post, except: [:MagazineScreen]
  behavior :show_author
  ...
end
```

As above, only in `MagazineScreen`, the `PostGrid`'s width will be '30%', the `print_post` action will appear in all screens except `MagazineScreen`, however, the `show_author` behavior has not been set the `:only` nor `:except` option, so it will be available to `PostGrid`s in all screens.

The `:only` and `:except` option can be appended to all methods of grid styles, options, actions and behaviors.

#### Configuration for different users

Permission management is a necessary aspect for the application. If you are using `wulin_permits` (the permission management plugin of wulin series), you can easily configure what screens or grid actions be visible for a certain kinds of users.

For screen permission, you can configure like:

```ruby
submenu 'Orders' do
  # the "order#cud" is a auto-generated permission by wulin_permits, you can configure it in 'Roles Permissions' setting
  item CreateOrderScreen, authorized?: lambda { |user| user.has_permission_with_name?('order#cud') }
  item OrderScreen
end
```

For action permission, configure like:

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

**Use case**: `Travel` belongs to `Position` and `Position` belongs to `Person`. We want to show `first_name` field of a person in `Travel` grid with sorting and filtering available.

For the case above, we could work it around by configurations as followings:

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

As one of WulinMaster components, `WulinMaster::Panel` can be also rendered in the screen like `WulinMaster::Grid`, but the configuration is much easier:

```ruby
# app/panels/order_booking_panel.rb

class OrderBookingPanel < WulinMaster::Panel
  fill_window false
  width '100%'
  height '50%'
  partial 'order_booking'
end
```

Panel configuration can use the same methods used in grid styles since they are defined in `WulinMaster::ComponentStyling` which included both in `WulinMaster::Grid` and `WulinMaster::Panel`.

The special configure option for Panel is `partial`. By default, the corresponding html partial file for a Panel should be put in *app/views/panel_partials*, and the file name should be the underscore version of panel class name, but if you want to use another partial name, you can set partial option by yourself.

### 3. Screen configuration

#### Basic screen configuration

A most basic screen configuration needs to provide nothing, it will request the url path which get from the screen class name, like `OrderScreen` will request path `orders?screen=OrderScreen` unless you set path option, and will display nothing until you add grids and panels, they will be rendered on the screen one by one.

```ruby
class OrderScreen < WulinMaster::Grid
  path '/orders/booking'  # optional

  title 'Orders Booking'  # optional

  panel OrderBookingPanel, height: '50%'
  grid OrderGrid, height: '50%'
end
```

#### Grid and Panel options in screen

This has been explained in 'Grid configuration/Configuration for different screens' part, the option you set for a panel or a grid in this screen class will be valid only in this screen.

#### Master-Detail grids

In many cases, we need to display 2 grids in one screen whose model relationship is `belong_to` and `has_many`, we have built a helper method `master_grid` in wulin_master gem to enable you to easily implement this. Eg, you want to show `AuthorGrid` and `PostGrid` in one screen, when select one author in `AuthorGrid`, the `PostGrid` will show his/her posts.

```ruby
class ArticleScreen < WulinMaster::Screen
  title 'All Articles'
  path 'authors'

  grid AuthorGrid, height: '50%'
  grid PostGrid, height: '50%', master_grid: 'AuthorGrid', eager_loading: false
end
```

In above example, `eager_loading` is set to `false` to make `PostGrid` not loading until selecting an author.

Sometimes, there is no master grid existing, but you still want to had the detail grid filtered by a given master id, in this case you can use `master_model` instead of `master_grid`. In fact, the two options both add a hidden column into detail grid in purpose of filtering, generally the column name is the foreign key name between the detail grid model and the master model. Let's make a little change of previous example and use `master_model` option:

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

In the above example, there is no `Author` grid, but supposing a dropdown list #author_list located in AuthorSelectionPanel, when we select one author from the dropdown, the data in PostGrid will be get filtered by invoking the javascript method `addFilter`.

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

In above code, action `:add_detail` must has two necessary options, `model` and `screen`: `model` specifies what kind of record you want to add, `screen` is the screen that contains the grid which you can pick records from.

`add_detail` action can has the option `reload_master`, if set to true, the master grid will be reloaded automatically once adding detail records is over. (This option can also be applied to `:delete` action when it is used as 'remove detail').

##### `detail_model` option

We often meet self-related model when 'add detail', imagine that there is a `Employee` model, and an employee can has many subordinates which are also employees.

```ruby
class Employee < ActiveRecord::Base
  has_many :subordinates, through: :staff_relations    # staff_relations is the middle table
  has_many :bosses, through: :staff_relations
end
```

Now we can set grids to add subordinates for the selected employee, like following code:

```ruby
class EmployeeGrid < WulinMaster::Grid
  ...
  action :add_detail, model: 'subordinates', screen: 'AddSubordinateScreen', title: 'Add Subordinates', icon: 'add', only: [:BossScreen]
end

class AddSubordinateScreen < WulinMaster::Screen
  grid EmployeeGrid, title: 'Available Employees', master_model: 'bosses', detail_model: 'subordinates'
end
```

In the above code, we must specify `detail_model` as 'subordinates' for `EmployeeGrid` in `AddSubordinateScreen`, otherwise the `EmployeeGrid` will use the default model 'employee' to find the relationship which will cause error.

#### Define Inclusion-Exclusion grids

Inclusion-Exclusion grids is also a very common case. For example, there are 3 grids in the screen, the models of 2 grid has relationship `has_and_belongs_to_many` or `has_many`, the third grid comes from the join table or through model. Let's look at following example:

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

We have `PeopleGroup` model, `People` model, they have `has_many` relation with each other, their relation through model is `PeopleGroupsPeople`, we want to build above screen to manage the groups when we select a group, the left bottom grid will show people of this group, the right bottom grid will show people who are not in the group yet, and you can utilize the middle panel to add/remove a people to/from the group. We can implement as the following:

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

In the above screen configuration, we use helper methods `include_of`, `exclude_of` to specify the inclusion and exclusion grids, also we used `WulinMaster::InclusionExclusionPanel` which is pre-defined in wulin_master gem, but it has to know which is the inclusion grid and which is the exclusion grid by set options `inclusion_grid` and `exclusion_grid`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b new-feature`)
3. Commit your changes (`git commit -am 'Added an awesome feature'`)
4. Push to the branch (`git push origin new-feature`)
5. Create new Pull Request

## License

WulinMaster is released under the MIT license.
