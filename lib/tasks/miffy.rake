namespace :miffy do

  desc "Updates legislation-uk code, clears acts from db."
  task :clear_acts => :environment do
    puts(cmd = "git submodule init")
    puts `cd #{RAILS_ROOT}; #{cmd}`
    puts(cmd = "git submodule update")
    puts `cd #{RAILS_ROOT}; #{cmd}`
    count = Act.count
    puts "clearing #{count} act#{count == 1 ? '' : 's'} from db"
    Act.find_each { |act| act.destroy }
  end

end