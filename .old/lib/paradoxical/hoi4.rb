$LOAD_PATH.unshift(*%w(. ..))
require 'paradoxical'
require 'date'
require 'ap'

require 'benchmark'

HOI4_PATH = "/home/zacsek/.steam/steam/steamapps/common/Hearts of Iron IV"

def load_country(id)
	id = id.upcase!
	country = Dir[HOI4_PATH + "/history/countries/#{id} - *"].first
	Paradoxical.parse(country)
end

def load_provinces_all
	provinces = {}
	bm = Benchmark.measure do
		Dir[HOI4_PATH + "/history/states/*"].each do |province|
			#print "Loading: "; puts File.basename(province)
			p = Paradoxical.parse(province)
			provinces[File.basename(province)] = p
		end
	end
	puts "Loaded in #{bm.total}"
	provinces
end

def get_country_provinces(id, provinces)
	filtered = provinces.select { |name,province| 
		province['state/history/owner'] == id.upcase
	}
end

provinces = load_provinces_all
ap get_country_provinces("HUN", provinces)
ap get_country_provinces("ROM", provinces)
#File.open("parsed.yaml", "w") do |f|
	#f.write load_provinces_all.to_yaml
#end



