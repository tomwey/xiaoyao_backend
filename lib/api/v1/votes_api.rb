module API
  module V1
    class VotesAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :votes, desc: '投票相关的接口' do
        
        desc "获取投票"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get do
          @votes = Vote.where(opened: true).order('id desc')
          if params[:page]
            @votes = @votes.paginate page: params[:page], per_page: page_size
            total = @votes.total_entries
          else
            total = @votes.size
          end
          
          render_json(@votes, API::V1::Entities::Vote, { user: User.find_by(private_token: params[:token]) }, total )
        end # end get
        
        desc "查看投票"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :address, type: String, desc: '用户地理位置'
          requires :id, type: Integer, desc: '投票ID'
        end
        post '/:id/view' do
          @vote = Vote.find_by(uniq_id: params[:id]) or !@vote.opened
          if @vote.blank?
            return render_error(4004, '投票不存在')
          end
          
          VoteViewLog.create!(vote_id: @vote.uniq_id, 
                              user_id: User.find_by(private_token: params[:token]).try(:uid),
                              ip: client_ip,
                              address: params[:address]
                              )
                              
          render_json(@vote, API::V1::Entities::Vote, { user: User.find_by(private_token: params[:token]) })
        end # end post view
        
        desc "用户投票"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          requires :id,    type: Integer, desc: '投票ID'
          requires :answers, type: String, desc: '投票选项ID,多个ID用英文逗号分隔'
          optional :address, type: String, desc: '用户地理位置'
        end
        post '/:id/commit' do
          user = authenticate!
          
          @vote = Vote.find_by(uniq_id: params[:id])
          if @vote.blank? or !@vote.opened
            return render_error(4004, '投票不存在')
          end
          
          if @vote.expired?
            return render_error(3001, '投票已过期')
          end
          
          if user.voted?(@vote)
            return render_error(3002, '你已经投过票了')
          end
          
          answers = params[:answers].split(',')
          ids = VoteItem.where(vote_id: @vote.id, uniq_id: answers).pluck(:uniq_id)
          if ids.empty?
            return render_error(3003, '投票选项不存在')
          end
          
          UserVoteLog.create!(user_id: user.uid, vote_id: @vote.uniq_id, ip: client_ip, address: params[:address], answers: ids)
          
          render_json(@vote, API::V1::Entities::Vote, { user: user })
          
        end # end post commit
        
      end # end resource
      
    end
  end
end