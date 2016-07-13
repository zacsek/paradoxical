$LOAD_PATH.unshift(*%w(. ..))
require 'paradoxical/paradoxical'
require 'awesome_print'
require 'date'
require 'yaml'
require 'fileutils'
require 'singleton'

require 'benchmark'

module Hoi4
	GAME_PATH = File.join( Dir.home, '.steam/steam/steamapps/common/Hearts of Iron IV' )
	MOD_PATH  = File.join( Dir.home, '.local/share/Paradox Interactive/Hearts of Iron IV/mod' )
	OWN_PATH  = File.join( Dir.home, '.paradoxical/hoi4' )

	PATHS = {
		:countries => 'history/countries',
		:states => 'history/states',
		:tech => 'common/technologies',
	}
	
	GAME_PATHS = PATHS.map { |k,v| [k, File.join(GAME_PATH, v)] }.to_h

	class Cache
		include Singleton

		def self.cached?
			self.instance.cached?
		end

		def self.cache
			self.instance.cache
		end

		def self.id2name(id)
			cache[:id2name][id]
		end

		def self.country(id)
			name = id2name(id)
			{ name => cache[:countries][name] }
		end

		def self.states(id)
			name = id.to_s.upcase
			cache[:states].select do |_,state|
				state['xp:state/history/owner'] == name
			end
		end

		def self.tech
			cache[:tech]
		end

		attr_accessor :cache

		def initialize
			@cache = {
				:id2name => {},
				:countries => {},
				:states => {},
				:tech => {},
			}
			load_all
		end

		def load_all
			if cached?
				@cache.keys.each do |key|
					fname = File.join( OWN_PATH, key.to_s + '.yaml' )
					@cache[key] = YAML.load_file(fname)
				end
			else
				load_id2name
				load_countries
				load_states
				load_tech
				persist!
			end
		end

		def load_countries
			glob = File.join(GAME_PATHS[:countries], "*.txt")
			Dir[glob].each do |fname|
				name = File.basename(fname)
				@cache[:countries][name] = Paradoxical.parse(fname)
			end
		end

		def load_states
			glob = File.join(GAME_PATHS[:states], "*.txt")
			Dir[glob].each do |fname|
				name = File.basename(fname)
				@cache[:states][name] = Paradoxical.parse(fname)
			end
			@cache[:states]
		end

		def load_tech
			tags = Paradoxical.parse(File.join(GAME_PATH, 'common/technology_tags', '00_technology.txt'))
			dirs = tags[:technology_folders]
			glob = File.join(GAME_PATHS[:tech], "*.txt")
			Dir[glob].each do |fname|
				techs = Paradoxical.parse(fname)
				techs[:technologies].each do |tname, tdef|
					if tdef.is_a? Hash
						dir = tdef['xp:folder/name'] || :unknown
						yr  = tdef[:start_year]
						if dir && yr
							@cache[:tech][dir] ||= []
							@cache[:tech][dir] << [tname, yr] 
						end
					end
				end
			end
			@cache[:tech]
		end

		def load_id2name
			glob = File.join(GAME_PATHS[:countries], "*.txt")
			@cache[:id2name] = Dir[glob].reduce([]) do |arr, fname|
				name = File.basename(fname)
				id = name[/[A-Z]{3}/].downcase.to_sym
				arr << [id, name]
			end.to_h
		end

		def persist!
			FileUtils.mkdir_p(OWN_PATH) unless Dir.exist?(OWN_PATH)
			@cache.keys.each do |k|
				fname = File.join(OWN_PATH, k.to_s + '.yaml')
				File.write(fname, @cache[k].to_yaml)
			end
		end

		def cached?
			retv = true
			retv = retv && Dir.exist?(OWN_PATH)
			@cache.keys.each do |k|
				retv = retv && File.exist?(File.join(OWN_PATH, k.to_s + '.yaml'))
			end
			retv
		end
	end

	class Mod
		def self.create(name)
			self.new(name)
		end

		def initialize(name)
			@name = name
			@dirty_files = {
				:countries => {},
				:states => {},
			}
		end

		def select_country(id)
			@id = id.to_s.upcase
			@dirty_files[:countries] = Cache.country(id)
			@dirty_files[:states]    = Cache.states(id)
		end

		def annex(id)
			annex_states  = Cache.states(id).clone
			annex_states.each do |_,h|
				h['xp:state/history/owner'] = @id
			end
			@dirty_files[:states].merge!(annex_states)
		end

		def buff_country
			@dirty_files[:countries].each do |_,h|
				h[:set_research_slots] = 6
				h[:set_convoys] = 500
				h[:set_national_unity] = 0.9
			end
		end

		def buff_tech(opts = { :until => 1939 })
			xtechs = @dirty_files[:countries].first[1][:set_technology]

			Cache.tech.each do |_,tarr|
				ntechs = tarr.reduce([]) do |a,tech|
					if tech[1] <= opts[:until]
						a << [ tech[0], 1 ]
					else
						a
					end
				end.to_h
				xtechs.merge!(ntechs)
			end
		end

		def buff_states
			@dirty_files[:states].each do |_,h|
				h['xp:state/state_category'] = 'megalopolis'
				h['xp:state/manpower'] = h['xp:state/manpower']  * 100
				buildings = h['xp:state/history/buildings']
				buildings[:infrastructure] = 10
				buildings[:air_base] = 10
				buildings[:anti_air_building] = 5
				buildings[:industrial_complex] = 20
				buildings[:arms_factory] = 20
				buildings[:dockyard] = 10 if buildings[:dockyard]
				buildings[:dockyard] = 10 if h['xp:state/history/add_core_of'] == "GRE"
			end
			resources = @dirty_files[:states]['43-Hungary.txt'][:state][:resources]
			resources[:oil] = 1000
			resources[:aluminium] = 1000
			resources[:rubber] = 1000
			resources[:tungsten] = 1000
			resources[:steel] = 1000
			resources[:chromium] = 1000
			ap @dirty_files[:states]['43-Hungary.txt']
		end

		def buff
			select_country(:hun)
			annex(:yug)
			annex(:gre)
			annex(:alb)
			buff_states
			buff_country
			buff_tech :until => 1945
			save!
		end

		def save!
			mod_path = File.join(MOD_PATH, @name)
			puts "Saving to: #{mod_path}"
			FileUtils.mkdir_p(mod_path) unless Dir.exist?(mod_path)
			@dirty_files.each do |category, files|
				if category == :none
					fpath = mod_path
				else
					fpath = File.join(mod_path, PATHS[category])
					FileUtils.mkdir_p(fpath) unless Dir.exist?(fpath)
				end

				files.each do |fname, content|
					Paradoxical.print_file(content, File.join(fpath, fname))
				end
			end
		end
	end
end

if __FILE__ == $0
	m = Hoi4::Mod.create 'hungary'
	m.buff
end
