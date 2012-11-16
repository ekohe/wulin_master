# WulinMaster

WulinMaster is a grid plugin base on ruby on rails and [SlickGrid](https://github.com/mleibman/SlickGrid). It provide powerfull generator 
and other tools to make grids easy to build, it also provides flexible configuration, you can easily configure your grid, a beautiful ui base on jqueryui and other good features.
       

## Installation

### 1. Put 'gem wulin_master' to your Gemfile:

    gem wulin_master

### 2. Run bundler command to install the gem:

    bundle install
    
### 3. After you install wulin_master gem, you need run the generator to install the base building:

    bundle exec rails g wulin_master:install

   This will create:

    create  app/controllers/homepage_controller.rb
    create  config/initializers/wulin_master.rb
    route  root :to => 'homepage#index'
  
   Now, you can config wulin_master in *config/initializers/wulin_master.rb*

### 4. Then you need run the generator:

    bundle exec rails g wulin_master:grid_states
   
   It will generator *db/migrate/<timestamp>_create_grid_states.rb* migrate file to your app,
   *_grid_states_* table is used for store the grid states for each user. 
   It will store *column width*,*sort column*,*column order*,*visibility columns*,
   *filter states* for each user.

   Run with *bundle exec rails g* for get generator list.

### 5. Update some rails default configs

   Remove the rails default view layout, because wulin_master users its own layout

   In application.rb, add autoload_paths for screens folder: 
   config.autoload_paths += Dir[Rails.root.join('app', 'screens', '{**}')]

## Getting Started

### 1. Generator resource files

  Assume generating a new grid called *post*, run the generator:
    
    bundle exec rails g wulin_master:screen_and_grid post name:string age:integer

  This will create:
   
    create  db/migrate/20110919093453_create_posts.rb
    create  app/controllers/posts_controller.rb
    create  app/screens/post_screen.rb
    create  app/grids/post_grid.rb
    create  app/models/post.rb
    create  app/views/posts
    route  resources :posts

   `name:string age:integer` are the columns of the grid, same as the `[field:type field:type]` 
   option of *scaffold* generator.

### 2. Run migration

    bundle exec rake db:migrate
   
### 3. Configure grid

   You can configure your grid like following:

    # app/grids/post_grid.rb
    class PostGrid < WulinMaster::Grid
      title 'Posts'   # Title for this grid

      model Post      # ActiveRecord model for this grid

      path '/hotels'  # Url path for this grid, correspond to <code>resources :posts</code> in routes.rb

      # Style options
      fill_window false 
      width: '500px' 
      height: '500px'  # options for this grid 

      # Other options
      cell_editable false
      eager_loading true

      # Grid actions which appear as a toolbar item for each
      action :publish_post
      action :see_author
      ...

      load_default_actions  # Call this method to add default toolbar items for this grid (default actions has been defined in the wulin_master gem)

      # Grid behaviors which act as grid event handler for each
      behavior :highlight
      behavior :show_total_price
      ...
      
      # Define the grid columns
      column :title, sortable: true, visible: true, editable: true
      column :category, width: 100, label: "Category"
      column :created_at, editor: "TimeCellEditor"
      ...
    end
   
### 4. Configure screen

   Grid is located in screen, one screen can has one or multiple grids,you can put any grid to one
   screen with *grid* method, and config the *title* and the *path* method.
   
    # app/screens/post_screen.rb:
    class PostScreen < WulinMaster::Screen
      title 'All Posts'

      path '/posts'

      grid PostGrid
    end

### 5. Configure controller
    
   Config resource controller which inherited from `WulinMaster::ScreenController`, to tell the controller which screens it controls, and you can also write customized callbacks
   
    # app/controllers/posts_controller.rb
    class PostsController < WulinMaster::ScreenController
      controller_for_screen PostScreen

      add_callback :query_filters_ready, :add_scope
      add_callback :query_ready, :state_filter
      

      protected
      
      # pass params
      # +@query+ now is a ActiveRecord class
      def add_scope
        @query = (params[:add_scope] == 'true' ? @query.scope : @query) 
      end

      # Set filter for grid source
      # +@query+ is a ActiveRecord::Relation object
      def state_filter
        @query = @query.where(state: params[:state] || 'ok')
      end
    end


## Usage

### 1. Grid configuration

#### Basic grid configuration
      
A basic grid configuration needs to provide model and columns. Title and path are optional, they will be automatically assigned according to the grid class name and model.

    class PostGrid < WulinMaster::Grid
      model Post

      title 'All posts'   # optional
      path '/blogs'       # optional

      column :title
      column :content
      column :author
    end


#### Column options

A column can be a real field in the database table of current model, or virtual attribute of the model, even the field of other model. You can attach one or more options to define attributes for the column.

  `:visible`
  Default is true, if set false, the column will be visible initially (Can make it visible from column picker).

  `:editable` 
  Default is true, if set false, the grid cell of this column can not be edited.

  `:sortable`
  Default is true, if set false, this column can not be sorted.
  
  `:formable`
  Control this column appear in the create and update dialog form or not. You can set it to true or false, either pass an array like [:new, :edit] or one of them.
  
    class PostGrid < WulinMaster::Grid
      ...
      
      column :author, formable: true          # author column will appear in both create and update dialog form.
      column :title, formable: [:new, :edit]  # same as `formable: true`.
      column :content, formable: [:new]       # content column will appear in only create dialog form.
      
      ...
    end

  `:label`
  Controll the text displayed on the column header, if not set, the column label will be same with column name.

  `:width`
  Controll the column initial width, default is 150.

  `:option_text_attribute`
  Sometimes you may want to show a column from another model, in this case, you can define the column name as the model name, and set :option_text_attribute to be the column name,         
  eg:

    class PostGrid < WulinMaster::Grid
      ...

      column :author, option_text_attribute: 'name'

      ...   
    end

  `:through`
  You can also show a column from another model by using :through option, in this case, the above example becomes:

    class PostGrid < WulinMaster::Grid
      ...
      column :name, through: 'author'
      ...
    end

  However, this approach has a shortcoming, if the Post model also has a column 'name', there will be a conflict.

  `:join_aliased_as`
  When the grid needs to show 2 or more columns which come from same table and same column, you can define :join_aliased_as for one column to set the alias to avoid conflict when doing sql join.

  `:sql_expression`
  This option is very special and rarely used. It is only used when you want to do some special sql operation, like sorting or filtering vitural attribute by sql.

  `:editor`
  By default, if the column is editable, the type of cell editor is decided from the column type: string, integer, boolean etc, so you don't need to specify the editor handly for general cases. But sometimes, you have to define the :editor, for example, 'SelectEditor' renders a dropdown of possible values of the column, 'TimeCellEditor' renders a timepicker for the column which is datetime type, etc. 
  And, you can define a new type of editor yourself, the editor definitions are all located in slick.editor.js

  `:formatter`
  This option controls how the value displayed in the grid cell, for example: 'MoneyFormatter' renders the number value as money format, 'RightFormatter' renders the value to align right in the cell, etc.
  And, you can define a new formatter yourself, the formatter definitions are all located in slick.editor.js

  `:choices`
  This option should be used together with 'SelectEditor', it specifies the options of the dropdown. Its value can be an array, a url path which can return a response of array, or a hash in very rare case.
  
  `:file`
  If this column is a file field, like image or any file, you should add this option and set it to true. It will use file_field in the new/edit form.
  
  `:password`
  If this column is a password or password_confirmation, you should add this option and set it to true. It will use password_field in the new/edit form.

  `:depend_column`
  This option should be used when the :choices option specifying a hash value. When you choose a value, say 'k1', from the column that :depend_column specifies, then you edit the current column, the dropdown will display options which are the values of key 'k1' in the choices hash. Here is an example:

    class ServiceGrid < WulinMaster::Grid
      UNIT_OPTIONS = ["piece", "match", "mn", "slot", "match-day", "match-period", "pkg"]
      UNIT_SCALE_OPTIONS = {'piece' => [], 
                      'match' => [], 
                      'mn' => ['10','30','60'], 
                      'slot' => ['pre','post'], 
                      'match-day' => [], 
                      'match-period' => [],
                      'pkg' => []
                    }
      ...

      column :unit, :choices => UNIT_OPTIONS, :editor => "SelectEditor"
      column :unit_scale, :choices => UNIT_SCALE_OPTIONS, :depend_column => :unit, :editor => "SelectEditor"

      ...
    end 

  For above example, if you choose 'mn' for :unit column, the available values for :unit_scale will be ['10','30','60'].

  `:currency`
  This option should be used when the :formatter is 'MoneyFormatter', you can specify it as '$' or '€', or other type of currencies.


#### Grid styles

The style configuration of grid can controll the css of the grid. Now the style configuration methods are all defined in WulinMaster::ComponentStyling module (grid and panel are both component), you can use these methods in grid class file, or as an option of grid in screen class file, like:

    class PostGrid < WulinMaster::Grid
      width "50%"
      height "30%"
    end

    or

    class PostScreen < WulinMaster::Screen
      grid PostGrid, width: "50%", height: "30%"
    end 

  Followings are the available style methods:

  `:height`
  Controll the component height, the value can be a number (default unit is px) or a percentage string

  `:width`
  Controll the compoment width, the value can be a number (default unit is px) or a percentage string

  `:css`
  Set the compoment whole styles, the value is a string of css styles, like "width:300px;height:200px;float:left"

  `:fill_window`
  Set the component fill the whole window or not, the default value is true.


#### Grid options

The option configuration of grid can set some attributes of the grid. These methods can be used in grid class file, or as an option of grid in screen class file, like the usage of grid styles. Followings are the available option methods:

  `:cell_editable`
  Set the whole grid editable or not, default is true

  `:column_sortable`
  Set the all columns sortable or not, default is true

  `:hide_header`
  Set the grid hide header or not, default is false

  `:eager_loading`
  Set the grid load data or not when rendered, default is true. If set false, the grid won't load data until set filters.

  `:multi_select`
  The default is true, means that you can select multiple rows in the grid. If set false, can only select one row.


#### Grid actions

If you want to set toolbar items on the grid, grid actions provide a convenient way to do that. Let's look an example:

1.First, call the action method in grid configuration file, we want to add an 'print' button on the toolbar

    class PostGrid < WulinMaster::Grid
      ...
      action :print, title: 'Print Post', icon: 'print'
      ...
    end

After this, you will see a item 'Print Post' appear on the grid toolbar, and the item css should be 'print_action toolbar_icon_edit', you can set a backgroud image for the css. For now, the available options are 'title' and 'icon' which are used to set the action text and css for each.

2.Then, create a javascript file for the action, write the click handler for it:

    # app/assets/javascripts/actions/print.js
    WulinMaster.actions.Print = $.extend({}, WulinMaster.actions.BaseAction, {
      name: 'print',

      handler: function() {
        // write your logic when click the toolbar item
        alert("print");
      }
    });

    WulinMaster.ActionManager.register(WulinMaster.actions.AddOrder);

  You can add this js file anywhere in the application, but we recommend to put it in *app/assets/javascripts/actions* folder

  That's all, you have set up a simple print action. 

In addition, you can call `load_default_actions` method to add default toolbar items of WulinMaster, they are 'Add', 'Delete', 'Edit',
'Filter' and 'Audit' (if you have installed **WulinAudit** gem). Also, if you extend WulinMaster gem or create your own gem which include some new actions and you want to make them to be default actions, you can call the api method `add_default_action(YOUR_ACTION)` to do that.


#### Grid behaviors

WulinMaster grid has a lot of events, like OnDataLoaded, onViewportChanged, etc.(see slick.grid.js for details). If you want to bind some event handlers, grid behavior gives you a easy and well-organized way. Let's look an example:

1.First, call the behavior method in grid configuration file, we want to add an `show_total_price` behavior after grid data loaded.

    class OrderGrid < WulinMaster::Grid
      ...
      behavior :show_total_price
      ...
    end

2.Then, create a javascript file for this behavior, write the event and handler for it:

    # app/assets/javascripts/behaviors/show_total_price.js
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
        var datas = this.grid.getData();
        for(var i in datas) total += datas[i].price
        alert(total);
      },
    });

    WulinMaster.BehaviorManager.register("show_total_price", WulinMaster.behaviors.ShowTotalPrice);

