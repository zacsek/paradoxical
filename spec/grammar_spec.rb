require 'ap'
require 'citrus'
require_relative 'spec_helper'


RSpec.describe 'Grammar' do
	let(:cfg) { File.read('../lib/paradoxical.citrus') }
	let(:grammar) {
		Object.send(:remove_const, :ParadoxicalGrammar) if Object.const_defined? :ParadoxicalGrammar
		Citrus.eval(cfg).first
	}

	context '#scalar' do
		it 'should parse integer' do
			expect { grammar.parse('123', :root => :scalar) }.not_to raise_error
			expect( grammar.parse('123', :root => :scalar).value ).to eq(123)
			expect( grammar.parse('123', :root => :scalar).value.class ).to eq(123.class)
		end

		it 'should parse float' do
			expect { grammar.parse('123.45', :root => :scalar) }.not_to raise_error
			expect( grammar.parse('123.45', :root => :scalar).value ).to eq(123.45)
			expect( grammar.parse('123.45', :root => :scalar).value.class ).to eq(123.45.class)
		end

		it 'should parse date' do
			expect( grammar.parse('2016.12.24', :root => :scalar).value ).to eq(Date.new(2016,12,24))
			expect( grammar.parse('2016.12.24', :root => :scalar).value.class ).to eq(Date)
		end

		it 'should parse string' do
			expect( grammar.parse('helloworld', :root => :scalar).value ).to eq("helloworld")
		end
		it 'should parse single qoute string' do
			expect( grammar.parse('\'helloworld\'', :root => :scalar).value ).to eq("helloworld")
		end
		it 'should parse double qoute string' do
			expect( grammar.parse('"helloworld"', :root => :scalar).value ).to eq("helloworld")
		end
	end

	context '#expressions' do
		it 'should match assignment expression' do
			match = grammar.parse('variable = 123', :root => :expression)
			expect( match.value[:variable] ).to eq(123)
		end

		it 'should match assignment expression without spaces' do
			match = grammar.parse('variable=123', :root => :expression)
			expect( match.value[:variable] ).to eq(123)
		end

		it 'should match less than expression' do
			match = grammar.parse('variable < 123', :root => :expression)
			expect( match.value[:variable] ).to eq('< 123')
		end

		it 'should match less than expression with weird key' do
			match = grammar.parse('2016.01.16 < 123', :root => :expression)
			expect( match.value[:"2016-01-16"] ).to eq('< 123')
		end

		it 'should match more than expression' do
			match = grammar.parse('variable > 123', :root => :expression)
			expect( match.value[:variable] ).to eq('> 123')
		end
	end

	context '#constructs' do
		it 'should match and return array' do
			match = grammar.parse('{ 1 2 3 4 5 }', :root => :array)
			expect( match.value ).to eq([1,2,3,4,5])
		end

		it 'should match and return hash' do
			text = <<-HERE.gsub!(/^\s*/,'').gsub!(/\s*$/,'')
			{
				var1 = hello
				date < 2016.01.01
				2016.01.01 > now
				var2 = 123
			}
			HERE
			expected = {
				:var1 => "hello",
				:date => "< 2016-01-01",
				:"2016-01-01" => "> now",
				:var2 => 123
			}
			match = grammar.parse(text, :root => :hash)
			expect( match.value ).to eq(expected)
		end

		it 'should match expression with array' do
			text = "arr = { 1 2 3 4 5}"
			match = grammar.parse(text, :root => :expression)
			expect( match.value ).to eq({ :arr => [1,2,3,4,5] })
		end

		it 'should match expression with hash' do
			text = "arr = { var = 1 }"
			match = grammar.parse(text, :root => :expression)
			expect( match.value ).to eq({ :arr => { :var =>  1} })
		end

		it 'should match multi-expression with hash' do
			text = <<-HERE.gsub!(/^\s*/,'').gsub!(/\s*$/,'')
				date = 2016.01.01
				val  < 200
				arr  = { 1 2 3 4 5 }
				hsh  = {
					var1 = string
					var2 = 'qstring'
					var3 = "qqstring"
				}
			HERE
			expected = {
				:date => Date.new(2016, 1, 1),
				:val  => "< 200",
				:arr  => [ 1, 2, 3, 4, 5],
				:hsh  => {
					:var1 => "string",
					:var2 => "qstring",
					:var3 => "qqstring"
				}
			}
			match = grammar.parse(text, :root => :expressions)
			expect( match.value ).to eq(expected)
		end
	end

end
