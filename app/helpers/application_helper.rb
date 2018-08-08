module ApplicationHelper
  def render_page_title
    site_name = SiteConfig.app_name
    title = @page_title ? "#{site_name} - #{@page_title}" : site_name rescue "SITE_NAME"
    content_tag("title", title, nil, false)
  end
  
  def notice_message
    flash_messages = []
    flash.each do |type, message|
      type = :success if type.to_s == "notice"
      type = :warning if type.to_s == "alert"
      type = :danger if type.to_s == "error"
      text = content_tag(:div, link_to("×", "#", class: "close", 'data-dismiss' => "alert") + message, class: "x_panel alert alert-#{type}", style: "margin-top: 20px; text-align:center;")
      flash_messages << text if message
    end
    flash_messages.join("\n").html_safe
  end
  
  def controller?(*controller)
    controller.include?(controller_name)
  end

  def action?(*action)
    action.include?(action_name)
  end
  
end
