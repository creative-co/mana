package 's3cmd'

s3cfg_filepath = "#{node.deploy_to}/.s3cmd"

file s3cfg_filepath do
  content <<CONTENT
[default]
access_key = #{node.aws.access_key_id}
secret_key = #{node.aws.secret_access_key}
CONTENT
end

bucket = "#{node.application}-backup"

execute "s3cmd -c #{s3cfg_filepath} mb s3://#{bucket}"
 
cron "#{node.application}-backup" do
  server_id = node[:ec2] ? node.ec2.instance_id : node.hostname

  minute 0
  command "F=`mktemp` && pg_dump -c -U postgres #{node.railsapp.db_name} | gzip > $F && s3cmd -c #{s3cfg_filepath} put $F s3://#{bucket}/#{server_id}-#{node.railsapp.db_name}/`date -u +\\%Y-\\%m-\\%d/\\%H-\\%M-\\%S`.sql.gz && rm $F"

  user node[:runner] || node.user
end
