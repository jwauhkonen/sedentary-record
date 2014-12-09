require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    column_names = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      SQL
      
    column_names.first.map { |name| name.to_sym }
  end

  def self.finalize!
    
    columns.each do |column|
      ivar = "@#{column}"
      
      define_method(column) { attributes[column] }
      
      define_method("#{column}=") do |value| 
        attributes[column] = value
      end
    end
    
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    all_columns = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM 
      #{table_name}
      SQL
      
    parse_all(all_columns)
  end

  def self.parse_all(results)
    instances = []
    
    results.each do |result|
      instances << self.new(result)
    end
    
    instances
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
    SELECT 
      * 
    FROM
      #{table_name}
    WHERE
      id = ?
      SQL
      
    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      
      attr_setter = "#{attr_name}=".to_sym
      
      self.send(attr_setter, value)
      
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |column| self.send(column) }
  end

  def insert
    col_names = "(#{self.class.columns.join(", ")})"
    question_marks = "(#{(["?"] * self.class.columns.count).join(", ")})"
    p col_names
    p question_marks
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} #{col_names}
    VALUES
      #{question_marks}
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    column_setters = "#{self.class.columns.map { |column| "#{column} = ?" }.join(", ")}"
    p column_setters
    
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
    #{self.class.table_name}
    SET
      #{column_setters}
    WHERE
      id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
