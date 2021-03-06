require 'test/unit'

require 'rubygems'
require 'active_record'


def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  # ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue LoadError
      begin
        require 'sqlite3'
        'sqlite3'
      rescue LoadError
        puts "could not load sqlite for running the tests"
      end
    end

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end