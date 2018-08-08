class Wechat::StatsController < Wechat::ApplicationController
  layout 'stats'
  skip_before_filter :check_weixin_legality
  
  before_filter :remove_xss_limit
  # before_filter :check_access_params
  
  def index
    
  end
  
  private
  def remove_xss_limit
    # 去掉XSS跨越访问限制
    response.headers.delete "X-Frame-Options"
  end
  
  def check_access_params
    if params[:token].blank? or params[:i].blank? or params[:ak].blank?
      render text: '参数不正确', status: 403
      return false
    end

    sign = Digest::MD5.hexdigest(params[:token] + params[:i] + SiteConfig.web_access_key)
    if sign != params[:ak]
      render text: '非法访问', status: 403
      return false
    end
  end
  
end
