class Wechat::LuckyDrawsController < Wechat::ApplicationController
  layout 'choujiang'
  skip_before_filter :check_weixin_legality
  
  before_filter :require_user
  before_filter :check_user
  
  def show
    @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
    
    @lucky_draw.view_for(nil, request.remote_ip, current_user.id)
    
    @log = LuckyDrawPrizeLog.where(user_id: current_user.id, lucky_draw_id:@lucky_draw.id).order('id desc').first
    
    # @i = Time.zone.now.to_i
    # @ak = Digest::MD5.hexdigest(SiteConfig.api_key + @i.to_s)
    # @sign_package = Wechat::Sign.sign_package(request.original_url)
  end
  
  def results
    @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
    
    if @lucky_draw.blank?
      @error_msg = '未找到该活动'
      @results = nil
    else
      @error_msg = nil
      @results = @lucky_draw.lucky_draw_prize_logs.includes(:user).order('id desc')
    end
  end
  
  def begin
    @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
    
    @error_msg = nil
    @success = false
    
    if @lucky_draw.blank?
      @error_msg = '未找到该抽奖'
    end
    
    if not @lucky_draw.opened
      @error_msg = '抽奖活动还未上线'
    end
    
    if @lucky_draw.started_at && @lucky_draw.started_at > Time.zone.now
      @error_msg = '抽奖活动还未开始' 
    end
    
    unless @lucky_draw.has_prizes?
      @error_msg = 'Oops, 已经全部抽完了' 
    end
    
    unless current_user.can_prize?
      # return render_error(6001, '对不起，您已经没有抽奖机会了')
      @error_msg = '对不起，您已经没有抽奖机会了' 
    end
    
    # 检查用户是否已经抽过一次奖了，此处后期可以灵活考虑拿掉限制
    if current_user.prized?(@lucky_draw)
      # return render_error(6001, '您已经参与过该抽奖')
      @error_msg = '您已经参与过该抽奖' 
      # puts '已经抽过了'
    end
    
    @prize = @lucky_draw.win_prize(current_user)
    if @prize.blank?
      # return render_error(6001, '对不起，没有找到奖品')
      @error_msg = '对不起，奖品已经抽完了' 
    end
    
    if @error_msg
      @success = false
    else
      if params[:loc]
        loc = "POINT(#{params[:loc].gsub(',', ' ')})"
      else
        loc = nil
      end
      @log = LuckyDrawPrizeLog.new(user_id: current_user.id, lucky_draw_id: @lucky_draw.id, prize_id: @prize.id, ip: request.remote_ip, location: loc)
    
      if @log.save
        @success = true
        
        # 向云巴推消息给客户端
        content = "<span style=\"color:red;\">#{@log.user.format_nickname}</span> 抽中 <span style=\"color:red;\">#{@prize.name}</span>#{@log.user.uid}"
        YunbaSendJob.perform_later(@lucky_draw.uniq_id.to_s, content)
      else
        @error_msg = '抽奖启动失败'
      end
    end
    
  end
  
  private 
  def require_user
    if current_user.blank?
      # 登录
      store_location
      redirect_to wechat_login_path
    end
  end
  
  def check_user
    unless current_user.verified
      # flash[:error] = "您的账号已经被禁用"
      # redirect_to wechat_shop_root_path
      render(text: "您的账号已经被禁用", status: 403)
      return
    end
  end
  
end