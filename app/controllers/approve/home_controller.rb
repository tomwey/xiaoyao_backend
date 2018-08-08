class Approve::HomeController < ApplicationController
  layout 'approve'
  
  def index
    @current = 'approve_index'
    @page_title = "小优大惠"
    @events = Event.valid.sorted
  end
  
  def new_event
    @current = 'approve_new_event'
    @page_title = "我要发布"
    @event = Event.new
    # @event.hongbao = Hongbao.new
  end
  
  def charge
    @current = 'approve_charge'
    @page_title = "充值"
  end
  
  def about
    @current = 'approve_about'
    
    @page = Page.find_by(slug: 'about')
    @page_title = @page.title
  end
  
  def event_body
    @current = 'approve_index'
    @event = Event.find_by(uniq_id: params[:event_id])
    @page_title = "活动详情"
  end
end