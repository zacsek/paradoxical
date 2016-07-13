require 'citrus'

repeat = <<-HERE
grammar Repeat
	rule multiple
		'ab'1*2
	end
end
HERE


RSpec.describe 'Citrus' do
	context 'terminals' do
		it 'should match exact string terminal' do
			grammar = Citrus::Grammar.new { rule(:exact) { 'helloworld' } }
			expect(grammar.parse('helloworld')).to eq('helloworld')
		end

		it 'should match regexp' do
			grammar = Citrus::Grammar.new {
				rule(:regex) {
					/.o{2}bar/
				}
			}
			expect(grammar.parse('foobar')).to eq('foobar')
		end

		it 'should fail when string cannot be parsed' do
			grammar = Citrus::Grammar.new {
				rule(:regex) {
					/.o{2}bar/
				}
			}
			expect{ grammar.parse('helloworld') }.to raise_error(Citrus::ParseError)
		end

		it 'should parse with Citrus\'s own type' do
			grammar = Citrus::Grammar.new { rule(:abc) { 'abc'*2 } }
			expect( grammar.parse('abcabc') ).to eq('abcabc')
		end
	end

	context 'extensions' do
		it 'should run the extension when its rule is matching' do
			grammar = Citrus::Grammar.new { 
				rule(:number) { 
					/[0-9]+/
				}
			}
			grammar.rules[:number].extension= Module.new { def value; self[0].to_s.to_i end }
			expect( grammar.parse('1234').value ).to eq(1234)
		end
	end

	context 'citrus dsl' do
		it 'should capture repetition, with minimum and maximum repetition' do
			grammar = Citrus.eval(repeat).first
			expect(grammar.parse('abab')).to eq('abab')
			expect{ grammar.parse('ababab') }.to raise_error(Citrus::ParseError)
			expect{ grammar.parse('') }.to raise_error(Citrus::ParseError)
		end

		#it 'should match zero or more repetition'
		#it 'should match one or more repetition'
		#it 'should match optionally'

		#it 'should match with lookahead: and predicate'
		#it 'should match with lookahead: negative predicate'
	end

end

