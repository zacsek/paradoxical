require 'citrus'
require 'ap'

Object.send(:remove_const, :PNumber) if Object.const_defined? :PNumber

txt = <<-HERE
grammar PNumber
	rule number
		( term:( float | integer ) space* ) { capture(:term).value }
	end

	rule integer
		( /[0-9]+/ ) { to_s.to_i }
	end

	rule float
		( integer '.' integer ) { to_s.to_f }
	end

  rule space
    /\s/
  end
end
HERE

a = Citrus.eval(txt).first
m = a.parse '123'
puts "#{m.value.class} : #{m.value}"

m = a.parse '123.45'
puts "#{m.value.class} : #{m.value}"

m = a.parse '123.45  '
puts "#{m.value.class} : #{m.value}"
