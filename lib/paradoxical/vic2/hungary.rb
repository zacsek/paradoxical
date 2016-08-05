require_relative 'vic2'
require 'fileutils'

def get_army
  army = <<-HERE
  army = {
    name = "I. Hadsereg"
    location = 641
    regiment = {
      name= "1.1. Kavalleriedivision"
      type = cuirassier
      home = 619
    }

    regiment = {
      name= "2.1. Kavalleriedivision"
      type = cuirassier
      home = 639
    }

    regiment = {
      name= "3.1. Kavalleriedivision"
      type = cuirassier
      home = 631
    }

    regiment = {
      name= "2.2. Infanteriedivision"
      type = infantry
      home = 729
    }

    regiment = {
      name= "3.2. Infanteriedivision"
      type = infantry
      home = 771
    }

    regiment = {
      name= "1.3. Infanteriedivision"
      type = infantry
      home = 618
    }

    regiment = {
      name= "2.3. Infanteriedivision"
      type = infantry
      home = 773
    }

    regiment = {
      name= "3.3. Infanteriedivision"
      type = artillery
      home = 728
    }
  }

  army = {
    name = "II. Armee"
    location = 702
    regiment = {
      name= "1.6. Infanteriedivision"
      type = infantry
      home = 627
    }

    regiment = {
      name= "2.6. Infanteriedivision"
      type = infantry
      home = 640
    }

    regiment = {
      name= "3.6. Infanteriedivision"
      type = infantry
      home = 705
    }

    regiment = {
      name= "1.7. Infanteriedivision"
      type = infantry
      home = 630
    }

    regiment = {
      name= "2.7. Infanteriedivision"
      type = infantry
      home = 643
    }

    regiment = {
      name= "3.7. Infanteriedivision"
      type = infantry
      home = 702
    }

  }

  army = {
    name = "III. Armee"
    location = 619
    regiment = {
      name= "1.8. Infanteriedivision"
      type = infantry
      home = 628
    }

    regiment = {
      name= "2.8. Infanteriedivision"
      type = infantry
      home = 642
    }

    regiment = {
      name= "3.8. Infanteriedivision"
      type = infantry
      home = 768
    }

    regiment = {
      name= "1.9. Infanteriedivision"
      type = infantry
      home = 624
    }

    regiment = {
      name= "2.9. Infanteriedivision"
      type = infantry
      home = 649
    }

    regiment = {
      name= "3.9. Infanteriedivision"
      type = infantry
      home = 633
    }

  }

  army = {
    name = "IV. Armee"
    location = 729
    regiment = {
      name= "1.4. Infanteriedivision"
      type = infantry
      home = 612
    }

    regiment = {
      name= "2.4. Infanteriedivision"
      type = infantry
      home = 629
    }

    regiment = {
      name= "3.4. Infanteriedivision"
      type = infantry
      home = 726
    }

    regiment = {
      name= "1.5. Infanteriedivision"
      type = infantry
      home = 614
    }

    regiment = {
      name= "2.5. Infanteriedivision"
      type = infantry
      home = 648
    }

    regiment = {
      name= "3.5. Infanteriedivision"
      type = infantry
      home = 714
    }
  }

  army = {
    name = "V. Armee"
    location = 641
    regiment = {
      name= "1.2. Kavalleriedivision"
      type = cuirassier
      home = 622
    }

    regiment = {
      name= "2.2. Kavalleriedivision"
      type = cuirassier
      home = 641
    }

    regiment = {
      name= "3.2. Kavalleriedivision"
      type = cuirassier
      home = 626
    }

    regiment = {
      name= "1.1. Infanteriedivision"
      type = infantry
      home = 613
    }

    regiment = {
      name= "2.1. Infanteriedivision"
      type = infantry
      home = 644
    }

    regiment = {
      name= "3.1. Infanteriedivision"
      type = infantry
      home = 625
    }

    regiment = {
      name= "1.2. Infanteriedivision"
      type = infantry
      home = 616
    }
  }
  HERE
  Paradoxical.parse_text(army)
end

Vic2::Mod.create("hungary") do |this|
  this.select_country(:hun)
  this.dirty_files[:states].each do |_,h|
    h[:controller] = h[:owner] = "HUN"
    h[:railroad] = 3
  end
  this.buff_literacy(95)
  this.buff_life_rating(75)
  this.randomize_goods
  this.pop_assimilate(5)
  this.pop_rebalance
  this.buff_tech(:until => 1950)

  this.country[:oob] = "\"HUN_oob.txt\""

  army = get_army.tap do |armies|
    ids = this.state_ids.map {|id| id.to_s.to_i }
    armies[:army].each do |a|
      next if a == :multi
      a[:location] = ids[rand(ids.length)]
      a[:regiment].each do |r|
        if r != :multi
          r[:home] = ids[rand(ids.length)]
        end
      end
    end
  end

  this.save!

  army_location = File.join(Vic2::MOD_PATH, this.name, "history/units/HUN_oob.txt")
  FileUtils.mkdir_p(File.dirname(army_location))
  Paradoxical.print_file(army, army_location)
end

