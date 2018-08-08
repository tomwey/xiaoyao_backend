module API
  module V1
    module Entities
      class Base < Grape::Entity
        format_with(:null) { |v| v.blank? ? "" : v }
        format_with(:chinese_date) { |v| v.blank? ? "" : v.strftime('%Y-%m-%d') }
        format_with(:chinese_datetime) { |v| v.blank? ? "" : v.strftime('%Y-%m-%d %H:%M:%S') }
        format_with(:month_date_time) { |v| v.blank? ? "" : v.strftime('%m月%d日 %H:%M') }
        format_with(:money_format) { |v| v.blank? ? 0.00 : ('%.2f' % v) }
        format_with(:rmb_format) { |v| v.blank? ? 0.00 : ('%.2f' % (v / 100.00)) }
        expose :id
        # expose :created_at, format_with: :chinese_datetime
      end # end Base
      
      class UserBase < Base
        expose :uid, as: :id
        expose :private_token, as: :token
      end
      
      # 用户基本信息
      class UserProfile < UserBase
        # expose :uid, format_with: :null
        expose :mobile, format_with: :null
        expose :nickname do |model, opts|
          model.format_nickname
        end
        expose :avatar do |model, opts|
          model.real_avatar_url
        end
        expose :nb_code, as: :invite_code
        expose :earn, format_with: :money_format
        expose :balance, format_with: :money_format
        expose :today_earn, format_with: :money_format
        expose :wx_id, format_with: :null
        unexpose :private_token, as: :token
      end
      
      class AppVersion < Base
        expose :version
        expose :os
        expose :changelog do |model, opts|
          if model.change_log
            arr = model.change_log.split('</p><p>')
            arr.map { |s| s.gsub('</p>', '').gsub('<p>', '') }
          else
            []
          end
        end
        expose :app_url
        expose :must_upgrade
      end
      
      # 用户详情
      class User < UserBase
        expose :uid, as: :id
        expose :mobile, format_with: :null
        expose :nickname do |model, opts|
          model.format_nickname
        end
        expose :avatar do |model, opts|
          model.format_avatar_url
        end
        expose :follows_count
        expose :following_count
        expose :likes_count
        expose :comm_type, as: :type
        # expose :balance, format_with: :rmb_format
        # expose :vip_expired_at, as: :vip_time, format_with: :chinese_date
        # expose :left_days, as: :vip_status
        # expose :qrcode_url
        # expose :portal_url
        unexpose :private_token, as: :token
        # expose :wx_bind
        # expose :qq_bind
        
        # expose :vip_expired_at, as: :vip_time, format_with: :chinese_date
        # expose :left_days do |model, opts|
        #   model.left_days
        # end
        # expose :private_token, as: :token, format_with: :null
      end
      
      class SimpleUser < Base
        expose :uid, as: :id
        expose :mobile, format_with: :null
        expose :nickname do |model, opts|
          model.format_nickname
        end
        expose :avatar do |model, opts|
          model.format_avatar_url
        end
      end
      
      class SimplePage < Base
        expose :title, :slug
      end
      
      class Page < SimplePage
        expose :title, :body
      end
      
      class Attachment < Base
        # expose :uniq_id, as: :id
        expose :data_file_name, as: :file_name
        expose :file_size do |model, opts|
          model.data ? model.data.file.size : 0
        end
        expose :file_type do |model, opts|
          model.data.content_type
        end
        expose :url do |model, opts|
          model.data.url
        end
        # expose :width, :height
      end
      
      class QuizRule < Base
        expose :name do |model, opts|
          '答题抢红包'
        end
        expose :action do |model, opts|
          '提交答案，抢红包'
        end
        expose :question
        expose :answers
      end
      
      class CheckinRule < Base
        expose :name do |model, opts|
          '签到抢红包'
        end
        expose :action do |model, opts|
          '签到抢红包'
        end
        expose :address
        expose :accuracy
        expose :checkined_at, format_with: :chinese_datetime
      end
      
      class Question < Base
        expose :name do |model, opts|
          '答题抢红包'
        end
        expose :action do |model, opts|
          '提交答案，抢红包'
        end
        expose :question
        expose :answers
      end
      
      class Catalog < Base
        expose :uniq_id, as: :id
        expose :name
      end
      
      class RedpackTheme < Base
        expose :uniq_id, as: :id
        expose :name
        expose :icon do |model, opts|
          model.icon.blank? ? '' : model.icon.url(:small)
        end
      end
      
      class RedpackAudio < Base
        expose :uniq_id, as: :id
        expose :name
        expose :file do |model, opts|
          model.file.url
        end
      end
      
      class UserPreviewLog < Base
        expose :uniq_id, as: :id
        expose :theme_url
        expose :audio_url
      end
      
      class SimpleRedpack < Base
        expose :uniq_id, as: :id
        expose :subject
        expose :has_sign do |model, opts|
          model.sign.any?
        end
        expose :is_pin do |model, opts|
          model._type == 0
        end
        expose :is_cash do |model, opts|
          model.use_type == 1
        end
        expose :in_use do |model, opts|
          model.opened
        end
        expose :total_money, format_with: :rmb_format
        expose :total_count
        expose :sent_money, format_with: :rmb_format
        expose :sent_count
        expose :created_at, as: :time, format_with: :month_date_time
      end
      
      class EditableRedpack < SimpleRedpack
        expose :theme, using: API::V1::Entities::RedpackTheme
        expose :audio, as: :audio_obj, using: API::V1::Entities::RedpackAudio
        expose :sign_val do |model, opts|
          model.sign_val
        end
      end
      
      class Redpack < SimpleRedpack
        expose :cover do |model, opts|
          model.redpack_image_url
        end
        expose :audio do |model, opts|
          if model.audio.blank?
            ''
          else
            model.audio.file.url
          end
        end
        expose :detail_url
        # expose :has_sign do |model, opts|
        #   model.sign.any?
        # end
        # expose :is_cash do |model, opts|
        #   model.use_type == 1
        # end
        expose :user, as: :owner, using: API::V1::Entities::User
      end
      
      class RedpackSendLog < Base
        expose :uniq_id, as: :id
        expose :money, format_with: :money_format do |model, opts|
          model.money / 100.0
        end
        expose :is_cash
        expose :qrcode_url
        expose :created_at, as: :time, format_with: :month_date_time
        expose :redpack_owner, as: :hb_owner, using: API::V1::Entities::User, if: proc { |o| o.redpack_owner.present? }
        expose :user, using: API::V1::Entities::User
      end
      
      class SimpleRedpackSendLog < Base
        expose :uniq_id, as: :id
        expose :money, format_with: :money_format do |model, opts|
          model.money / 100.0
        end
        expose :qrcode_url
        expose :created_at, as: :time, format_with: :month_date_time
        expose :redpack, using: API::V1::Entities::SimpleRedpack
        expose :hb_sender, using: API::V1::Entities::User do |model, opts|
          model.redpack.try(:user)
        end
      end
      
      class RedpackConsume < Base
        expose :uniq_id, as: :id
        expose :money, format_with: :rmb_format
        expose :user, using: API::V1::Entities::SimpleUser do |model, opts|
          model.user_for_action(opts[:opts][:action])
        end
        expose :created_at, as: :time, format_with: :month_date_time
      end
            
      class TradeLog < Base
        expose :uniq_id, as: :id, format_with: :null
        expose :title
        expose :money, format_with: :rmb_format
        expose :created_at, as: :time, format_with: :month_date_time
      end
      
      class Banner < Base
        expose :uniq_id, as: :id
        expose :title
        expose :image do |model, opts|
          model.image.url(:large)
        end
        expose :link, format_with: :null
        
        # expose :view_count, :click_count
      end
      
      class Performer < Base
        expose :uniq_id, as: :id
        expose :name
        expose :avatar do |model, opts|
          model.avatar.url(:large)
        end
        expose :comm_type, as: :type
        expose :school
        expose :follows_count
        expose :followed do |model, opts|
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            user.followed?(model)
          else
            false
          end
        end
      end
      
      class VoteItem < Base
        expose :uniq_id, as: :id
        expose :perform, using: API::V1::Entities::Performer
        expose :vote_count
        expose :percent
        expose :video_url
        expose :body
      end
      
      class Vote < Base
        expose :uniq_id, as: :id
        expose :title
        expose :body
        expose :video_url
        expose :body_url
        expose :_type, as: :type
        expose :vote_count, :comments_count, :view_count, :likes_count
        expose :expired_at, as: :expire_time, format_with: :month_date_time
        expose :vote_items, using: API::V1::Entities::VoteItem
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :expired do |model, opts|
          model.expired?
        end
        expose :voted do |model,opts|
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            # puts user
            user.voted?(model)
          else
            false
          end
        end
        expose :liked do |model, opts|
          # puts opts
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            # puts user
            user.liked?(model)
          else
            false
          end
        end
      end
      
      class Media < Base
        expose :uniq_id, as: :id
        expose :title
        expose :summary, as: :subtitle, format_with: :null
        expose :cover do |model, opts|
          model.cover.url(:large)
        end
        expose :media_file_url, as: :media_file
        expose :duration
        expose :views_count, :likes_count, :comments_count, :danmu_count
        expose :owner, using: API::V1::Entities::Performer
        expose :liked do |model,opts|
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            user.liked?(model)
          else
            false
          end
        end
        expose :created_at, as: :time,format_with: :chinese_datetime
        
      end
      
      class MediaDetail < Media
        
      end
      
      class MediaPlayLog < Base
        expose :created_at, as: :time,format_with: :chinese_datetime
        expose :media, using: API::V1::Entities::Media
      end
      
      class Like < Base
        expose :likeable, using: API::V1::Entities::Media, if: proc { |o| o.likeable_type == 'Media' }
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :user, using: API::V1::Entities::User
      end
      
      class Reply < Base
        expose :content
        expose :from_user, using: API::V1::Entities::User
        expose :to_user, using: API::V1::Entities::User
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :ip
        expose :address
        expose :comment_id
      end
      
      class Comment < Base
        expose :content
        expose :user, using: API::V1::Entities::User
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :ip
        expose :address
        expose :replies, using: API::V1::Entities::Reply
      end
      
      class Ownerable < Base
        expose :comm_id, as: :id
        expose :comm_name, as: :name
        expose :avatar do |model, opts|
          model.format_avatar_url
        end
        expose :comm_type, as: :type
        expose :followed do |model, opts|
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            user.followed?(model)
          else
            false
          end
        end
      end
      
      class Topic < Base
        expose :uniq_id, as: :id
        expose :content
        expose :views_count, :likes_count, :comments_count
        expose :owner, using: API::V1::Entities::Ownerable
        expose :attachment_type, as: :type
        expose :files, using: API::V1::Entities::Attachment
        expose :topicable, as: :media, using: API::V1::Entities::Media, if: proc { |o| o.topicable_type && o.topicable_type == 'Media' }
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :liked do |model,opts|
          if opts and opts[:opts] and opts[:opts][:user]
            user = opts[:opts][:user]
            user.liked?(model)
          else
            false
          end
        end
        expose :liked_users, using: API::V1::Entities::User
        expose :latest_comments, using: API::V1::Entities::Comment
        
      end
      
      class Follow < Base
        expose :user, using: API::V1::Entities::User
        expose :followable, as: :target, using: API::V1::Entities::Ownerable
        expose :created_at, as: :time, format_with: :chinese_datetime
      end
      
      # 供应商
      class Merchant < Base
        expose :merch_id, as: :id
        expose :name
        expose :avatar do |model, opts|
          model.avatar.blank? ? '' : model.avatar.url(:large)
        end
        expose :mobile
        expose :follows_count
        expose :address, format_with: :null
        expose :type do |model, opts|
          model.auth_type.blank? ? '' : model.auth_type
        end
        # expose :note, format_with: :null
      end
      
      # 收益明细
      class EarnLog < Base
        expose :title
        expose :earn
        expose :unit
        expose :created_at, as: :time, format_with: :chinese_datetime
      end
      
      # 消息
      class Message < Base
        expose :title do |model, opts|
          model.title || '系统公告'
        end#, format_with: :null
        expose :content, as: :body
        expose :created_at, format_with: :chinese_datetime
      end
      
      class Author < Base
        expose :nickname do |model, opts|
          model.nickname || model.mobile
        end
        expose :avatar do |model, opts|
          model.avatar.blank? ? "" : model.avatar_url(:large)
        end
      end
      
      # 提现
      class Withdraw < Base
        expose :bean, :fee
        expose :total_beans do |model, opts|
          model.bean + model.fee
        end
        expose :pay_type do |model, opts|
          if model.account_type == 1
            "微信提现"
          elsif model.account_type == 2
            "支付宝提现"
          else
            ""
          end
        end
        expose :state_info, as: :state
        expose :created_at, as: :time, format_with: :chinese_datetime
        expose :user, using: API::V1::Entities::Author
      end
      
    end
  end
end