module API
  module CommHelpers
    # 获取服务器session
    def session
      env[Rack::Session::Abstract::ENV_SESSION_KEY]
    end # end session method
    
    # 获取客户端ip
    def client_ip
      env['action_dispatch.remote_ip'].to_s
    end
  
    # 最大分页大小
    def max_page_size
      100
    end # end max_page_size method
  
    # 默认分页大小
    def default_page_size
      15
    end # end default_page_size method
  
    # 分页大小
    def page_size
      size = params[:size].to_i
      size = size.zero? ? default_page_size : size
      [size, max_page_size].min
    end # end page_size method
  
    # 1.格式化输出带结果数据的json
    def render_json(target, grape_entity, opts = {}, total = 0)
      return { code: 0, message: 'ok', data: {} } if target.nil?
      return { code: 0, message: 'ok', data: [] } if target.is_a?(Array) and target.blank?
      
      present target, :with => grape_entity, :opts => opts
      
      if total > 0
        body( { code: 0, message: 'ok', total: total, data: body } )
      else
        body( { code: 0, message: 'ok', data: body } )
      end
      
    end # end render_json method
  
    # 2.格式化输出错误
    def render_error(error_code, message)
      { code: error_code, message: message }
    end # end render_error method
  
    # 3.格式输出无数据的json
    def render_json_no_data
      render_error(0, 'ok')
    end # end render_json_no_data method
  
    # 当前登录用户
    def current_user
      token = params[:token]
      @current_user ||= User.where(private_token: token).first
    end # end current_user
  
    # 认证用户
    def authenticate!
      error!({"code" => 401, "message" => "用户未登录"}, 200) unless current_user
      error!({"code" => -10, "message" => "您的账号已经被禁用"}, 200) unless current_user.verified
    
      # 返回当前用户
      current_user
    end # end authenticate!
  
    # 手机号验证
    def check_mobile(mobile)
      return false if mobile.blank?
      return false if mobile.length != 11
      mobile =~ /\A1[3|4|5|8|7][0-9]\d{4,8}\z/
    end # end check_mobile
  end
end