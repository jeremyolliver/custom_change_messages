ActiveRecord::Base.class_eval do
  
  # hash and array to keep track of the customised messages, belongs_to associations, and any skipped attributes
  class_inheritable_hash :custom_dirty_messages # The watched attributes with configuration options {:field_name => options, ...}
  class_inheritable_hash :belongs_to_key_mapping
  
  CUSTOM_CHANGE_MESSAGE_DEFAULTS = {:message => "has changed", :prefix => "from", :suffix => "to"}
  DEFAULT_SKIPPED_COLUMNS = [:updated_at, :created_at, :id]
  
  DEFAULT_BELONGS_TO_DISPLAY_OPTIONS = [:name, :title, :display, :description]
  
  class << self
  
    def initialise_default_change_messages
      unless self.custom_dirty_messages
        self.custom_dirty_messages = {}
        self.belongs_to_key_mapping = {}
        
        model_columns = self.column_names.collect(&:to_sym)
        
        # Don't include foreign keys for belongs_to associations by default, they must be added manually
        self.reflect_on_all_associations(:belongs_to).each do |association|
          # model_columns -= [association.primary_key_name.to_sym] # Remove the key name from the attributes that will be watched by default
          self.belongs_to_key_mapping.merge!(association.primary_key_name.to_sym => association.name)
        end
        
        # Register each column with default options
        model_columns.each do |column_name|
          key = key_name_for(column_name)
          next if DEFAULT_SKIPPED_COLUMNS.include?(key)
          # custom_dirty_messages[key] = CUSTOM_CHANGE_MESSAGE_DEFAULTS.clone
          custom_message_for(key)
        end
      end
    end
  
    def custom_message_for(*attr_names)
      initialise_default_change_messages
      
      options = attr_names.extract_options!
      options.symbolize_keys!

      attr_names.each do |attribute|
        key = key_name_for(attribute)
        
        if is_association?(key)
          association = self.reflect_on_association(key)
          display_method = options[:display]
          raise "Incorrect :display option. #{display_method} is undefined for #{association.class_name}" if display_method && !method_or_attribute_exists(association, display_method)
          display_method ||= find_default_display_method(association)
          puts "***Warning*** couldn't detect a display method for #{key.to_s}, please set a display option e.g. custom_message_for :#{key.to_s}, :display => :my_display_method (where #{association.class_name}#my_display_method) is defined otherwise #to_s will be used as the default" unless display_method
          display_method ||= :to_s
          
          defaults = CUSTOM_CHANGE_MESSAGE_DEFAULTS.merge({:as => association.name.to_s.humanize.titleize, :display => :to_s})
          options = defaults.merge(options).merge({:type => :belongs_to})
        end
        
        if self.custom_dirty_messages[key]
          # override defaults
          self.custom_dirty_messages[key].merge!(options)
        else
          # Set values for any not already being watched
          self.custom_dirty_messages.merge!({key => options})
        end
      end
    end
  
    def skip_message_for(*attr_names)
      initialise_default_change_messages
      
      attr_names.extract_options!
      attr_names.each do |column_name|
        key = key_name_for(column_name)
        self.custom_dirty_messages.delete(key)
      end
    end
    
    def is_association?(attribute)
      belongs_to_key_mapping.keys.include?(attribute.to_sym) || belongs_to_key_mapping.values.include?(attribute.to_sym)
    end
  
    def key_name_for(attribute)
      attribute = attribute.to_sym
      if is_association?(attribute)
        # Use the association name for belongs_to (could be already passed in)
        belongs_to_key_mapping[attribute] || attribute
      else
        attribute
      end
    end
    
    private
    
    def method_or_attribute_exists(association, method)
      klass = association.class_name.constantize
      (klass.column_names + klass.instance_methods).include?(method.to_s)
    end
    
    def find_default_display_method(association)
      DEFAULT_BELONGS_TO_DISPLAY_OPTIONS.each do |meth_name|
        return meth_name if method_or_attribute_exists(association, meth_name)
      end
      nil
    end
    
  end
  
  def change_messages
    self.class.initialise_default_change_messages
    
    messages = []
    changes.each do |attribute, diff|
      key = self.class.key_name_for(attribute) # belongs_to association name, or column_name
      
      if self.class.custom_dirty_messages.keys.include?(key)
        messages << change_message_for(key, diff)
      end
    end
    messages
  end
  
  def change_message_for(attribute, changes = nil)
    self.class.initialise_default_change_messages
    
    column_name = column_name_for(attribute)
    changes ||= self.send((column_name.to_s + "_change").to_sym)
    
    key = self.class.key_name_for(attribute)
    
    val = "#{attr_name(key)} #{message_option_value(key, :message)}"
    val += " #{message_option_value(key, :prefix)} \'#{attr_display(key, changes.first)}\'" unless message_option_value(key, :no_prefix)
    val += " #{message_option_value(key, :suffix)} \'#{attr_display(key, changes.last)}\'" unless message_option_value(key, :no_suffix)
    val
  end
  
  private
  
  def column_name_for(attribute)
    attribute = attribute.to_sym
    if self.class.belongs_to_key_mapping.values.include?(attribute)
      self.class.belongs_to_key_mapping.to_a.select {|col, assoc_name| assoc_name == attribute }.first.first
    else
      attribute
    end
  end
  
  # check if it's an association name, or if the attribute is being watched
  def attr_name(key)
    value = if self.class.custom_dirty_messages[key]
      if (name = self.class.custom_dirty_messages[key][:as])
        name
      else
        key
      end
    else
      key
    end
    value.to_s.humanize.titleize
  end
  
  def attr_display(key, value)
    if self.class.custom_dirty_messages[key]
      if (meth = self.class.custom_dirty_messages[key][:format])
        return self.send(meth, value)
      elsif (meth = self.class.custom_dirty_messages[key][:display]) && self.class.is_association?(key)
        assoc = self.class.reflect_on_association(key)
        raise "must set the :display option for belongs_to associations e.g. :display => :name where name is a method on the parent object" unless meth
        finder = ("find_by_" + assoc.klass.primary_key).to_sym
        return assoc.klass.send(finder, value).send(meth.to_sym)
      end
    end
    return value.to_s
  end
  
  def message_option_value(key, option)
    if self.class.custom_dirty_messages[key]
      self.class.custom_dirty_messages[key][option] || CUSTOM_CHANGE_MESSAGE_DEFAULTS[option]
    else
      CUSTOM_CHANGE_MESSAGE_DEFAULTS[option]
    end
  end
  
  
end