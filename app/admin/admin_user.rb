ActiveAdmin.register AdminUser do
  menu parent: 'system', label: '账号管理', priority: 1
  
  permit_params :email, :password, :password_confirmation
  
  config.filters = false
  
  actions :all, except: [:show]
  
  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  # filter :email
  # filter :current_sign_in_at
  # filter :sign_in_count
  # filter :created_at
  
  member_action :unbind, method: :put do
    resource.unbind!
    redirect_to collection_path, notice: '解绑成功'
  end

  # form do |f|
  #   f.inputs '修改密码' do
  #     # f.input :email
  #     f.input :password
  #     f.input :password_confirmation
  #   end
  #   f.actions
  # end
  
  form do |f|
    f.inputs "管理员信息" do
      if f.object.new_record?
        f.input :email
      end
      f.input :password
      f.input :password_confirmation
      # f.input :role, as: :radio, collection: Admin.roles.map { |role| [I18n.t("common.#{role}"), role] }
    end
    f.actions
  end

end
