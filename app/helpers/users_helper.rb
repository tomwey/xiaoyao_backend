module UsersHelper
  def user_avatar_tag(user, size = :normal, img_class = '')
    if user.is_a?(Admin)
      return image_tag("avatar/#{size}.png", size: '48x48', class: img_class)
    end
    
    if user.blank? or user.real_avatar_url.blank?
      return image_tag("avatar/#{size}.png", size: '48x48', class: img_class)
    end
    
    image_tag(user.real_avatar_url, size: '48x48', class: img_class)
  end
  
end