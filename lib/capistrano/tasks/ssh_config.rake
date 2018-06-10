desc "todo"
task :ssh_config do
  puts "# #{env.send(:config)[:stage]}"
  puts
  env.send(:servers).each do |server|
    puts "Host #{server.properties.host}"
    puts "  HostName #{server.hostname}"
    puts
  end
end
