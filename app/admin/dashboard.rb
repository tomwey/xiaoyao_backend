ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: "概况"

  content title: "控制面板" do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end
    
    div class: "blank_slate_container" do
      "您好，#{current_admin_user.email}，欢迎来到后台系统！"
      # render "admin/dashboard/profile", owner: current_admin_user
    end
    
    # 玩家统计
    # columns do
    #   column do
    #     panel "游戏统计" do
    #       render 'admin/dashboard/game_stats' if Rails.env.production?
    #     end
    #   end
    # end
  
    # 充值统计
    
    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
  
end
