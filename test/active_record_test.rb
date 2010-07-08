require File.dirname(__FILE__) + '/test_helper.rb'

load_schema

class Person < ActiveRecord::Base
  custom_message_for :username, :as => "Name"
  skip_message_for :internal_calculation
  
end

class Category < ActiveRecord::Base
  
  def to_s
    name
  end
  
end

class Item < ActiveRecord::Base
  DATEFORMAT = "%d/%m/%Y"
  belongs_to :person
  belongs_to :category
  
  custom_message_for :person, :display => :username
  custom_message_for :due_on, :as => "Due Date", :message => "has been rescheduled", :format => :pretty_print_date
  
  def pretty_print_date(value = self.due_on)
    value.strftime(DATEFORMAT)
  end
end


class ActiveRecordTest < Test::Unit::TestCase
  
  def test_active_record_extension
    i = Item.create!
    assert i.respond_to?(:change_messages)
    assert i.respond_to?(:change_message_for)
  end
  
  def test_ignores_timestamps
    i = Item.create!
    i.attributes = {:created_at => Date.tomorrow, :updated_at => Date.tomorrow}
    puts i.change_messages
    assert i.change_messages.empty?
  end
  
  def test_belongs_to_and_keys_ignored_by_default
    c1 = Category.create(:name => "Updates")
    c2 = Category.create(:name => "Posts")
    i = Item.create!(:category => c1)
    
    i.category = c2
    
    assert_nil i.change_message_for(:category) # An error should be raised if the display is not set for a belongs_to
    assert_nil i.change_message_for(:category_id) # This attribute should be skipped because it's a foreign key for the belongs to association
  end
  
  def test_unwatching
    p = Person.create!(:username => "Robot", :internal_calculation => 1)
    p.internal_calculation = 42
    assert p.change_messages.empty?
  end
  
  def test_labeling_attributes
    # ensure associations are given the correct name. In this case username has been renamed to 'Name'
    u = Person.create!(:username => "Jeremy")
    u.username = "Jeremy O"
    
    assert_equal "Name has changed from \'Jeremy\' to \'Jeremy O\'", u.change_message_for(:username)
  end
  
  def test_associations_loaded
    i = Item.create!(:name => "My Cool Task")
    assert i.class.custom_dirty_messages[:person]
    assert_equal :belongs_to, i.class.custom_dirty_messages[:person][:type]
  end
  
  def test_display_of_associations
    u = Person.create!(:username => "Jeremy")
    u2 = Person.create!(:username => "Guy")
    i = Item.create!(:name => "My Task", :description => "super", :person => u)
    i.person = u2
    
    assert_equal "Person has changed from \'Jeremy\' to \'Guy\'", i.change_message_for(:person)
  end
  
  def test_handling_of_nil_attrs
    i = Item.create!(:name => "Namae wa", :description => nil)
    i.description = "Japanese sentence"
    
    assert_nothing_raised do
      i.change_messages
    end
  end
  
  def test_formatting_attributes
    i = Item.create!(:name => "Task", :due_on => Date.today)
    i.due_on = Date.tomorrow
    
    today = Date.today.strftime(Item::DATEFORMAT)
    tomorrow = Date.tomorrow.strftime(Item::DATEFORMAT)
    assert_equal "Due Date has been rescheduled from '#{today}' to '#{tomorrow}'", i.change_message_for(:due_on)
  end
  
  def test_full_sentence_changes
    p = Person.create!(:username => "Jeremy")
    p2 = Person.create!(:username => "Optimus")
    i = Item.create!(:name => "My Task", :description => "Nice and easy", :person => p, :due_on => Date.today)
    i.attributes = {:person => p2, :description => "This task is now rather long and arduous", :due_on => Date.tomorrow }
    
    today = Date.today.strftime(Item::DATEFORMAT)
    tomorrow = Date.tomorrow.strftime(Item::DATEFORMAT)
    
    assert_equal "Description has changed from 'Nice and easy' to 'This task is now rather long and arduous', Person has changed from 'Jeremy' to 'Optimus', and Due Date has been rescheduled from '#{today}' to '#{tomorrow}'", \
    i.change_messages.to_sentence
  end
  
end
