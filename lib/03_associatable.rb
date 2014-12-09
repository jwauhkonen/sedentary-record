require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name || class_name.tableize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name.downcase}_id".to_sym
    @class_name = options[:class_name] || "#{name.capitalize}"
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase}_id".to_sym
    @class_name = options[:class_name] || "#{name.to_s.singularize.capitalize}"
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    
    define_method(name) do 
      f_key = options.send(:foreign_key)
      options.model_class.where({id: attributes[f_key]}).first
    end
    
    assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      f_key = options.send(:foreign_key)
      options.model_class.where("#{f_key}".to_sym => attributes[:id])
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
