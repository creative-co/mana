module Mana
  class ManaRailtie < Rails::Railtie
    rake_tasks do
      load 'tasks/mana.rake'
    end
  end
end
