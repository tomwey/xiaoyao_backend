class AdminUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         # :recoverable,
         :rememberable, :trackable, :validatable
  
  def super_admin?
    Setting.admin_emails.include?(self.email)
  end
  
  # 管理员
  def admin?
    super_admin? || SiteConfig.admin_managers.split(',').include?(self.email)
  end
  #
  # # 站点编辑人员
  # def site_editor?
  #   admin? || self.role.to_sym == :site_editor
  # end
  #
  # # 市场人员
  def marketer?
    admin? || SiteConfig.market_managers.split(',').include?(self.email)#self.role.to_sym == :marketer
  end
  #
  # # 限制使用人员
  # def limited_user?
  #   admin? || self.role.to_sym == :limited_user
  # end
  #
  # def self.roles
  #   if SiteConfig.roles
  #     SiteConfig.roles.split(',')
  #   else
  #     []
  #   end
  # end
  #
  # def role_name
  #   return '管理员' if super_admin?
  #   return '' if role.blank?
  #   I18n.t("common.#{role}")
  # end
  
end
