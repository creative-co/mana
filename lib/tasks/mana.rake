namespace :mana do
  desc "Install mana configs"
  task :install do
    templates_path = File.expand_path(File.join(File.dirname(__FILE__), '../../templates')) + '/.'
    cookbooks_path = File.expand_path(File.join(File.dirname(__FILE__), '../../cookbooks'))
    FileUtils.cp_r templates_path, '.'
    FileUtils.cp_r cookbooks_path, './config/deploy'
  end
end
