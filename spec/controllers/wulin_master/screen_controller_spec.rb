# frozen_string_literal: true

require 'spec_helper'
require 'wulin_master/utilities/variables'
require './lib/wulin_master/actions'
require './app/controllers/wulin_master/screen_controller'

class PeopleTestController < PeopleController
  attr_accessor :query
end

describe PeopleTestController, type: :controller do
  describe 'Includes WulinMaster::Actions' do
    before :each do
      @screen = PersonScreen.new(controller)
      @grid = @screen.grids.first
      allow(controller).to receive(:grid).and_return(@grid)
      allow(controller).to receive(:params).and_return({})
      routes.draw { get :index, to: 'people_test#index' }
    end

    describe 'get :index' do
      it 'should render index template if request format :html' do
        get :index, format: :html
        expect(response).to render_template(:index)
      end

      describe 'format: :json' do
        before :each do
          controller.query = Person
        end

        it 'should invoke methods of building filters, orders and renderings' do
          expect(controller).to receive(:construct_filters)
          expect(controller).to receive(:parse_ordering)
          expect(controller).to receive(:render_json)
          get :index, format: :json
        end

        it 'should render json object as the response' do
          json_obj = { offset: 100, total: 1000, count: 100, rows: %w[Maxime Ben] }.to_json
          allow(controller).to receive(:construct_filters).and_return(true)
          allow(controller).to receive(:parse_ordering).and_return(true)
          allow(controller).to receive(:render_json).and_return(json_obj)
          get :index, format: :json
          expect(response.body).to eq(json_obj)
        end

        it 'should apply filter on the grid when calling #construct_filters if given filter params' do
          allow(controller).to receive(:params).and_return(filters: [{column: 'first_name', value: 'Ben', operator: 'equals'}])
          expect(@grid).to receive(:apply_filter).with(Person, 'first_name', 'Ben', 'equals')
          controller.send(:construct_filters)
        end
      end
    end
  end
end
