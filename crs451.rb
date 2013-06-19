require 'csv'
require_relative 'windows_gui.rb'

class CRS600
  def initialize(*args)
    @agency_id, @agency_name, @routes = args
    @database_dir = "#{ ENV['HOME']+'/Desktop' }"

    program_files = "#{ ENV['ProgramFiles(x86)'] || ENV['ProgramFiles'] }#{ '/DRI/CRS600' }"

    raise "#{ @database_dir+"/"+@agency_id+"Database" } Already Exists!" if File.directory? "#{ @database_dir }/#{ @agency_id }Database"

    Dir.mkdir "#{ @database_dir }/#{ @agency_id }Database"

    system "#{ 'start "" /D "'}#{ program_files }#{ '" "' }#{ program_files }#{ '/CRS600.exe"' }"
  end

  def landing(action)
    window = WindowsGUI.find_window 'Open/New CRS 600'

    case action
    when :new_database
      WindowsGUI.press_button WindowsGUI.find_subwindow window, 'New'

      new_database
    end
  end

  def new_database
    new_window = WindowsGUI.find_window 'New CRS60'

    directory_field = WindowsGUI.find_control new_window, 0x14BB
    WindowsGUI.set_text directory_field, @database_dir

    filename_field = WindowsGUI.find_control new_window, 0x14B6
    WindowsGUI.set_text filename_field, "#{ @agency_id }Database.crs"

    WindowsGUI.press_button WindowsGUI.find_subwindow new_window, 'Create'

    sampleconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', 'A sample rate must be selected before we can continue.'
    WindowsGUI.press_button WindowsGUI.find_subwindow sampleconfirm_window, 'OK'

    samplerate_window = WindowsGUI.find_window 'Select Sample Rate'
    WindowsGUI.press_button WindowsGUI.find_subwindow samplerate_window, 'OK'

    importconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', "&Yes"
    WindowsGUI.press_button WindowsGUI.find_subwindow importconfirm_window, '&Yes'

    cardconfirm_window = WindowsGUI.find_window_with_subwindow 'CRS 600', 'A new card must be created to start CRS 600.'
    WindowsGUI.press_button WindowsGUI.find_subwindow cardconfirm_window, 'OK'

    new_card
  end

  def new_card
    new_window = WindowsGUI.find_window 'New Card'

    card_field = WindowsGUI.find_control new_window, 0xED
    WindowsGUI.set_text card_field, @agency_name
    
    WindowsGUI.press_button WindowsGUI.find_subwindow new_window, 'OK'
  end
end

trips_gtfs = CSV.open('trips.txt', headers: true)
routes_gtfs = CSV.open('routes.txt', headers: true)

routes = {}
CSV.foreach('tripstoDSC.txt', headers: true) do |row|
  trip_gtfs = trips_gtfs.find { |t| t['trip_id'] == row['trip'] }
  route_gtfs = routes_gtfs.find { |r| r['route_id'] == trip_gtfs['route_id'] }

  route = [route_gtfs['route_short_name'], route_gtfs['route_long_name'], trip_gtfs['trip_headsign']]
  
  if routes[row['DSC']].nil?
    routes[row['DSC']] = route
  elsif routes[row['DSC']] != route
    raise "DSC #{row['DSC']} assigned to more than one variant"
  end
end

agency_id = CSV.new(File.open('agency.txt'), headers: true).readline['agency_id']
agency_name = CSV.new(File.open('agency.txt'), headers: true).readline['agency_name']

crs600 = CRS600.new agency_id, agency_name, routes

crs600.landing :new_database