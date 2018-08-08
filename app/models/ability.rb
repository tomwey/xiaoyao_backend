class Ability
  include CanCan::Ability
  
  def initialize(user)
    can :manage, ActiveAdmin::Page, name: "Dashboard"#, namespace_name: :admin
    
    if user.super_admin?
      can :manage, :all
    else
      can :read, :all
      cannot :read, SiteConfig
      
      can :update, AdminUser do |admin|
        admin.id == user.id
      end
      
      # if user.marketer? or user.admin?
      #   can :create, GameRecharge
      #   can :recharge, GameRecharge
      # end
      
    end
    
    # if user.super_admin?
    #   can :manage, :all
    # elsif user.admin?
    #   can :manage, :all
    #   cannot :manage, SiteConfig
    #   cannot :manage, Admin, email: Setting.admin_emails
    #   cannot :destroy, :all
    # elsif user.site_editor?
    #   can :manage, :all
    #   cannot :manage, SiteConfig
    #   cannot :manage, Admin
    #   cannot :destroy, :all
    # elsif user.marketer?
    #   cannot :manage, :all
    #   can :read, :all
    #   cannot :read, SiteConfig
    #   cannot :read, Admin
    # elsif user.limited_user?
    #   cannot :manage, :all
    #   can :manage, ActiveAdmin::Page, name: "Dashboard"
    #   can :read, User
    #   can :read, UserSession
    #   can :read, WechatLocation
    #   can :read, UserChannel
    #   can :read, UserChannelLog
    #   can :read, Page
    #   can :read, Report
    #   can :read, Feedback
    #   # cannot :read, SiteConfig
    #   # cannot :read, Admin
    # end
  end
  
end