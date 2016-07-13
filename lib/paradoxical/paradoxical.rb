require 'paradoxical/parser'
require 'paradoxical/printer'

module Paradoxical
	def self.parse(path)
		text = File.read(path, mode: 'r:bom|utf-8')
		Parser.instance.parse(text)
	end

	def self.parse_text(text)
		Parser.instance.parse(text)
	end

	def self.print_file(text, path)
		File.open(path, 'w') do |f|
			f.write(Printer.print(text))
		end
	end

	def self.print(text)
		Printer.print(text)
	end
end

