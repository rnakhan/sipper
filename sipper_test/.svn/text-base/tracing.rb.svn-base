module Tracing
def Tracing.included(into)
into.instance_methods(false).each { |m|
Tracing.hook_method(into, m) }
def into.method_added(meth)
unless @adding
@adding = true
Tracing.hook_method(self, meth)
@adding = false
end
end
end
def Tracing.hook_method(klass, meth)
klass.class_eval do
alias_method "old_#{meth}", "#{meth}"
define_method(meth) do |*args|
puts "#{meth} start"
self.send("old_#{meth}",*args)
puts "#{meth} end"
end
end
end
end
