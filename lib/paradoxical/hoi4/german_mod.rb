require_relative 'hoi4'

def buff_states(this)
  this.dirty_files[:states].each do |_,h|
    h['xp:state/state_category'] = 'megalopolis'
    h['xp:state/manpower'] = h['xp:state/manpower']  * 10
    buildings = h['xp:state/history/buildings']
    buildings[:rocket_site] = 3
    buildings[:nuclear_reactor] = 1
    buildings[:infrastructure] = 10
    buildings[:air_base] = 10
    buildings[:anti_air_building] = 5
    buildings[:radar_station] = 6
    buildings[:arms_factory] = 15
    buildings[:industrial_complex] = 15
    buildings[:dockyard] = 10 if buildings[:dockyard]
  end
  resources = this.dirty_files[:states]['64-Brandenburg.txt'][:state][:resources]
  resources = this.dirty_files[:states]['64-Brandenburg.txt'][:state][:resources] = {} if resources == nil
  resources[:oil] = 2000
  resources[:aluminium] = 2000
  resources[:rubber] = 2000
  resources[:tungsten] = 2000
  resources[:steel] = 2000
  resources[:chromium] = 2000
  ap this.dirty_files[:states]['64-Brandenburg.txt']
end

def buff_country(this)
  this.dirty_files[:countries].each do |_,h|
    h[:set_research_slots] = 6
    h[:set_convoys] = 500
    h[:set_national_unity] = 0.9
  end
end

Hoi4::Mod.create 'germany' do |this|
  this.select_country(:ger)
  #annex(:yug)
  #annex(:gre)
  #annex(:alb)
  buff_states(this)
  buff_country(this)
  this.buff_tech :until => 1950
  this.save!
end

