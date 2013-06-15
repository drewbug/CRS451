require_relative 'windows_gui_raw.rb'

module WindowsGUI
  WM_GETTEXT = 0xD
  WM_SETTEXT = 0xC
  BM_CLICK = 0xF5

  module_function

  def find_window(name)
    window = WindowsGUIRaw.FindWindowA( nil, name ) until !window.nil? and window > 0
    return window
  end

  def find_subwindow(parent, name)
    subwindow = WindowsGUIRaw.FindWindowExA( parent, nil, nil, name ) until !subwindow.nil? and subwindow > 0
    return subwindow
  end

  def press_button(handle)
    WindowsGUIRaw.PostMessageA( handle, BM_CLICK, 0, nil )
  end

  def find_control(parent, id)
    control = WindowsGUIRaw.GetDlgItem( parent, id ) until !control.nil? and control > 0
    return control
  end

  def set_text(handle, text)
    WindowsGUIRaw.SendMessageA( handle, WM_SETTEXT, 0, text )
  end

  def find_window_with_subwindow(window_name, subwindow_name)
    name_pointer = FFI::MemoryPointer.new :char, 512
    loop do
      WindowsGUI.list_windows.each do |window|
        name_pointer.clear
        WindowsGUIRaw.GetWindowTextA(window, name_pointer, name_pointer.size)
        if name_pointer.get_string(0) == window_name
          subwindow = WindowsGUIRaw.FindWindowExA( window, nil, nil, subwindow_name )
          return window if subwindow > 0
        end
      end
    end
  end
  
  def list_windows
    windows = []
    enumWindowCallback = Proc.new do |wnd, param|
      windows << wnd
      true
    end
    WindowsGUIRaw.EnumDesktopWindows(nil, enumWindowCallback, 0)
    return windows
  end
end