You can add this js file anywhere in the application, but we recommend to put it in *app/assets/javascripts/behaviors* folder

That's all, you have set up a simple behavior.

In addition, we already provide some behaviors in `wulin_master` gem, you can view them in *wulin_master/app/assets/javascripts/master/behaviors* folder, they are applied to all grids. But if you want to disable some default behaviors for the grid in your application, you can call `remove_behaviors` method. Also, if you extend WulinMaster gem or create your own gem which include some new behaviors and you want to make them to be default behavior for all grids, you can call the api method `add_default_behavior(YOUR_BEHAVIOR)` to do that. 


#### Configuration for different screens

In many cases, a grid may appear on different screens for different purpose, so it may have different styles, options, actions or behaviors between screens. It is easy to implement that.

1.If you configure the grid in screen class file, the grid options are only applied in this screen, like: 

    class PostScreen < WulinMaster::Screen
      grid PostGrid, width: '30%', height: '50%', eager_loading: false, multi_select: false
      ...
    end 

    class MagazineScreen < WulinMaster::Screen
      grid PostGrid
      ...
    end

  As above, the PostGrid options defined in PostScreen are only applied on the grid in PostScreen, will not affect the grid in MagazineScreen.

2.But, if you configure the grid in grid class, you should specify which screens will accept the options or not by using `:only` and `:except` option, like:

    class PostGrid < WUlinMaster::Grid
      ...
      width: '30%', only: [:MagazineScreen]
      action :print_post, except: [:MagazineScreen]
      behavior :show_author
      ...
    end

