# サーバ登録時に user 情報を追加するパッチ
module Capistrano
  class Configuration
    def server(name, properties={})
      servers.add_host(name, {user: config[:user]}.merge(properties))
    end
  end
end

# file required by Capistrano, don't delete
set :user, (ENV["CAP_USER"] || ENV["USER"] || `whoami`.chomp)
