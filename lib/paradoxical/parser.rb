require 'singleton'
require 'citrus'
require 'yaml'
require 'date'

class Hash
	alias_method :old_at, :[]
	alias_method :old_at_eq, :[]=

	def [](key)
		if key.is_a?(String) && key.start_with?('xp:')
			begin
				key = key.gsub('xp:','')
				path = key.split('/').map { |p| p.to_sym }
				hash = self
				path.each { |p|
					if hash.has_key?(p)
						hash = hash[p]
						if hash.is_a?(Array) && hash.first == :multi
							hash.shift
							hash = hash.first
						end
					else
						return nil
					end
				}
				hash
			rescue
				puts "Error selecting key:#{key}"
				ap self
				ap path
				puts
				raise
			end

		else
			old_at(key)
		end
	end

	def []=(key, value)
		if key.is_a?(String) && key.start_with?('xp:')
			begin
			key = key.gsub('xp:','')
				path = key.split('/').map { |p| p.to_sym }
				hash = self
				path[0..-2].each { |p| hash = hash[p] }
				hash[path[-1]] = value
			rescue
				puts "K:#{key} V:#{value}"
				raise
			end
		else
			old_at_eq(key, value)
		end
		value
	end
end

module Paradoxical
	class Parser
		include Singleton

		def initialize
		  fname = File.join(File.dirname(__FILE__), 'paradoxical.citrus')
			@citrus = Citrus.load(fname, :consume => false).first
		end

		def parse(text)
			ParadoxicalGrammar.parse(text, :consume => false).value
		end
	end

end
