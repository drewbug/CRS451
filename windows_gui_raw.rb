require 'ffi'

module WindowsGUIRaw
  extend FFI::Library

  ffi_lib 'user32'
  ffi_convention :stdcall

  HWND = :long
  INT = :int
  UINT = :uint
  LPARAM = :pointer
  WPARAM = :ulong
  LRESULT = :long
  LPCTSTR = :pointer

  callback :enum_callback, [ :long, :long ], :bool

  attach_function :PostMessageA, [ HWND, UINT, WPARAM, LPARAM ], LRESULT
  attach_function :SendMessageA, [ HWND, UINT, WPARAM, LPARAM ], LRESULT
  attach_function :FindWindowA, [ LPCTSTR, LPCTSTR ], HWND
  attach_function :FindWindowExA, [ HWND, :pointer, LPCTSTR, LPCTSTR ], HWND
  attach_function :GetDlgItem, [ HWND, INT ], HWND
  attach_function :EnumDesktopWindows, [ :pointer, :enum_callback, :long ], :bool
  attach_function :GetWindowTextA, [ :long, :pointer, :int ], :int
end