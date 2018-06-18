ENV["AWS_REGION"] = "ap-northeast-1" # TODO: INPUT REGION
require "aws-sdk-core"

desc "Populate config/deploy with one file per AWS OpsWorks stack"
task :populate => :extinguish do
  opsworks = Aws::OpsWorks::Client.new
  stages = Hash.new { {} }

  opsworks.describe_stacks.stacks.each do |stack|
    stages[stack.name] = {}
    opsworks.describe_layers(:stack_id => stack.stack_id).layers.each do |layer|
      opsworks.describe_instances(:layer_id => layer.layer_id).instances.reject { |instance| instance.public_ip.nil? }.each do |instance|
        # stages[stack.name][instance.public_ip] ||= { :user => instance.os.include?("Amazon Linux") ? "ec2-user" : "ubuntu", :roles => [] }
        stages[stack.name][instance.public_ip] ||= { :host => instance.hostname, :roles => [] }
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
