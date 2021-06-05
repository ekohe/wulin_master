# frozen_string_literal: true

Rails.application.routes.draw do
  resources :posts
  resources :people
  resources :teachers
  root to: 'homepage#index'
end
