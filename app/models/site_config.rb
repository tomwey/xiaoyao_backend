class SiteConfig < ActiveRecord::Base
  validates :key, :value, presence: true
  validates_uniqueness_of :key
  
  def self.method_missing(method, *args)
    method_name = method.to_s
    super(method, *args)
  rescue NoMethodError
    if method_name =~ /=$/
      var_name = method_name.gsub('=', '')
      value = args.first.to_s
      if item = find_by_key(var_name)
        item.update_attribute(:value, value)
      else
        SiteConfig.create(key: var_name, value: value, description: var_name)
      end
    else
      Rails.cache.fetch("site_config:#{method}") do
        if item = find_by_key(method)
          item.value
        else
          nil
        end
      end
    end
    
  end
  
  after_save :update_cache
  def update_cache
    Rails.cache.write("site_config:#{self.key}", self.value)
    if self.key == 'wechat_menu'
      # 创建微信自定义菜单
      Wechat::Base.create_wechat_menu(self.value)
    end
  end

  def self.find_by_key(key)
    where(key: key.to_s).first
  end
end
