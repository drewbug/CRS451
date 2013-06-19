require_relative 'windows_gui.rb'

require 'csv'

module CRS600Raw
  module_function

  def new_database(directory, filename)
    window = WindowsGUI.find_window 'New CRS60'

    directory_field = WindowsGUI.find_control window, 0x14BB
    WindowsGUI.set_text directory_field, directory

    filename_field = WindowsGUI.find_control window, 0x14B6
    WindowsGUI.set_text filename_field, filename

    WindowsGUI.press_button WindowsGUI.find_subwindow window, 'Create'

    sampleconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', 'A sample rate must be selected before we can continue.'
    WindowsGUI.press_button WindowsGUI.find_subwindow sampleconfirm_window, 'OK'

    samplerate_window = WindowsGUI.find_window 'Select Sample Rate'
    WindowsGUI.press_button WindowsGUI.find_subwindow samplerate_window, 'OK'

    importconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', "&Yes"
    WindowsGUI.press_button WindowsGUI.find_subwindow importconfirm_window, '&Yes'

    cardconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', 'A new card must be created to start CRS 600.'
    WindowsGUI.press_button WindowsGUI.find_subwindow cardconfirm_window, 'OK'
  end

  def new_card(name)
    window = WindowsGUI.find_window 'New Card'

    field = WindowsGUI.find_control window, 0xED
    WindowsGUI.set_text field, name
    
    WindowsGUI.press_button WindowsGUI.find_subwindow window, 'OK'
  end

  def new_route(name, number)
    window = WindowsGUI.find_window 'New Route'

    name_field = WindowsGUI.find_control window, 0x172
    WindowsGUI.set_text name_field, name

    number_field = WindowsGUI.find_control window, 0x173
    WindowsGUI.set_text number_field, number

    WindowsGUI.press_button WindowsGUI.find_subwindow window, 'OK'
  end

  def route_info(options = {})
    options = {name: nil, number: nil, b_number: '', ocu: nil, farebox: nil}.merge(options)

    window = WindowsGUI.find_window 'Route Information'

    if options[:name]
      name_field = WindowsGUI.find_control window, 0x16C
      WindowsGUI.set_text name_field, options[:name]
    end

    if options[:number]
      number_field = WindowsGUI.find_control window, 0x16D
      WindowsGUI.set_text number_field, options[:number]
    end

    if options[:b_number]
      b_number_field = WindowsGUI.find_control window, 0x16A
      WindowsGUI.set_text b_number_field, options[:b_number]
    end

    if options[:ocu]
      ocu_field = WindowsGUI.find_control window, 0x157
      WindowsGUI.set_text ocu_field, options[:ocu]
    end

    if options[:farebox]
      farebox_field = WindowsGUI.find_control window, 0x265
      WindowsGUI.set_text farebox_field, options[:farebox]
    end

    WindowsGUI.press_button WindowsGUI.find_subwindow window, 'OK'
  end
end

class CRS600
  ID_MAINMENU_DATA_NEW_ROUTE = 33031

  def initialize
    program_files = "#{ ENV['ProgramFiles(x86)'] || ENV['ProgramFiles'] }#{ '/DRI/CRS600' }"
    system "#{ 'start "" /D "'}#{ program_files }#{ '" "' }#{ program_files }#{ '/CRS600.exe"' }"

    @landing_window = WindowsGUI.find_window 'Open/New CRS 600'
  end

  def add_database(db_dir, db_prefix, card_name)
    raise "#{ db_dir + "/" + db_prefix + "Database" } Already Exists!" if File.directory? "#{ db_dir }/#{ db_prefix }Database"
    Dir.mkdir "#{ db_dir }/#{ db_prefix }Database"

    WindowsGUI.press_button WindowsGUI.find_subwindow @landing_window, 'New'
    CRS600Raw.new_database db_dir, "#{ db_prefix }Database.crs"
    CRS600Raw.new_card card_name

    @main_window = WindowsGUI.find_window " CRS 600 - #{db_dir}\\#{db_prefix}Database\\#{db_prefix}Database.crs"
  end

  def add_route(dsc, route_hash)
    WindowsGUI.menu_command @main_window, ID_MAINMENU_DATA_NEW_ROUTE

    CRS600Raw.new_route "Route #{route_hash[:short_name]} [#{route_hash[:direction]}] #{route_hash[:long_name]} (#{route_hash[:headsign]})", dsc
    CRS600Raw.route_info ocu: "#{route_hash[:short_name]}#{route_hash[:direction]} #{route_hash[:headsign]}"
  end
end

crs600 = CRS600.new

agency_gtfs = CSV.read('agency.txt', headers: true)
trips_gtfs = CSV.read('trips.txt', headers: true)
routes_gtfs = CSV.read('routes.txt', headers: true)

crs600.add_database "#{ ENV['HOME']+'/Desktop' }", agency_gtfs[0]['agency_id'], agency_gtfs[0]['agency_name']

routes = {}
CSV.foreach('tripstoDSC.txt', headers: true) do |row|
  trip_gtfs = trips_gtfs.find { |t| t['trip_id'] == row['trip'] }
  route_gtfs = routes_gtfs.find { |r| r['route_id'] == trip_gtfs['route_id'] }

  route_hash = { short_name: route_gtfs['route_short_name'],
            direction: case trip_gtfs['direction_id']; when '0'; "IB"; when '1'; "OB"; else nil; end,
            long_name: route_gtfs['route_long_name'],
            headsign: trip_gtfs['trip_headsign'] }

  if routes[row['DSC']].nil?
    routes[row['DSC']] = route_hash
  elsif routes[row['DSC']] != route_hash
    raise "DSC #{row['DSC']} assigned to more than one variant"
  end
end

routes.each { |dsc, route_hash| crs600.add_route(dsc, route_hash) }
