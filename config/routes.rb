Rails.application.routes.draw do
  
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # 富文本上传路由
  mount RedactorRails::Engine => '/redactor_rails'
  
  get 'app/download' => 'home#download'
  get 'app/install'  => 'home#install'
  
  # 网页文档
  resources :pages, path: :p, only: [:show]
  
  # 获取二维码图片
  # /qrcode?text=http://www.baidu.com
  get 'qrcode' => 'home#qrcode', as: :qrcode
  
  # /redpack?id=3848484
  
  get 'hb_test' => 'home#qrcode_test'
    
  namespace :front, path: '' do 
    # 网页认证登录
    # get    'login'    => 'sessions#new',       as: :login
    get    'redirect' => 'sessions#save_user', as: :redirect_uri
    delete 'logout'   => 'sessions#destroy',   as: :logout
    get 'app_auth' => 'sessions#app_auth'
    
    get 'redpack'       => 'redpacks#detail', as: :redpack
    
    # redpack/result?id=3838939393
    get 'redpack/result' => 'redpacks#result', as: :redpack_result
    
    # get 'auth/redirect' => 'sessions#app_auth', as: :auth_redirect_uri
    
    # post redpack/take?id=4848474&sign=3838392
    # post 'redpack/take' => 'redpacks#take', as: :redpack_take
    
    post 'pay/wx_notify' => 'home#wx_notify', as: :wx_notify
    
  end
  
  # get 'wx/redirect' => 'front/home#wap_auth', as: :wx_redirect_uri
  # get 'qq/redirect' => 'front/home#wap_auth', as: :qq_redirect_uri
  get 'auth/redirect' => 'front/home#wap_auth', as: :auth_redirect_uri
  
  # 队列后台管理
  require 'sidekiq/web'
  authenticate :admin_user do
    mount Sidekiq::Web => 'sidekiq'
  end
  
  # # API 文档
  mount GrapeSwaggerRails::Engine => '/apidoc'
  # #
  # # API 路由
  mount API::Dispatch => '/api'
  
  match '*path', to: 'home#error_404', via: :all
end