As above, only in MagazineScreen, the PostGrid's width will be '30%', the `print_post` action will appear in all screens except MagazineScreen, however, the `show_author` behavior has not been set the `:only` nor `:except` option, so it will be applied to PostGrid in all screens.

The `:only` and `:except` option can be appended to all methods of grid styles, grid options, grid actions and grid behaviors.


### 2. Panel configuration

As one kind of WulinMaster component, `WulinMaster::Panel` can be also rendered in the screen like `WulinMaster::Grid`, but the configuration is much easier, let's take an example:

    # app/panels/order_booking_panel.rb
    class OrderBookingPanel < WulinMaster::Panel
      fill_window false
      width "100%"
      height "50%"
      partial 'order_booking'
    end

Panel configuration can use same methods in grid styles, because these methods are defined in `WulinMaster::ComponentStyling` which included both in `WulinMaster::Grid` and `WulinMaster::Panel`.

The special configure option for Panel is `partial`. By default, the corresponding html partial file for a Panel should be put in *app/views/panel_partials*, and the file name should be the underscore of Panel class name, but if you want to use another partial name, you can set partial option handily.

Btw, we will introduce more options for `WulinMaster::Panel` in future, like header, title, etc.

### 3. Screen configuration

#### Basic screen configuration

A most basic screen configuration needs to provide nothing, it will request the url path which get from the screen class name, like OrderScreen will request path 'orders?screen=OrderScreen' unless you set path option, and will display nothing until you add grids and panels, they will be rendered on the screen one by one.

    class OrderScreen < WulinMaster::Grid
      path 'orders/booking'   # optional

      title 'Orders Booking'   # optional

      panel OrderBookingPanel, height: '50%'
      grid OrderGrid, height: '50%'
    end

