require 'rails_helper'
require './lib/generators/wulin_master/screen_and_grid/screen_and_grid_generator'
# require 'generator_spec/test_case'

describe WulinMaster::ScreenAndGridGenerator do
  # include GeneratorSpec::TestCase
  # destination File.expand_path("../../tmp", __FILE__)
  # arguments %w(city name:string country:string)

  before :all do
    # prepare_destination

    # mkdir ::File.join(self.test_case.destination_root, 'config')
    # routes_path = ::File.join(self.test_case.destination_root, 'config', 'routes.rb')
    # touch routes_path
    # open(routes_path, 'w') { |f|
    #   f.puts "TestApp.routes.draw do"
    #   f.puts "end"
    # }

    # run_generator
  end

  after :all do
    #rm_rf self.test_case.destination_root
  end

  specify do
    pending 'fix'
    destination_root.should have_structure {
      # test migration file
      directory "db" do
        directory "migrate" do
          migration "create_cities" do
            contains "class CreateCities < ActiveRecord::Migration"
            contains "create_table :cities do |t|"
            contains "t.string :name"
            contains "t.string :country"
          end
        end
      end
      # test routes
      directory "config" do
        file "routes.rb" do
          contains "resources :cities"
        end
      end

      directory "app" do
        # test controller
        directory "controllers" do
          file "cities_controller.rb" do
            contains "class CitiesController < WulinMaster::ScreenController"
            contains "controller_for_screen CityScreen"
            contains "controller_for_grid :city"
          end
        end
        # test model
        directory "models" do
          file "city.rb" do
            contains "class City < ActiveRecord::Base"
          end
        end
        # test grid
        directory "grids" do
          file "city_grid.rb" do
            contains "class CityGrid < WulinMaster::GridConfig"
            contains "config do"
            contains "title 'City'"
            contains " model City"
            contains "path '/cities'"
            contains "column :name"
            contains "column :country"
          end
        end
        # test screens
        directory "screens" do
          file "city_screen.rb" do
            contains "class CityScreen < WulinMaster::Screen"
            contains "title 'City'"
            contains "path '/cities'"
            contains "grid CityGrid"
          end
        end
      end
    }
  end
end
