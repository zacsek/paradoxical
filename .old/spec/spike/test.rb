require 'citrus'
require 'pry'

g = Citrus::Grammar.new do
	rule :number do
		/[0-9]+/
	end
end

g.rules[:number].extension = Module.new { def value; to_s.to_i end }
binding.pry
puts g.parse('123').value
