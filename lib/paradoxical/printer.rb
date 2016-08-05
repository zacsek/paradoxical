require 'date'
require 'awesome_print'
require 'pry'

module Paradoxical
	module Printer
		class << self
			def print(hash)
				p_expressions(hash)
			end

			private

			def indent(nr)
				" "*4*nr
			end

			def p_expressions(hash, lvl = 0)
				out = ""
				hash.each do |k, v|
					out += p_expression(k, v, lvl)
				end
				out
			end

			def p_expression(lhs, rhs, lvl)
				#variable
				out = ""
				out += indent(lvl)
				if lhs.to_s =~ /\d{4}-\d{2}-\d{2}/
						lhs = lhs.to_s.tr('-','.')
				end
				out += "#{lhs}"

				#operator
				if rhs =~ /^([<>])\s+([^\s]+)/
					out += " #{$1} "
					rhs = $2
				else
					out += " = "
				end

				#value
				case rhs
				when Hash
					out += p_hash(rhs, lvl+1)
				when Array
					if rhs.first == :multi
						out = ""
						arr = rhs.clone
						arr.shift
						arr.each { |r| out += p_expression(lhs, r, lvl) }
					else
						out += p_array(rhs, lvl+1)
					end
				when Fixnum
					out += "#{rhs}"
				when Float
					out += "#{rhs}"
				when String
					if rhs =~ /\d{4}-\d{2}-\d{2}/
						rhs.tr!('-','.')
					end
					out += "#{rhs}"
				end

				out += "\n"
				out
			end

			def p_hash(hsh, lvl)
				out = "{\n"
				out += p_expressions(hsh, lvl)
				out += indent(lvl-1) + "}\n"
			end

			def p_array(arr, lvl)
				out = "{\n"

				out += indent(lvl)
				out += arr.reduce("") { |s,v| s+= "#{v} " }.chomp(' ')
				out += "\n"

				out += indent(lvl-1) + "}\n"
				out
			end
		end
	end
end

