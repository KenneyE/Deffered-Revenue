Rails.application.routes.draw do
  root to: 'entries#index'
  resources :entries do
    collection {post :import}
    collection {delete :clear}
  end

  post '/accrue', to: 'entries#accrue'
end
