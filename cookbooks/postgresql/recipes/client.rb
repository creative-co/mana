%w{postgresql-client libpq-dev make}.each do |pg_pack|
  package pg_pack do
    action :install
  end
end
