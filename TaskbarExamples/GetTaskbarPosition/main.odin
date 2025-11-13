package main

import "core:fmt"
import win "core:sys/windows"

main :: proc() {

	class_name: win.wstring = win.L("Shell_TrayWnd") // Class Name for the Taskbar
	taskbar_handle: win.HWND = win.FindWindowW(lpClassName = class_name, lpWindowName = nil) // -> HWND ---

	// Get window info for the taskbar
	window_info: win.WINDOWINFO
	win.GetWindowInfo(hwnd = taskbar_handle, pwi = &window_info) // -> BOOL ---
	fmt.println(window_info)

}
