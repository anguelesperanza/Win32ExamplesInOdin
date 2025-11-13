package main


/*

Update: 9/10/2025 -- Updated to use the new cstring16 datatype in odin

This file gets the executable names of open windows
It does this by using the QueryFullProcessImageNameW procedure.


This does not exist in the odin binings for win32 at the moment (or at least I could not find them)
so I created the binding myself -- lines 21 - 26

*/


import "core:fmt"
import "core:strings"
import win "core:sys/windows"

import "base:runtime"

foreign import user32 "system:User32.lib"
@(default_calling_convention="system")

foreign user32 {
	QueryFullProcessImageNameW :: proc(hProcess:win.HANDLE, dwFlags:win.DWORD, lpExeName:win.LPWSTR, lpdwSize:win.PDWORD) -> win.BOOL ---
}

MAX_SIZE :: 32768 // Used for getting the executable path of a process. This is the max size that path can be.

Window_Enum_Proc :: proc "stdcall" (window_handle: win.HWND,window_enum_param: win.LPARAM) -> win.BOOL {
	/*This will enumerate through all the windows that are on the screen, being shown on the screen*/
	context = runtime.default_context()

	length := win.GetWindowTextLengthW(window_handle)
	if length > 0 && win.IsWindowVisible(window_handle) {


		// Check if a window is cloaked -- A second type of way a window can be hidden - different from visible attribuate
		// But for a more modern windows: https://devblogs.microsoft.com/oldnewthing/20200302-00/?p=103507
		// The blog post above explains why cloaking exists
		is_cloaked: win.BOOL = win.FALSE
		// paramenter 3 -> is 14 witch is DWMA_CLOAKED enum value (dwmapi.odin)
		handle_result: win.HRESULT = win.DwmGetWindowAttribute(
			window_handle,
			14,
			&is_cloaked,
			size_of(is_cloaked),
		)

		if !is_cloaked {
			// buffer := make([]win.WCHAR, length)
			// defer delete(buffer)
			 // = &buffer[0]

			result: win.wstring
			
			process_id:win.DWORD
			window_thread_result:win.DWORD = win.GetWindowThreadProcessId(hwnd = window_handle, lpdwProcessId = &process_id) // -> DWORD ---
			process_handle:win.HANDLE = win.OpenProcess(dwDesiredAccess = win.PROCESS_QUERY_LIMITED_INFORMATION , bInheritHandle = false, dwProcessId = process_id)// -> HANDLE ---
		
			exe_path:[MAX_SIZE]u16 // 32768 is the max size a path can be in windows
			exe_size:win.DWORD = MAX_SIZE
			
			if QueryFullProcessImageNameW(hProcess = process_handle,dwFlags = 0,lpExeName = &exe_path[0],lpdwSize = &exe_size) {
				// buf:[]u8
				// process_name:string = win.utf16_to_utf8_buf(buf = buf, s = exe_path[:])
				process_name, err := win.utf16_to_utf8_alloc(s = exe_path[:])

				if err != .None {
					panic("Cannot finish querying open windows")
				}

				// Since already converted utf16 to string, just going to do operations on that
				// instead of using win.PathFindFileNameW
				last_index := strings.last_index(s = process_name, substr = "\\")
				// fmt.println(last_index)
				exe_name := process_name[last_index + 1:len(process_name)]
				fmt.println(exe_name)
				
				
			}// -> win.BOOL ---
		}

	}
	return win.TRUE
}

main :: proc() {
	fmt.println("Hello World!")

	l_param:win.LPARAM
	win.EnumWindows(lpEnumFunc = Window_Enum_Proc, lParam = l_param)// -> BOOL ---
}
