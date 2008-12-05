require File.dirname(__FILE__) + '/test_helper.rb'

class CustomChangeMessagesTest < Test::Unit::TestCase

  class Item < ActiveRecord::Base
  end
  
  def setup
    # schema needs to be loaded in the other test, so don't load it here a second time, unless this is run first or isolated
    unless Item.connected?
      load_schema
    end
  end

  def test_schema_has_loaded_correctly
    assert_nothing_raised do
      Item.all
    end
  end

end
