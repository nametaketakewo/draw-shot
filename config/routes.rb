Rails.application.routes.draw do

  match 'images' => 'images#index', via: [:get, :post]
  match 'compare' => 'images#compare', via: :post

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
