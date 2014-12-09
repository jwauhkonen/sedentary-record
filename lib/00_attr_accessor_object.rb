class AttrAccessorObject
  def self.my_attr_accessor(*names)
    
   names.each do |name|
     ivar = "@#{name}"
     
     define_method(name) { self.instance_variable_get(ivar) }
     
     define_method("#{name}=") do |argument|
       self.instance_variable_set(ivar, argument)
     end 
     
   end
    
  end
end
