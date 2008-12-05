ActiveRecord::Base.class_eval do
  
  # hash and array to keep track of the customised messages, belongs_to associations, and any skipped attributes
  class_inheritable_hash :custom_dirty_messages
  class_inheritable_array :skipped_dirty_attributes
  
  class << self
  
    def init_messages
      unless self.custom_dirty_messages
        self.custom_dirty_messages = {}
        self.reflect_on_all_associations(:belongs_to).each do |association|
          self.custom_dirty_messages[association.primary_key_name.to_sym] = {:type => :belongs_to, :association_name => association.name, :as => association.name.to_s.capitalize}
        end
      end
    end
  
    def custom_message_for(*attr_names)
      init_messages
      options = attr_names.extract_options!
      attr_names.each do |attribute|
        key = key_for(attribute)
        if self.custom_dirty_messages[key]
          # if options are being passed for an associations attribute, or an association
          self.custom_dirty_messages[key].merge!(options)
        else
          self.custom_dirty_messages.merge!({attribute.to_sym => options})
        end
      end
    end
  
    def skip_message_for(*attr_names)
      self.skipped_dirty_attributes ||= [:updated_at, :created_at, :id]
      attr_names.extract_options!
      self.skipped_dirty_attributes += attr_names
    end
  
    private
  
    def key_for(attribute)
      # first check if it's a belongs_to association
      if (assoc = self.reflect_on_association(attribute))
        assoc.primary_key_name.to_sym
      else
        attribute.to_sym
      end
    end
  
  end
  
  def change_messages
    messages = []
    changes.each do |attribute, diff|
      attribute = attribute.to_sym
      self.class.skipped_dirty_attributes ||= [:updated_at, :created_at, :id]
      next if self.class.skipped_dirty_attributes.include?(attribute)
      messages << change_message_for(attribute, diff)
    end
    messages
  end
  
  def change_message_for(attribute, changes = nil)
    attribute = key_for(attribute)
    changes ||= self.send((attribute.to_s + "_change").to_sym)
    val = "#{attr_name(attribute)} #{watch_value(attribute, :message)}"
    val += " #{watch_value(attribute, :prefix)} \'#{attr_display(attribute, changes.first)}\'" unless watch_value(attribute, :no_prefix)
    val += " #{watch_value(attribute, :suffix)} \'#{attr_display(attribute, changes.last)}\'" unless watch_value(attribute, :no_suffix)
    val
  end
  
  private
  
  def key_for(attribute)
    # first check if it's a belongs_to association
    if (assoc = self.class.reflect_on_association(attribute))
      assoc.primary_key_name.to_sym
    else
      attribute.to_sym
    end
  end
  
  # check if it's an association name, or if the attribute is being watched
  def attr_name(attribute)
    if self.class.custom_dirty_messages[attribute]
      if (name = self.class.custom_dirty_messages[attribute][:as])
        name
      elsif is_association?(attribute)
        (n = self.class.custom_dirty_messages[attribute][:association_name]) ? n.to_s.capitalize : attribute.to_s.capitalize
      else
        attribute.to_s.capitalize
      end
    else
      attribute.to_s.capitalize
    end
  end
  
  def attr_display(attribute, value)
    attribute = key_for(attribute)
    if self.class.custom_dirty_messages[attribute]
      if (meth = self.class.custom_dirty_messages[attribute.to_sym][:format])
        return self.send(meth, value)
      elsif (meth = self.class.custom_dirty_messages[attribute.to_sym][:display])
        raise ":display option set on an attribute which isn't a belongs_to association" unless is_association?(attribute)
          assoc = self.class.reflect_on_association(association_name(attribute))
          finder = ("find_by_" + assoc.klass.primary_key).to_sym
          return assoc.klass.send(finder, value).send(meth.to_sym)
      end
    end
    return value.to_s
  end
  
  def association_name(attribute)
    self.class.custom_dirty_messages[attribute][:association_name]
  end
  
  def is_association?(attribute)
    attribute = key_for(attribute)
    self.class.custom_dirty_messages[attribute][:association_name]
  end
  
  def watch_value(attribute, option)
    if self.class.custom_dirty_messages[attribute.to_sym]
      self.class.custom_dirty_messages[attribute.to_sym][option] || watch_option_defaults[option]
    else
      watch_option_defaults[option]
    end
  end
  
  def watch_option_defaults
    {:message => "has changed", :prefix => "from", :suffix => "to"}
  end
  
  
end