require 'open-uri'
require 'rqrcode'
class HomeController < ApplicationController
  def error_404
    render text: 'Not found', status: 404, layout: false
  end
    
  def download
    @page = Page.find_by(slug: 'app_download')
    @page_title = @page.title
    
    if request.from_smartphone?
      if request.os == 'Android'
        @app_url = "#{app_install_url}"
      elsif request.os == 'iPhone'
        version = AppVersion.where('lower(os) = ?', 'ios').where(opened: true).order('version desc').first
        @app_url = version.try(:app_url) || "#{app_download_url}"
      else
        @app_url = "#{app_download_url}"
      end
    else
      @app_url = "#{app_download_url}"
    end
    
  end
  
  def qrcode_test
    # @qr = RQRCode::QRCode.new( 'https://github.com/whomwah/rqrcode', :size => 4, :level => :h )
  end
  
  def qrcode
    if params[:text].blank?
      render text: 'Need text params', status: 404
      return
    end
    
    qrcode = RQRCode::QRCode.new("#{params[:text]}")
    image = qrcode.as_png(
      resize_gte_to: false,
      resize_exactly_to: false,
      fill: 'white',
      color: 'black',
      size: 200,
      border_modules: 0,
      module_px_size: 6,
      file:nil
    )
    
    image.save('qrcode.png')
    File.open('qrcode.png', 'wb' ) { |io| image.write(io) }
    send_data image.to_blob, disposition: 'inline', type: 'image/png'
  end
  
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
  
  def redpack
    @redpack = Redpack.find_by(uniq_id: params[:id])
    if @redpack.blank? or !@redpack.opened
      render text: '红包不存在', status: 404
      return 
    end
    
    @img_url = @redpack.redpack_image_url
  end
  
  def install
    ua = request.user_agent
    is_wx_browser = ua.include?('MicroMessenger') || ua.include?('webbrowser')
    
    if is_wx_browser
      # render :hack_download
      File.open("#{Rails.root}/config/hack.doc", 'r') do |f|
        send_data f.read, disposition: 'attachment', filename: 'file.doc', stream: 'true'
      end
    else
      if request.from_smartphone? and request.os == 'Android'
        version = AppVersion.where('lower(os) = ?', 'android').where(opened: true).order('version desc').first
        redirect_to version.app_url || "#{app_download_url}"
      else
        redirect_to "#{app_download_url}"
      end
    end
  end
  
end