$LOAD_PATH.unshift(*%w(. .. ../..))

require 'paradoxical/paradoxical'
require 'awesome_print'
require 'date'
require 'yaml'
require 'fileutils'
require 'singleton'

require 'benchmark'

module Vic2
  GAME_PATH = File.join( Dir.home, '.PlayOnLinux/wineprefix/Steam/drive_c/Steam/steamapps/common/Victoria 2' )
  MOD_PATH  = File.join( Dir.home, '.PlayOnLinux/wineprefix/Steam/drive_c/Steam/steamapps/common/Victoria 2/mod' )
  OWN_PATH  = File.join( Dir.home, '.paradoxical/vic2' )

  PATHS = {
    :countries => 'history/countries',
    :states    => 'history/provinces',
    :pops      => 'history/pops/1836.1.1',
    :tech      => 'technologies',
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

    def self.[](id)
      self.instance.cache[id]
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
        if state[:add_core]
          state[:add_core].include? name
        #else
          #ap "No-core: #{state}"
        end
      end
    end

    def self.pop(id)
      name = @cache[:ipops][id]
      @cache[:pops][name][id]
    end

    def self.tech
      cache[:tech]
    end

    attr_accessor :cache

    def initialize
      @cache = {
        :id2name   => {},
        :countries => {},
        :states    => {},
        :pops      => {},
        :ipops     => {},
        :tech      => {},
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
        load_pops
        load_tech
        persist!
      end
    end

    def load_countries
      glob = File.join(GAME_PATHS[:countries], "*.txt")
      Dir[glob].each do |fname|
        name = File.basename(fname)
        puts "COUNTRIES loading file: #{name}"
        @cache[:countries][name] = Paradoxical.parse(fname)
      end
    end

    def load_states
      glob = File.join(GAME_PATHS[:states], "**/*.txt")
      Dir[glob].each do |fname|
        name = fname.gsub(GAME_PATHS[:states] + '/', '')
        puts "PROVINCES loading file: #{fname}"
        @cache[:states][name] = Paradoxical.parse(fname)
      end
      @cache[:states]
    end

    def load_pops
      glob = File.join(GAME_PATHS[:pops], "*.txt")
      Dir[glob].each do |fname|
        name = File.basename(fname)
        puts "POPS loading file: #{fname}"
        pop = @cache[:pops][name] = Paradoxical.parse(fname)
        pop.each do |id,_|
          @cache[:ipops][id] = name
        end
      end
      @cache[:pops]
    end

    def load_tech
      glob = File.join(GAME_PATHS[:tech], "*.txt")
      Dir[glob].each do |fname|
        puts "TECH loading file: #{fname}"
        techs = Paradoxical.parse(fname)
        techs.each do |tname, tdef|
          if tdef.is_a? Hash
            dir = tdef[:area] || :unknown
            yr  = tdef[:year]
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
        puts "ID2NAME loading file: #{name}"
        if name =~ /[A-Z]{3}/
          id = name[/[A-Z]{3}/].downcase.to_sym
          arr << [id, name]
        end
        arr
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
    GOODS ={ :cotton         => 0,
             :dye            => 0,
             :wool           => 0,
             :silk           => 0,
             :coal           => 5,
             :sulphur        => 0,
             :iron           => 5,
             :timber         => 0,
             :tropical_wood  => 0,
             :rubber         => 0,
             :oil            => 5,
             :precious_metal => 0,
             :cattle         => 5,
             :fish           => 5,
             :fruit          => 5,
             :grain          => 10,
             :tobacco        => 0,
             :tea            => 0,
             :coffee         => 0,
             :opium          => 0,  }

    POPS = { :aristocrats => 6,
             :artisans    => 10,
             :bureaucrats => 3,
             :capitalists => 3,
             :clergymen   => 4,
             :clerks      => 4,
             :craftsmen   => 20,
             :farmers     => 20,
             :labourers   => 20,
             :officers    => 3,
             :slaves      => -1,
             :soldiers    => 7 }


    def self.create(name, &block)
      ctxt = self.new(name)
      ctxt.instance_exec do
        block.call(self)
      end
      ctxt
    end

    attr_accessor :name, :dirty_files

    def initialize(name)
      @name = name
      @dirty_files = {
        :countries => {},
        :states    => {},
        :pops      => {},
        #:units     => {},
      }
    end

    def select_country(id)
      @id = id.to_s.upcase
      @dirty_files[:countries] = Cache.country(id).clone
      @dirty_files[:states]    = Cache.states(id).clone
      load_pops_2_dirty
    end

    def load_pops_2_dirty
      @dirty_files[:states].each do |name,_|
        id = state2id(name)
        key = Cache[:ipops][id].clone
        val = Cache[:pops][key].clone
        @dirty_files[:pops][key] = val
      end
      @dirty_files[:pops]
    end

    def state2id(province)
      province[/[^\/]+\/(\d{3,4})/, 1].to_sym
    end

    def country
      @dirty_files[:countries].first[1]
    end

    def annex(id)
      annex_states  = Cache.states(id).clone
      annex_states.each do |_,h|
        h[:owner] = @id
        h[:controller] = @id
      end
      @dirty_files[:states].merge!(annex_states)
    end

    def buff_literacy(amount)
      country[:literacy] = amount
      country[:non_state_culture_literacy] = amount
    end

    def buff_life_rating(amount)
      @dirty_files[:states].each do |_,h|
        h[:life_rating] = amount
      end
    end

    def randomize_goods
      goods_assigned = GOODS.clone.map {|k,v| [k,0]}.to_h
      lngth = goods_assigned.length

      goods = GOODS.keys.map(&:to_s).shuffle
      @dirty_files[:states].each do |_,h|
        g = goods.shift
        if goods.empty?
          goods = GOODS.keys.map(&:to_s).shuffle
        end
        gs = g.to_sym
        if goods_assigned[gs] > 0 && GOODS[gs] == 0
          g = goods.shift
          if goods.empty?
            goods = GOODS.keys.map(&:to_s).shuffle
          end
          gs = g.to_sym
        end
        h[:trade_goods] = g
        goods_assigned[gs] += 1
      end
    end

    def state_ids
      ids = []
      @dirty_files[:states].each do |name,_|
        ids << state2id(name)
      end
      ids
    end

    def pop_assimilate(grow = 1.0)
      primary = country[:primary_culture]
      ids = state_ids

      @dirty_files[:pops].each do |_,provinces|
        provinces.each do |id, pops|
          if ids.include?(id)
            pops.each do |pop,cultures|
              #print "Before: #{pop} -> ";ap pops[pop]
              cultures = [cultures] unless cultures.is_a? Array
              sum = cultures.reduce(0) do |sum,culture|
                if culture != :multi
                  sum += culture[:size]
                end
                sum
              end
              sum = (sum * grow).to_i
              pops[pop] = { :culture => primary, :religion => country[:religion], :size => sum }
              #print "After: #{pop} -> ";ap pops[pop]
            end
          end
        end
      end
    end

    def pop_rebalance
      primary = country[:primary_culture]
      religion= country[:religion]

      ids = state_ids
      @dirty_files[:pops].each do |_,provinces|
        provinces.each do |id,pops|
          if ids.include?(id)
            total = pops.reduce(0) do |s,pop|
              s += pop[1][:size]
            end
            provinces[id] = POPS.map do |pop,percent|
              if percent != -1
                nsize = percent.to_f * total / 100
                [ pop, { :culture => primary, :religion => religion, :size => nsize } ]
              end
            end.compact.to_h
          end
        end
      end
    end

    def buff_tech(opts = { :until => 1836 })
      Cache.tech.each do |_,tarr|
        ntechs = tarr.reduce([]) do |a,tech|
          if tech[1] <= opts[:until]
            a << [ tech[0], 1 ]
          else
            a
          end
        end.to_h
        country.merge!(ntechs)
      end
    end

    def description
      info = <<-HERE.gsub(/^\s*/,'')
        name="#{@name}"
        path="mod/#{@name}"
        tags={ "Alternative history" }
      HERE
      fname = File.open(File.join(MOD_PATH, "#{@name}.mod"), 'w') do |f|
        f.write(info)
      end
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
        description()

        files.each do |fname, content|
          name = File.join(fpath, fname)
          dirname = File.dirname(name)
          FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)

          Paradoxical.print_file(content, name)
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'ap'
  require 'pry'
  Vic2::Cache.instance
  h = Vic2::Mod.new 'hun'
  h.select_country :hun
  h.pop_assimilate(10)

  #ap h.state_ids
  #ap h.dirty_files[:pops]
  #binding.pry
  puts "End"
end
