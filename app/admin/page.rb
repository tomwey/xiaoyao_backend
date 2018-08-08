ActiveAdmin.register Page do

# menu parent: 'system'
menu parent: 'system', priority: 88, label: '网页文档'

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :list, :of, [:title, :slug, :body], :on, :model

filter :title
filter :slug
filter :created_at

index do
  selectable_column
  column('#',:id) { |page| link_to page.id, admin_page_path(page) }
  column(:title, sortable: false) { |page| link_to page.title, admin_page_path(page) }
  column(:slug, sortable: false) { |page| link_to page_path(page.slug), page_path(page.slug)  }
  
  actions
end

form do |f|
  f.semantic_errors
  f.inputs do
    f.input :title
    f.input :slug
    f.input :body, as: :text, input_html: { class: 'redactor' }, placeholder: '网页内容，支持图文混排', hint: '网页内容，支持图文混排'
  end
  actions
end

end
