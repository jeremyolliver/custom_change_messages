CustomChangeMessages
====================

[![Code Climate](https://codeclimate.com/repos/530c01aae30ba04b780004f8/badges/90ec4dc6e56ffd805864/gpa.png)](https://codeclimate.com/repos/530c01aae30ba04b780004f8/feed)

CustomChangeMessages is a rails plugin for providing a nicely formatted log message recording any edits made to an active record object.
This is based off of the ActiveRecord::Dirty module, making this plugin compatible with rails versions 2.1 and up. There is little to no configuration required, with all columns included by default (except for id, and created\_at, updated\_at timestamps), and belongs_to associations handled nicely with the default options configurable.

Usage
=====

In a controllers #update action

```ruby
def update
  @post = Post.find(params[:id])
  @post.attributes = params[:post]
  @changes = @post.change_messages
  # Use this array to either log history, display in a flash message, or in a mailer.
  # => ["Title has changed from 'Ruby on Rails plugin' to '[Update] Ruby on Rails plugin'", "Category has changed from 'Ruby' to 'Ruby on Rails'"]
  @post.save!
end
```

API
===

ActiveRecord extensions:

`change_message_for(attribute)` # Returns a string message representation of the attribute that has changed

`change_messages` # Returns an array of the messages for each changed attribute

Installation
============

    gem install custom_change_messages

Rails 2.X

    # config/environment.rb
    config.gem "custom_change_messages"

Rails 3.X

    # Gemfile
    gem "custom_change_messages"


Requirements: active record, version 2.1 or greater, if you use an earlier version you can try using http://code.bitsweat.net/svn/dirty which backports the ActiveRecord::Dirty code that this gem depends on to earlier rails versions.


Detailed Example
================

The main use of this is to help clean up controller actions, such as:

```ruby
class ItemsController < ApplicationController

  def update
    @item.attributes = params[:item]
    Mailer.deliver_item_update(@item, @item.change_messages.to_sentence)
    @item.save!

  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.reord.error_messages
    redirect_to item_url(@item)
  end

end
```

In this example we use `attributes=` instead of `update_attributes` because the change\_messages functionality is required to be called before you save the object, detecting what is changed from the state read from the database. For more advanced uses, you can add in `before_save` hooks to log changed details for you.

`@item.change_messages.to_sentence` will return human readable mesages in a string format such as:
=> "Description has changed from 'Nice and easy' to 'This task is now rather long and arduous', User has changed from 'Jeremy' to 'Guy', and Due Date has been rescheduled from '09/11/2008' to '10/11/2008'"

The messages for each attribute are also customizable, which is especially handy for dealing with belongs_to
assocations. Here's a more complicated example:

Use the `custom_message_for` method to customize the message for the attribute, specifying `:display => :name`
will use the method/attribute :name for displaying the record that the item belongs to

The `skip_message_for` method can be used to prevent stop any changes to a particular attribute showing up

```ruby
class Item < ActiveRecord::Base
  belongs_to :person

  custom_message_for :person, :display => :username # display the person's username instead of the id
  custom_message_for :due_on, :as => "Due Date", :message => "has been rescheduled", :format => :pretty_print_date
  # change the syntax of the message for working with dates, because it makes more sense that way

  # this method is used for formatting the due_on field when it changes
  def pretty_print_date(value = self.due_on)
    value.strftime("%d/%m/%Y")
  end
end
```

```ruby
class Person < ActiveRecord::Base
  custom_message_for :username, :as => "Name"
  skip_message_for :internal_calculation
end
```

```
p = Person.create!(:username => "Jeremy")
p2 = Person.create!(:username => "Optimus Prime")
i = Item.create!(:name => "My Task", :description => nil, :person => p, :due_on => Date.today)
i.attributes = {:person => p2, :description => "This task is difficult, might need some help"}

i.change_messages
=> ["Due Date has been rescheduled from '4/12/2008' to '5/12/2008'", "Person has changed from 'Jeremy' to 'Optimus Prime'", "Description has changed from '' to 'This task is difficult, might need some help'"]
```


Copyright (c) 2008 Jeremy Olliver, released under the MIT license
