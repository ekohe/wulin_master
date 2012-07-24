#Setup

##Install WulinMaster gem

  Put 'gem wulin_master' to your Gemfile, and run `bundle` command to install it:
    
    gem 'wulin_master'
    
###1.Run `rails g wulin_master:install` generator
  
    rails g wulin_master:install
  
  It will: 
  
    create  app/controllers/homepage_controller.rb # All menu will config in this file
    create  config/initializers/wulin_master.rb    # Some global configurations will localed in this file
     route  root :to => 'homepage#index'           # Set the homepage route
    
###2.Remove origin files of Rails app

  For apply WulinMaster layout, you need to remove two origin files of Rails app

    rm public/index.html
    rm app/views/layouts/application.html.erb   # WulinMaster provide a beautful layout template already
    
  Then start you app and visit it, you will look at the initialized homepage with a example menu.
  
###3.Remove Jquery lib require

  Remve jquery and jquery_ujs require in application.js
  
    //= require jquery
    //= require jquery_ujs
  
###4.Create a new screen and grid
  
  WulinMaster provide a generator to generate screen and grid.
  
    rails g wulin_master:screen_and_grid Post title content:text
    
##Setup WulinOauth

### Install

  GridState for current user was supported. but first, you must have **current_user**.
  
  You can use you own authentication process, and also can use `WulinOauth`.
  
  Put 'gem wulin_oauth' to your Gemfile, and run `bundle` command to install it:
  
      gem 'wulin_oauth'
  
  And then create <em>wulin_oauth.yml</em> config file under config folder.Please check WulinOauth documents.
  
###Config
  
  Put some code for wulin_oauth in <em>application_controller.rb</em>
  
    #app/controllers/application_controller.rb
    before_filter :require_login
    before_filter :set_current_user

    def set_current_user
      User.set_current_user(current_user)
    end
  
##Enabled GridState
  
  Run generator to create migrate file of grid_state modle:
  
    rails g wulin_master:grid_states
    
  And then run `rake db:migrate` to create grid_states table.
  
  
##Setup WulinExcel

  What you need to do is put 'gem wulin_excel' to your Gemfile, and run `bundle` command to install it,
  
  then you can export grid with excel file.
  
    
