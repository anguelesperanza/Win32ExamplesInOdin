package main

/*
	Get Taskbar Position
	====================

	This gets the poistion of the task bar through a WINDOWINFO struct
	
	Resoruces:
		https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowinfo
		https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindoww
*/


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