#### Grid and Panel options in screen

This has been expained in section 'Grid configuration/Configuration for different screens', the option you set for a panel or a grid in this screen class will be only valid in this screen.

#### Define master-detail grids

In many cases, we need to display 2 grids in one screen whose model relationship is `belong_to` and `has_many`, we have built a helper method `master_grid` in wulin_master gem to enable you to easily implement this. Eg, you want to show AuthorGrid and PostGrid in one screen, when select one author in AuthorGrid, the PostGrid will show his/her posts.

    class ArticleScreen < WulinMaster::Screen
      title 'All Articles'
      path 'authors'

      grid AuthorGrid, height: '50%'
      grid PostGrid, height: '50%', master_grid: 'AuthorGrid', eager_loading: false
    end

In above example, `eager_loading` set to false to make PostGrid not loading until selecting an author.

Sometimes, there is no master grid existing, but you still want to had the detail grid filtered by a given master id, in this case you can use `master_model` instead of `master_grid`. In fact, the two options both add a hidden column into detail grid in porpuse of filtering, generally the column name is the foreign key name between the detail grid model and the master model. Let's make a little change of previous example and use `master_model` option:
    
    # article_screen.rb
    class ArticleScreen < WulinMaster::Screen
      title 'All Articles'

      panel AuthorSelectionPanel
      grid PostGrid, height: '50%', master_model: 'author', eager_loading: false  
      # Actually, the master_model option will add a hidden column 'author_id' into PostGrid
    end

    # author_selection.js (using jQuery)
    $('.#author_list').change(function(){
      var postGrid = gridManager.getGrid("post");
      var author_id = $(this).val();

      postGrid.master = {filter_column: 'author_id', filter_value: author_id};
      postGrid.loader.addFilter('author_id', author_id, 'equals');
    });

