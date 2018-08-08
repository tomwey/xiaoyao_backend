require 'rest-client'
class Front::HomeController < Front::ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:wx_notify]
  
  def wx_notify
    @output = {
      return_code: '',
      return_msg: 'OK',
    }
    
    result = params['xml']
    if result and result['return_code'] == 'SUCCESS' and Wechat::Pay.notify_verify?(result)
      # 修改充值状态
      order = Charge.find_by(uniq_id: result['out_trade_no'])
      if order.present? and order.not_payed?
        order.pay!
      end
      @output[:return_code] = 'SUCCESS'
    else
      # 支付失败
      @output[:return_code] = 'FAIL'
    end
    
    respond_to do |format|
      format.xml { render xml: @output.to_xml(root: 'xml', skip_instruct: true, dasherize: false) }
    end
    
  end
  
  def wap_auth
    if params[:provider] && (params[:provider] == 'qq' || params[:provider] == 'wechat')
      from_url = params[:from_url] || SiteConfig.h5_front_url
      if from_url.include? '?'
        url = "#{from_url}&code=#{params[:code]}&provider=#{params[:provider]}"
      else
        url = "#{from_url}?code=#{params[:code]}&provider=#{params[:provider]}"
      end
      
      redirect_to url
    else
      render text: '禁止登录', status: 403
    end
    
  end
  
end
