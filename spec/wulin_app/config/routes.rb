# frozen_string_literal: true

Rails.application.routes.draw do
  resources :posts
  resources :people
  root to: 'homepage#index'
end
