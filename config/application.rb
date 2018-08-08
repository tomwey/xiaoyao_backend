require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CentralServices
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths.push(*%W(#{config.root}/lib))
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Beijing'
    
    # 确保app配置文件存在
    if Rails.env.development?
      %w(config redis database secrets).each do |fname|
        filename = "config/#{fname}.yml"
        next if File.exist?(Rails.root.join(filename))
        FileUtils.cp(Rails.root.join("#{filename}.example"), Rails.root.join(filename))
      end
    end
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    # config.i18n.default_locale = "zh-CN"
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = "zh-CN"
    # config.encoding = "utf-8"
    config.encoding = "utf-8"
    
    config.middleware.use Rack::Deflater
    
    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :destroy]
      end
    end
    
    config.middleware.insert 0, Rack::UTF8Sanitizer
    
    # 解析xml参数到hash，需要旧的gem支持: actionpack-xml_parser
    config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser
    
    # remove warnings
    config.active_record.raise_in_transactional_callbacks = true
    
    config.cache_store = [:mem_cache_store, '127.0.0.1', { namespace: 'xy-backend-1', compress: true }]
    
    # 防止大量IP访问
    config.middleware.use Rack::Attack
    
    # 设置Active job adapter
    config.active_job.queue_adapter = :sidekiq
    
  end
end

I18n.config.enforce_available_locales = false
I18n.locale = 'zh-CN'
