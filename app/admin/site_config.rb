ActiveAdmin.register SiteConfig do
  menu parent: 'system', priority: 2, label: '站点配置'
  
  active_admin_import validate: true,
            template_object: ActiveAdminImport::Model.new(
                hint: "文件导入格式为: '配置名','配置值','配置描述'",
                csv_headers: ["key","value","description"],
                force_encoding: :auto
            ),
            back: {action: :index}

  # menu false if current_admin.super_admin?
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  permit_params :key, :value, :description

end
