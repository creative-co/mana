require 'right_aws'

module Capistrano
  class Configuration
    def server_ec2 instance_id, *roles
      ec2 = RightAws::Ec2.new aws[:access_key_id], aws[:secret_access_key], region: aws[:region]
      addr = ec2.describe_instances(instance_id).first[:ip_address] 
      server addr, *roles
    end
  end
end
