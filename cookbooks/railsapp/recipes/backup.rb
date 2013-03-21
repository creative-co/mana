package 's3cmd'

s3cfg_filepath = "#{node.deploy_to}/.s3cmd"

file s3cfg_filepath do
  content <<CONTENT
[default]
access_key = #{node.aws.access_key_id}
secret_key = #{node.aws.secret_access_key}
CONTENT
end

execute "s3cmd -c #{s3cfg_filepath} mb s3://#{node.application}-#{node.stage}"
 
cron "#{node.application}-backup" do
  minute 0
  command "F=`mktemp` && pg_dump -c -U postgres #{node.railsapp.db_name} | gzip > $F && s3cmd -c #{s3cfg_filepath} put $F s3://#{node.application}-#{node.stage}/backups/`date -u +\\%Y-\\%m-\\%d/\\%H-\\%M-\\%S`.gz && rm $F"

  user node.runner || node.user
end
