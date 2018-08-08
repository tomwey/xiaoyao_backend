require 'rest-client'
class Front::RedpacksController < Front::ApplicationController
  # skip_before_filter :wx_notify
  before_filter :require_user
  
  def detail
    @redpack = Redpack.find_by(uniq_id: params[:id])
    if @redpack.blank? or !@redpack.opened
      render text: '红包不存在', status: 404
      return
    end
    
    @img_url = @redpack.redpack_image_url
  end
  
  def result
    @log = RedpackSendLog.find_by(uniq_id: params[:id])
    
  end
  
end
