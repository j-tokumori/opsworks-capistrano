ENV["AWS_REGION"] = "ap-northeast-1" # TODO: INPUT REGION
require "aws-sdk-core"

desc "Populate config/deploy with one file per AWS OpsWorks stack"
task :populate => :extinguish do
  opsworks = Aws::OpsWorks::Client.new
  stages = Hash.new { {} }

  opsworks.describe_stacks.stacks.each do |stack|
    # puts stack.custom_json
    stages[stack.name] = {}
    opsworks.describe_layers(:stack_id => stack.stack_id).layers.each do |layer|
      opsworks.describe_instances(:layer_id => layer.layer_id).instances.reject { |instance| instance.public_ip.nil? }.each do |instance|
        # stages[stack.name][instance.public_ip] ||= { :user => instance.os.include?("Amazon Linux") ? "ec2-user" : "ubuntu", :roles => [] }
        stages[stack.name][instance.public_ip] ||= { :roles => [] }
        stages[stack.name][instance.public_ip][:roles] << layer.name
      end
    end
  end

  stages.each do |stack, instances|
    File.open("config/deploy/#{stack}.rb", "w") do |file|
      instances.values.flat_map { |instance| instance[:roles] }.uniq.sort.each do |layer|
        file.puts "role #{layer.inspect}, []"
      end
      instances.sort_by { |_, instance| [instance[:role], instance[:host]] }.each do |(ip, instance)|
        file.puts "server #{ip.inspect}, #{instance.inspect}"
      end
    end
  end
end

desc "Remove the results of :populate"
task :extinguish do
  (Dir["config/deploy/*.rb"] - [__FILE__]).each do |stage|
    File.delete stage
  end
end

desc "todo"
task :ssh_config do
  opsworks = Aws::OpsWorks::Client.new
  output_path = ENV['OUTPUT_PATH'] || File.join(Dir.home, '.ssh/conf.d/hosts')

  opsworks.describe_stacks.stacks.each do |stack|
    File.open(File.join(output_path, stack.name), "w") do |file|
      file.puts "# #{stack.name}"
      file.puts
      opsworks.describe_layers(:stack_id => stack.stack_id).layers.each do |layer|
        file.puts "## #{layer.name}"
        opsworks.describe_instances(:layer_id => layer.layer_id).instances.reject { |instance| instance.public_ip.nil? }.each do |instance|
          file.puts "Host #{instance.hostname}"
          file.puts "  HostName #{instance.public_ip}"
        end
        file.puts
      end
    end
    puts "output: #{File.join(output_path, stack.name)}"
  end
end
