require 'paradoxical/version'
require 'paradoxical/parser'
require 'paradoxical/printer'

require 'awesome_print'

module Paradoxical
	def self.parse(path)
		text = File.read(path, mode: 'r:bom|utf-8')
		Parser.instance.parse(text)
	end

	def self.parse_text(text)
		Parser.instance.parse(text)
	end

	def self.print(text, path)
		File.open(path, 'w') do |f|
			f.write(text)
		end
	end

	def self.print(text)
		Printer.instance.print(text)
	end
end

