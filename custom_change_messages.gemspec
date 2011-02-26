Gem::Specification.new do |s|
  s.name        = "custom_change_messages"
  s.version     = "0.2.0"
  s.summary     = "Change history for ActiveRecord models"
  s.email       = "jeremy.olliver@gmail.com"
  s.homepage    = "http://github.com/jeremyolliver/custom_change_messages"
  s.description = "Change history for ActiveRecord models in a customisable format, making user friendly logging for change history simple"
  s.author      = "Jeremy Olliver"

  s.files = ["README","Rakefile","MIT-LICENSE"]
  s.files += ["lib/custom_change_messages.rb", "lib/custom_change_messages/active_record.rb"]
  s.test_files = ["test/active_record_test.rb", "test/custom_change_messages_test.rb", "test/database.yml", "test/schema.rb", "test/test_helper.rb"]

  s.add_dependency("activerecord", [">= 2.1.0"])

  s.add_development_dependency("sqlite3-ruby", [">= 1.2.5"])
end