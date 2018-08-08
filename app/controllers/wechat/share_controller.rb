class Wechat::ShareController < Wechat::ApplicationController
  layout 'share'
  skip_before_filter :check_weixin_legality
  
  # before_filter :require_user
  
  # 官方分享
  # http://domain/wx/share/offical?token=xxxxxxx
  def offical
    @users = User.includes(:wechat_profile).where('earn > 0').order('earn desc').limit(3)
    @earn_logs = EventEarnLog.joins(:user, :event).order('id desc').limit(10)
  end
  
  # 红包分享结果
  def result
    @redbag = Redbag.find_by(uniq_id: params[:id])
    if @redbag.blank?
      render text: '未找到红包'
      return 
    end
    
    if params[:money]
      @money = params[:money]
    else
      code = (params[:code] || 0)
      if code == 500
        @msg = '服务器出错，请稍后再试！'
      else
        @msg = params[:message]
      end
    end
    
    @total_money ||= Redbag.opened.no_complete.where(use_type: Redbag::USE_TYPE_EVENT).sum('total_money').to_i
    
  end
  
  # 晒提现
  def invite
    @share_title = ''
    @share_image_url = ''
    @share_desc = ''
    @sign_package = Wechat::Sign.sign_package(request.original_url)
  end
  
  # 红包分享
  def redbag
    @redbag = Redbag.find_by(uniq_id: params[:id])
    if @redbag.blank?
      render text: '未找到红包'
      return 
    end
    
    if not @redbag.opened
      render text: '红包未上架'
      return
    end
    
    if @redbag.share_hb_id.blank?
      render text: '该红包没有分享红包'
      return
    end
    
    # @earn_logs = RedbagEarnLog.joins(:user, :redbag).where(redbag_id: @redbag.id).where.not(money: 0.0).order('money desc, id desc').limit(10)
    
    @user = User.find_by(private_token: params[:token])
    # if @user && @user.balance > 0
    #   @share_title = "我刚刚在小优大惠领了#{@user.balance}元，爽翻..."
    # else
    #   @share_title = CommonConfig.share_title || ''
    # end
    @share_title = @redbag.real_share_title
    @share_image_url = @redbag.share_image_icon

    # 写浏览日志
    # RedbagViewLog.create!(redbag_id: @redbag.id, ip: request.remote_ip, user_id: @user.try(:id), location: nil)
    
    @sign_package = Wechat::Sign.sign_package(request.original_url)
    
    redirect_url  = "#{wechat_auth_redirect_url}?eid=#{@redbag.uniq_id}&token=#{params[:token]}&is_hb=1"
    
    @wx_auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&response_type=code&scope=snsapi_userinfo&state=yujian#wechat_redirect"
    
    # 表示用户认证登录通过，并注册了新的账号，然后重定向了当前路由，这个时候需要把这个token保存到localStorage
    if session['auth.flag'] && session['auth.flag'].to_i == 1
      if @user
        session['auth.flag'] = nil
        @current_token = @user.private_token
      end
    end
    
    @i = Time.zone.now.to_i.to_s
    @ak = Digest::MD5.hexdigest(SiteConfig.api_key + @i)
    
  end
  
  # 简单的分享广告内容到
  def redbag2
    @redbag = Redbag.find_by(uniq_id: params[:id])
    if @redbag.blank?
      render text: '未找到红包'
      return 
    end
    
    # @user = User.find_by(private_token: params[:token])
    # if @user && @user.balance > 0
    #   @share_title = "我刚刚在小优大惠领了#{@user.balance}元，爽翻..."
    # else
    #   @share_title = CommonConfig.share_title || ''
    # end
    @share_title = @redbag.title
    # puts @share_title
    @share_image_url = @redbag.share_image_icon

    @sign_package = Wechat::Sign.sign_package(request.original_url)
    
    @i = Time.zone.now.to_i.to_s
    @ak = Digest::MD5.hexdigest(SiteConfig.api_key + @i)
        
  end
  
  # 活动分享
  # http://domain/wx/share/event?id=123&token=xxxxx
  def event
    @event = Event.find_by(uniq_id: params[:event_id] || params[:id])
    if @event.blank?
      render text: '未找到该活动'
      return 
    end
    @earn_logs = EventEarnLog.joins(:user, :event).where(event_id: @event.id, hb_id: @event.current_hb.uniq_id).where.not(money: 0.0).order('id desc').limit(10)
    
    @user = User.find_by(private_token: params[:token])
    if @user && @user.balance > 0
      @share_title = "我刚刚在小优大惠领了#{@user.balance}元，爽翻..."
    else
      @share_title = CommonConfig.share_title || ''
    end
    
    @has_share_hb = @event.share_hb && @event.share_hb.left_money > 0.0
    
    # 写浏览日志
    EventViewLog.create!(event_id: @event.id, ip: request.remote_ip, user_id: @user.try(:uid), location: nil)
    
    @sign_package = Wechat::Sign.sign_package(request.original_url)
    
    redirect_url  = "#{wechat_auth_redirect_url}?eid=#{@event.uniq_id}&token=#{params[:token]}"
    
    @wx_auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&response_type=code&scope=snsapi_userinfo&state=yujian#wechat_redirect"
    
    # 表示用户认证登录通过，并注册了新的账号，然后重定向了当前路由，这个时候需要把这个token保存到localStorage
    if session['auth.flag'] && session['auth.flag'].to_i == 1
      if @user
        session['auth.flag'] = nil
        @current_token = @user.private_token
      end
    end
    
    @i = Time.zone.now.to_i.to_s
    @ak = Digest::MD5.hexdigest(SiteConfig.api_key + @i)
    
  end
  
  private
  def require_user
    @user = User.find_by(private_token: params[:token])
    if @user.blank?
      render text: '非法访问'
      return false
    end
  end
end
