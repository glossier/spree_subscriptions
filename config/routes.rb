Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :subscriptions, except: [:show, :destroy] do
      member do
        put :cancel
        put :renew
        put :skip
        put :undo_skip
        get :credit_card
        post :credit_card
      end
      collection do
        get :failures
        get :adjust_sku
        post :adjust_sku
      end
    end
  end

  namespace :api, defaults: { format: 'json' } do
    resources :subscriptions, except: [:create, :new, :destroy] do
      member do
        put :renew
        put :skip_next_order
        put :undo_skip_next_order
        put :pause
        put :resume
        post :create_address
        put :update_address
        put :select_address
        put :cancel
        post :create_credit_card
      end
      resources :subscription_items
    end
  end

  resources :subscriptions do
    member do
        put :pause
        put :resume
        put :cancel
        post :add_item
        get :credit_card
        post :credit_card
    end
    resources :subscription_items
  end
end
