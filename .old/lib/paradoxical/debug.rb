$LOAD_PATH.unshift '.'
require 'citrus'
require 'ap'
require 'date'
require 'yaml'

require 'printer'

#path = ARGV.shift
#txt = File.read(path, mode: 'r:bom|utf-8')
gr  = Citrus.load('paradoxical.citrus').first
#h = ParadoxicalGrammar.parse(txt).value;ap h

#h2 = ParadoxicalGrammar.parse(str).value;ap h2
#h = ParadoxicalGrammar.parse("add_named_threat = { threat = 40 }", :root => :expressions).value;ap h
#h = ParadoxicalGrammar.parse("    # 1939_bookmark_threat", :root => :expressions).value;ap h
#h = ParadoxicalGrammar.parse("add_named_threat = { threat = 40\n    # 1939_bookmark_threat\n }", :root => :expressions).value;ap h
#h = ParadoxicalGrammar.parse("1933.3.5", :root => :scalar).value;ap h
#h = ParadoxicalGrammar.parse('"1933.3.5"', :root => :scalar).value;ap h

#txt = <<-HERE
	#add_ideas = {
		#henschel
		#ig_faben
		#heinrich_himmler
		#rudolf_hess
		#ludwig_beck
		#gerd_von_rundstedt
		##laws
		#war_economy # law
		#extensive_conscription
	#}
#HERE
#h = ParadoxicalGrammar.parse(txt).value;ap h
#h = ParadoxicalGrammar.parse("{ electronics_folder	#secret_weapons_folder\n}", :root => :array).value;ap h

txt = <<-HERE
{
	infantry_folder
	support_folder
	armour_folder
	artillery_folder
	air_techs_folder
	naval_folder
	industry_folder
	land_doctrine_folder
	naval_doctrine_folder #comment
	air_doctrine_folder
	electronics_folder
	#secret_weapons_folder
}
HERE
h = ParadoxicalGrammar.parse(txt, :root => :array).value;ap h
#str =  Paradoxical::Printer.print(h)
#puts str


#
#		/[a-zA-Z0-9_\-\\\/!$%^&*.]+/
#
		#( '{' ( full_line_comment | ( space* scalar space* line_end_comment? )  )*  '}' space* ) {
			#arr = []
			#captures(:scalar).flatten.each do |match|
				#arr << match.value
			#end
			#arr
		#}
