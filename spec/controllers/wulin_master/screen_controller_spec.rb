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
          controller.instance_variable_set(:@per_page, 200)
        end

        it 'should invoke methods of building filters, orders and renderings' do
          expect(controller).to receive(:construct_filters)
          expect(controller).to receive(:parse_ordering)
          expect(controller).to receive(:parse_pagination)
          expect(controller).to receive(:render_json)
          get :index, format: :json
        end

        it 'should render json object as the response' do
          json_obj = { offset: 100, total: 1000, count: 100, rows: %w[Maxime Ben] }.to_json
          allow(controller).to receive(:construct_filters).and_return(true)
          allow(controller).to receive(:parse_ordering).and_return(true)
          allow(controller).to receive(:parse_pagination).and_return(true)
          allow(controller).to receive(:render_json).and_return(json_obj)
          get :index, format: :json
          expect(response.body).to eq(json_obj)
        end

        it 'should apply filter on the grid when calling #construct_filters if given filter params' do
          allow(controller).to receive(:params).and_return(filters: [{column: 'first_name', value: 'Ben', operator: 'equals'}])
          expect(@grid).to receive(:apply_filter).with(Person, 'first_name', 'Ben', 'equals')
          controller.send(:construct_filters)
        end

        it 'should do nothing when calling construct_filters if no filter params given' do
          expect(@grid).not_to receive(:apply_filter)
          controller.send(:construct_filters)
        end

        it 'should invoke limit and offset on the query according to params count and offset when calling parse_pagination if params given' do
          limited = double(:limited)
          offseted = double(:offseted)
          controller.instance_variable_set(:@offset, 200)
          allow(controller).to receive(:params).and_return(count: 100, offset: 200)
          allow(controller.query).to receive(:limit).and_return(limited)
          allow(limited).to receive(:offset).and_return(offseted)
          expect(controller.query).to receive(:limit).with(100)
          expect(limited).to receive(:offset).with(200)
          controller.send(:parse_pagination)
        end

        it 'should invoke limit and offset on the query with default value when calling parse_pagination if params not given' do
          limited = double(:limited)
          offseted = double(:offseted)
          controller.instance_variable_set(:@offset, 0)
          allow(controller.query).to receive(:limit).and_return(limited)
          allow(limited).to receive(:offset).and_return(offseted)
          expect(controller.query).to receive(:limit).with(200)
          expect(limited).to receive(:offset).with(0)
          controller.send(:parse_pagination)
        end

        it 'should apply order on the grid when calling parse_ordering if params given' do
          allow(@grid).to receive(:sql_columns).and_return(['first_name'])
          allow(controller).to receive(:params).and_return(sort_col: 'first_name', sort_dir: 'DESC')
          expect(@grid).to receive(:apply_order).with(Person, 'first_name', 'DESC')
          controller.send(:parse_ordering)
        end

        it 'should invoke order on query with default value when calling parse_ordering if params not given' do
          allow(@grid).to receive(:sql_columns).and_return(['first_name'])
          expect(@grid).to receive(:apply_order).with(Person, 'first_name', 'ASC')
          controller.send(:parse_ordering)
        end

        it 'should return a json object after calling render_json' do
          allow(@grid).to receive(:arraify).and_return(['Maxime', 'Ben'])
          expect(@grid).to receive(:arraify)
          result = controller.send(:render_json)
          expect(result).to be_a(String)
          expect(result).to include('offset')
          expect(result).to include('total')
          expect(result).to include('count')
          expect(result).to include('rows')
          expect(result).to include('["Maxime","Ben"]')
        end
      end
    end
  end
end
