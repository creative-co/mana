require 'roundsman/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano/recipes/deploy/strategy/remote_cache'
require 'mana/remote_cache_subdir'

Capistrano::Configuration.default_io_proc = ->(ch, stream, out){
  next if out.strip.empty? # skipping extensive blank lines
  level = stream == :err ? :important : :info
  ch[:options][:logger].send(level, out.strip, "#{stream} :: #{ch[:server]}")
}

Capistrano::Configuration.instance(:must_exist).load do

  # Convinient defaults

  set(:deploy_to) { "/opt/#{fetch(:application)}" }
  set :scm, 'git'
  set :deploy_via, :remote_cache
  set :use_sudo, false

  default_run_options[:pty] = true
  ssh_options[:forward_agent] = true

  set :strategy, RemoteCacheSubdir.new(self)

  # Roundsman fine-tuning

  set :chef_version, '~> 10.18.2'
  set :cookbooks_directory, 'config/deploy/cookbooks'
  set :stream_roundsman_output, false # todo check why is this needed
  set :ruby_install_script do
    if fetch(:ruby_version) == :brightbox
      %Q{
        apt-get install -y python-software-properties
        apt-add-repository -y ppa:brightbox/ruby-ng
        apt-get update
        apt-get install -y ruby1.9.3
        gem install bundler
      }
    else
      %Q{
        set -e
        cd #{roundsman_working_dir}
        rm -rf ruby-build
        git clone -q https://github.com/sstephenson/ruby-build.git
        cd ruby-build
        ./install.sh
        CONFIGURE_OPTS='--disable-install-rdoc' ruby-build #{fetch(:ruby_version)} #{fetch(:ruby_install_dir)}
      }
    end
  end

  # Mana

  namespace :mana do
    desc 'Complete update of all software'
    task :default do
      if roundsman.install.install_ruby?
        abort "Node is not boostrapped yet. Please run 'cap mana:setup' instead"
      end
      install
      deploy.migrations
    end

    desc 'Bootstrap chef and ruby'
    task :bootstrap do
      roundsman.install.default
      roundsman.chef.install
    end

    desc 'Install & update software'
    task :install do
      roundsman.chef.default
    end

    desc 'Show install log'
    task :log do
      sudo "cat /tmp/roundsman/cache/chef-stacktrace.out"
    end

    desc 'Complete setup'
    task :setup do
      upgrade
      bootstrap
      install
      deploy.setup
      deploy.cold
      deploy.seed
      sudo 'monit reload'
    end

    desc 'Upgrade software'
    task :upgrade do
      sudo "DEBIAN_FRONTEND=noninteractive #{fetch(:package_manager)} -yq update"
      sudo "DEBIAN_FRONTEND=noninteractive #{fetch(:package_manager)} -yq upgrade"
    end

    desc "Open SSH connection to server"
    task :ssh do
      host = roles[:app].servers.first # silly approach
      exec "ssh -L 3737:localhost:3737 #{fetch(:user)}@#{host}" # forward monit status server port
    end

    desc "Watch Rails log"
    task :watchlog do
      begin
        run "tail -n 100 -f #{fetch(:shared_path)}/log/#{rails_env}.log", pty: true do |_, stream, data|
          puts "[#{channel[:host]}][#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{data}"
          break if stream == :err
        end
      rescue Interrupt
        exit
      end
    end
  end

  # More convinience

  namespace :deploy do
    desc 'Update the database with seed data'
    task :seed, roles: :db, only: {primary: true} do
      run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
    end

    desc "Restart unicorn"
    task :restart_unicorn, roles: :app, except: {no_release: true} do
      sudo "service #{fetch(:application)}-web restart"
    end
  end
end
