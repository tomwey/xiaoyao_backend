module API
  module V1
    class CardsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :cards, desc: '卡相关的接口' do
        # desc "获取我的卡"
        # params do
        #   requires :token, type: String, desc: '用户认证Token'
        #   use :pagination
        # end
        # get :my_list do
        #   user = authenticate!
        #
        #   @user_cards = UserCard.includes(:card).opened.not_used.not_expired
        #   if params[:page]
        #     @user_cards = @user_cards.paginate page: params[:page], per_page: page_size
        #     @total = @user_cards.total_entries
        #   else
        #     @total = @user_cards.size
        #   end
        #
        #   render_json(@user_cards, API::V1::Entities::UserCard, {}, @total)
        # end # end get my_list
        # desc "获取卡的领取情况"
        
      end # end resource
      
    end # end class
  end
end