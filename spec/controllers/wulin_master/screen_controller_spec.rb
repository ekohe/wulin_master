# frozen_string_literal: true

require 'spec_helper'
require 'wulin_master/utilities/variables'
require './lib/wulin_master/actions'
require './app/controllers/wulin_master/screen_controller'

class PeopleTestController < PeopleController
  attr_accessor :query
end

describe PeopleTestController, type: :controller do
  def mock_person(stubs = {})
    @mock_person ||= mock_model(Person, stubs).as_null_object
  end

  describe 'Includes WulinMaster::Actions' do
    before :each do
      @screen = PersonScreen.new(controller)
      @grid = @screen.grids.first
      allow(controller).to receive(:grid).and_return(@grid)
    end

    describe 'get :index' do
      it 'should render index template if request format :html' do
        routes.draw { get :index, to: 'people_test#index' }
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
          allow(@grid).to receive(:arraify).and_return(%w[Maxime Ben])
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

    describe 'post :create' do
      before :each do
        routes.draw { post :create, to: 'people_test#create' }
      end

      describe 'with valid params' do
        before :each do
          allow(@grid.model).to receive(:new).and_return(mock_person(save: true))
          post :create, format: :json
        end

        it 'assigns a newly created record as @record' do
          expect(assigns(:record)).to eq(mock_person)
        end

        it 'render success json if format json' do
          expect(response.body).to include('"success":true')
        end
      end

      describe 'with invalid params' do
        it 'assigns a newly created but unsaved record as @record' do
          allow(@grid.model).to receive(:new).and_return(mock_person(save: false))
          post :create, format: :json
          expect(assigns(:record)).to eq(mock_person)
        end

        it 'render failure json and error message if format json' do
          allow(@grid.model).to receive(:new).and_return(mock_person(save: false))
          allow(mock_person(save: false)).to receive(:errors).and_return('person error')
          post :create, format: :json
          expect(response.body).to eq({success: false, error_message: 'person error' }.to_json)
        end
      end
    end

    describe 'post :update' do
      before :each do
        routes.draw { put :update, to: 'people_test#update' }
      end

      context 'with valid params' do
        let(:valid_params) { { id: 37, item: { these: 'params' } } }

        before do
          allow(@grid.model).to receive(:find).with(['37']).and_return([mock_person])
        end

        it 'assigns the requested records as @records' do
          put :update, params: valid_params
          expect(assigns(:records)).to eq([mock_person])
        end

        it 'updates the requested record' do
          expect(mock_person).to receive(:update_attributes!)
          put :update, params: valid_params
        end

        it 'render success json if format json' do
          put :update, params: valid_params
          expect(response.body).to eq({success: true}.to_json)
        end
      end

      context 'with invalid params' do
        it 'assigns the records as @records' do
          allow(@grid.model).to receive(:find).with(['thirty seven']).and_return([mock_person])
          put :update, params: {id: 'thirty seven', item: {'these' => 'params'}}
          expect(assigns(:records)).not_to eq(nil)
        end

        it 'render failure json and error message if format json' do
          allow(@grid.model).to receive(:find).with(['thirty seven']).and_return([mock_person])
          errors = double(:error, empty?: false, full_messages: double)
          allow(errors.full_messages).to receive(:join).and_return('person error')
          allow(mock_person(update_attributes: false)).to receive(:errors).and_return(errors)
          put :update, params: {id: 'thirty seven', item: {'these' => 'params'}}, format: :json
          expect(response.body).to eq({success: false, error_message: 'person error' }.to_json)
        end
      end
    end

    describe 'delete :destroy' do
      let(:ids) { ['1'] }

      before :each do
        routes.draw { put :update, to: 'people_test#destroy' }
      end

      it 'success to destroy the requested county' do
        person = mock_person(id: 1, destroy: 1)
        people = [person]

        allow(@grid.model).to receive(:find).with(ids).and_return(people)

        expect(@grid.model).to receive(:transaction).and_yield
        expect(people).to receive(:each).and_yield(person)
        expect(person).to receive(:destroy)

        delete :destroy, params: { id: '1' }, format: :json
        expect(response.body).to eq({success: true}.to_json)
      end

      it 'fails to destroy the requested county' do
        errors = double(:error, full_messages: double)
        allow(errors.full_messages).to receive(:join).and_return('can\'t destroy')
        person = mock_person(id: 1, destroy: nil, errors: errors)
        people = [person]

        allow(@grid.model).to receive(:find).with(ids).and_return(people)

        expect(@grid.model).to receive(:transaction).and_yield
        expect(people).to receive(:each).and_yield(person)

        expect(person).to receive(:destroy)

        delete :destroy, params: { id: '1' }, format: :json
        expect(response.body).to eq({ success: false, error_message: 'can\'t destroy' }.to_json)
      end
    end

  end
end
