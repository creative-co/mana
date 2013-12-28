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

  set :show_mascot, true
  set :ask_confirmation, true

  # Roundsman fine-tuning

  set :chef_version, '~> 11.4.0'
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

  namespace :roundsman do
    def install_ruby?
      installed_version = capture("ruby --version || true").strip
      if installed_version.include?("not found")
        logger.info "No version of Ruby could be found."
        return true
      end

      return false if fetch(:ruby_version) == :brightbox

      required_version = fetch(:ruby_version).gsub("-", "")
      if installed_version.include?(required_version)
        if fetch(:care_about_ruby_version)
          logger.info "Ruby #{installed_version} matches the required version: #{required_version}."
          return false
        else
          logger.info "Already installed Ruby #{installed_version}, not #{required_version}. Set :care_about_ruby_version if you want to fix this."
          return false
        end
      else
        logger.info "Ruby version mismatch. Installed version: #{installed_version}, required is #{required_version}"
        return true
      end
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

      # fix https://github.com/iain/roundsman/issues/26
      variables.keys.each { |k| reset! k }
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

    set :ssh_login_options, '-L 3737:localhost:3737' # forward monit status server port

    desc "Open SSH connection to server"
    task :ssh do
      host = roles[:app].servers.first # silly approach
      exec "ssh #{ssh_login_options} #{fetch(:user)}@#{host}"
    end
    
    def sudo_runner
     (exists? :runner) ? (sudo as: runner) : ''
    end

    desc 'Run rails console'
    task :console do
      host = roles[:app].servers.first # silly approach
      cmd = "cd #{current_path} && #{sudo_runner} bundle exec rails console #{rails_env}"
      exec "ssh -t #{ssh_login_options} #{fetch(:user)}@#{host} #{cmd.shellescape}"
    end

    desc 'Run rake task. Example: cap mana:rake about'
    task :rake do
      host = roles[:app].servers.first # silly approach
      args = ARGV.drop_while { |a| a != 'mana:rake' }[1..-1].join ' '
      cmd = "cd #{current_path} && #{sudo_runner} RAILS_ENV=#{rails_env} bundle exec rake #{args}"
      exec "ssh #{fetch(:user)}@#{host} #{cmd.shellescape}"
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

    namespace :addon do
      task :mascot do
        file = File.join("config", "deploy", "mascot.txt")

        if File.exist?(file) && show_mascot
          puts File.read(file)
        end

      end

      task :confirmation do
        if ask_confirmation
          set(:confirmed) do
            project = "#{application.upcase} (#{stage.upcase})"
            project = Array.new(((72 - project.length) / 2).ceil, "").join(" ") + project

            puts <<-WARN

        ========================================================================
        #{project}
        ========================================================================

          WARNING: You're about to perform actions on application server(s)
          Please confirm that all your intentions are kind and friendly

        ========================================================================

            WARN
            answer = Capistrano::CLI.ui.ask "  Are you sure you want to continue? (Y) "
            if answer == 'Y' then true else false end
          end

          unless fetch(:confirmed)
            puts "\nDeploy cancelled!"
            exit
          end
        end
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

  before 'deploy', 'mana:addon:mascot'
  before 'deploy', 'mana:addon:confirmation'
end
