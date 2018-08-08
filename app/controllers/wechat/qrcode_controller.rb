require 'open-uri'
class Wechat::QrcodeController < Wechat::ApplicationController
  layout 'qrcode'
  skip_before_filter :check_weixin_legality
  
  before_filter :remove_xss_limit
  before_filter :check_access_params
  
  def user_pay
    @user_pay = UserPay.find_by(uniq_id: params[:code])
    
    if @user_pay.blank?
      render text: '无效的抵现申请', status: 404
      return
    end
    
  end
  
  def user_card
    @user_card = UserCard.find_by(uniq_id: params[:code])
    
    if @user_card.blank?
      render text: '此卡未找到', status: 404
      return
    end
    
    @user_card.add_view_count
    
  end
  
  def share_poster 
    user_poster_redbag = UserPosterRedbag.find_by(uniq_id: params[:code])
    qrcode_url = 'https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=' + user_poster_redbag.qrcode_ticket
    image = MiniMagick::Image.open(qrcode_url)
    image.resize "200x200"
    send_data image.to_blob, disposition: 'inline', type: image.mime_type
  end
  
  private
  def remove_xss_limit
    # 去掉XSS跨越访问限制
    response.headers.delete "X-Frame-Options"
  end
  
  def check_access_params
    if params[:code].blank? or params[:i].blank? or params[:ak].blank?
      render text: '参数不正确', status: 403
      return false
    end
    
    sign = Digest::MD5.hexdigest(params[:code] + params[:i] + SiteConfig.web_access_key)
    if sign != params[:ak]
      render text: '非法访问', status: 403
      return false
    end
  end
  
end
