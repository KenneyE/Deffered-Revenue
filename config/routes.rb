Rails.application.routes.draw do
  root to: 'entries#index'
  resources :entries do
    collection {post :import}
    collection {delete :clear}
  end

  post '/accrual_year', to: 'entries#accrual_year'
end
