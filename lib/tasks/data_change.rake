namespace :data_change do
  desc "开始..."
  task trade_logs: :environment do
    id_user_ids = TradeLog.where(tradeable_type: 'Redbag').pluck(:id, :user_id, :tradeable_id)
    id_user_ids.each do |item|
      id = item[0]
      user_id = item[1]
      tradeable_id = item[2]
      
      ids = RedbagShareEarnLog.where(user_id: user_id, redbag_id: tradeable_id).pluck(:id)
      puts ids
    end
  end

end
