
Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.

  root 'static_pages#home'
  
  match '/help',          to: 'static_pages#help',    via: :get
  match '/home',          to: 'static_pages#home',    via: :get
  match '/dev',           to: 'static_pages#dev',     via: :get
  # match '/update',        to: 'static_pages#dev',     via: :get #Why is lack of this throwing an error?
  match 'debtor/search',  to: 'debtors#search',       via: :get, as: 'search'
  
  match '/import',        to: 'import#create',        via: :post
  match '/import',        to: 'import#new',           via: :get
  match '/import/status', to: 'import#status',        via: :get
  
  match '/email',         to: 'debts#preview_email',  via: :get
  match '/email/send',    to: 'debts#send_email',     via: :post 

  resources :debtors 
  resources :debts, except: :destroy do 
    resources :mail_logs, except: :destroy
  end

  match '/letter',        to: 'static_pages#modeloSC_724', via: :get
  
  # get "static_pages/home"
  # get "static_pages/help"
  
  # for sse
  # resources :status, only :index

end