In above example, there is no Author grid, but supposing a dropdown list #author_list located in AuthorSelectionPanel, when we select one author from the dropdown, the data in PostGrid will be get filtered by invoking the javascript method `addFilter`.


##### add_detail action

For master-detail relationship, wulin_master provides a build-in action `add_detail`. Once you use it on detail grid, you can get a new toolbar item which can help you to add one or more detail records for the selected master record. Let's take an example:    
    
    class AuthorPostGrid < WulinMaster::Grid
      ...
      action :add_detail, model: 'post', screen: 'AddPostScreen', icon: 'add', title: 'Add Posts'
    end

    class AddPostScreen < WulinMaster::Screen
      grid PostGrid, title: 'Available Posts', master_model: 'author'
    end

In above code, action :add_detail must have two neccessary option, `model` and `screen`, `model` specifies what kind of record you want to add, `screen` is the screen that contains the grid which you can pick records from.


##### detail_model option

It is very often we meet self-related model when 'add detail', imagine that there is Employee model, and an employee can has many subordinates which are also employees.

    class Employee < ActiveRecord::Base
      has_many :subordinates, through: :staff_relations    # staff_relations is the middle table
      has_many :bosses, through: :staff_relations
    end

Now we can build grids to add subordinates for the selected employee, like following code:

    class EmployeeGrid < WulinMaster::Grid
      ...
      action :add_detail, model: 'subordinates', screen: 'AddSubordinateScreen', title: 'Add Subordinates', icon: 'add', only: [:BossScreen]
    end

    class AddSubordinateScreen < WulinMaster::Screen
      grid EmployeeGrid, title: 'Available Employees', master_model: 'bosses', detail_model: 'subordinates' 
    end

In above code, we must specify detail_model as 'subordinates' for EmployeeGrid in AddSubordinateScreen, otherwise the EmployeeGrid will use the defaul model 'employee' to find the relationship which will cause error.

#### Define inclusion-exclusion grids

Inclusion-exclusion grids is also a very common case, there are 3 grids in the screen, the models of 2 grid has relationship `has_and_belongs_to_many` or `has_many` through, the third grid comes from the join table or through model. Let's look at following example:

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

We have PeopleGroup Model, People Model, they have `has_many` relation with each other, their relation through model is `PeopleGroupsPeople`, we want to build above screen to manage the groups: when we select a group, the left bottom grid will show people of this group, the right bottom grid will show people who are not in the group yet, and you can utilize the middle panel to add/remove a people to/from the group. We can write following code:

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

In above screen configuration, we used helper methods `include_of`, `exclude_of` to specify the inclusion and exclusion grids, also we used `WulinMaster::InclusionExclusionPanel` which is pre-defined in wulin_master gem, but it has to know which is the inclusion grid and which is the exclusion grid by set options `inclusion_grid` and `exclusion_grid`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

WulinMaster is released under the MIT license.

