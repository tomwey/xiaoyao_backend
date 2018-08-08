class PagesController < ApplicationController

  def show
    # 去掉XSS跨越访问限制
    response.headers.delete "X-Frame-Options"
    @page = Page.find_by(slug: params[:id])
    @page_title = @page.title
  end
    
end