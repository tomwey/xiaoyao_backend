class EventsController < ApplicationController
  before_filter :set_user
  def new
    # 去掉XSS跨越访问限制
    response.headers.delete "X-Frame-Options"
    @event = Event.new
    @event.hongbao = Hongbao.new
  end
  
  def create
    # 去掉XSS跨越访问限制
    response.headers.delete "X-Frame-Options"
    @event = Event.new(event_params)
    @event.ownerable = @user
    if @event.save
      redirect_to new_event_path(token: @user.private_token), notice: '发布成功！'
    else
      render :new
    end
  end
  
  private
  def set_user
    @user = User.find_by(private_token: params[:token])
    puts @user
    if @user.blank?
      render text: '用户认证失败'
      return false
    end
  end
  def event_params
    params.require(:event).permit(:title, :image, :body, :body_url, :started_at, hongbao: [:total_money, :min_value, :max_value, :_type])
  end
end
