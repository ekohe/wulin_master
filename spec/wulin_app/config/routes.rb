# frozen_string_literal: true

Rails.application.routes.draw do
  resources :clients
  resources :courses
  resources :trainings
  resources :addresses
  resources :posts
  resources :people
  resources :teachers
  root to: "homepage#index"
end
