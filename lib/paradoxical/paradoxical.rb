require_relative 'parser'
require_relative 'printer'

module Paradoxical
	def self.parse(path)
	  begin
      text = File.read(path, mode: 'r:bom|utf-8')
      text = text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      Parser.instance.parse(text)
    rescue Exception => e
      puts "ERROR: #{e.message} while parsing #{path}"
      require 'ap';ap e.backtrace
    end
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

