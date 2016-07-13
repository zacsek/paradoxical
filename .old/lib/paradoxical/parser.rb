require 'singleton'
require 'citrus'
require 'yaml'
require 'date'
require 'delegate'


module Paradoxical
	class Parser
		include Singleton

		def initialize
			@citrus = Citrus.load('paradoxical.citrus').first
		end

		def parse(text)
			XHash.new(ParadoxicalGrammar.parse(text).value)
		end
	end

	class XHash < SimpleDelegator
		def [](key)
			if key.is_a?(String) && key.include?('/')
				path = key.split('/').map { |p| p.to_sym }
				self.dig(*path)
			else
				super
			end
		end

		def []=(key, value)
			if key.is_a?(String) && key.include?('/')
				path = key.split('/').map { |p| p.to_sym }
				hash = self
				path[0..-2].each { |p| hash = hash[p] }
				hash[path[-1]] = value
			else
				super
			end
			value
		end
	end
end
