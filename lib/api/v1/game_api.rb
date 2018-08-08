# require 'rest-client'
module API
  module V1
    class GameAPI < Grape::API
      
      resource :game, desc: '游戏相关接口' do
        desc '获取游戏更新配置'
        params do
          requires :code, type: String, desc: '某个游戏代号, 例如：jgmj'
          requires :bv,   type: String, desc: '当前版本'
          requires :os,   type: String, desc: '平台，ios或android' 
        end
        get :update do
          game = Game.find_by(code: params[:code])
          if game.blank?
            return render_error(4004, '不存在的游戏')
          end
          
          bv = params[:bv]
          unless bv.include? '.'
            bv = bv.to_i
            if bv < 100
              t = bv
            else
              t = bv - 100
            end
            
            suffix = t % 10
            prefix = bv / 100.0
            prefix = prefix.to_s[0,3]
            
            bv = prefix + '.' + suffix.to_s
          end
          
          puts bv
          
          shield = GameConfig.is_app_approving_version.to_i
          if params[:os].downcase == 'android' or game.code == 'jgmj-test'
            shield = 0
          end
          
          @update = GameUpdate.where(game_id: game.id, opened: true)
            .where('version > ? and lower(os) = ?', bv, params[:os].downcase)
            .order('version desc').first
          
          if @update.blank?
            return {
              packageUrl: '',
              remoteManifestUrl: "http://120.132.57.133:8080/api/v1/game/update?code=#{params[:code]}&bv=#{params[:bv]}&os=#{params[:os]}",
              version: bv,
              engineVersion: GameConfig.game_engine_version,
              assets: {},
              searchPaths: ['src/','src/games/src/','res/','res/games/res/', 'res/protocol/'],
              shield: shield,
              md5: '',
              packageSize: 0,
              updateDesc: ''
            }
          end
          
          filename = File.basename(@update.package_file.path)
          assets = {}
          assets[filename] = {
            compressed: true,
            md5: @update.file_md5 || ''
          }
          
          {
            packageUrl: @update.package_file.try(:url) || '',
            remoteManifestUrl: "http://120.132.57.133:8080/api/v1/game/update?code=#{params[:code]}&bv=#{params[:bv]}&os=#{params[:os]}",
            version: @update.version || bv,
            engineVersion: GameConfig.game_engine_version,
            assets: assets,
            searchPaths: @update.search_paths.gsub(/\s+/, ',').split(','),
            shield: shield,
            md5: @update.file_md5 || '',
            packageSize: @update.package_file.size,
            updateDesc: @update.change_log
          }
          
        end # end update
        
        desc '获取游戏服务器信息'
        params do
          requires :code, type: String, desc: '某个游戏代号'
          optional :bv,   type: String, desc: '当前版本'
          optional :os,   type: String, desc: '平台，ios或android' 
        end
        get :server do
          ports = []
          GameConfig.server_ports.split(',').each do |p|
            ports << p.to_i
          end
          
          { cname: GameConfig.server_cname, ip: GameConfig.server_ip, ports: ports }
        end # end server
        
      end # end resource
      
    end # end class
  end
end