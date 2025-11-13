package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:time"
import "core:math/rand"


/*
	Borderless Window
	Sets up window, adjusts window, and draws a blank window that is borderless
*/


// Globals
running := true // Exiting main loop (which in turn leads to exiting application)

// window size
rect:win.RECT = {left = 0, top = 0, right = 600, bottom = 600}

device_context:win.HDC
memory_device_context:win.HDC
window:win.HWND

// Callback function for handling events
window_event_proc :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	switch message {
		case win.WM_SIZE:
			win.OutputDebugStringW(win.L("WM_SIZE\n"))
		case win.WM_DESTROY:
			running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:

		case win.WM_PAINT:
			// The event for painting to the window
			// There is flickering here; double buffering could have solved it but I couldn't figure that out.
			// Instead; I 'sleep' game_loop after every iteration and it stops the flickering (until the snake gets too big then it comes back)
			paint: win.PAINTSTRUCT
			hdc := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(hdc, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window; causing flickering but without it, painting does not work right


		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}

		case win.WM_CHAR:
			// The event for keyboard presses (like, w,a,s,d etc)
			switch(wParam) {
			}
		}
		
	return win.DefWindowProcW(window, message, wParam, lParam)
}

main :: proc() {

	// Window Creation Start
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance
	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("BorderlessWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	window = win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Borderless Window"),
		// dwStyle = win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE | win.WS_SYSMENU,
		dwStyle = win.WS_BORDER | win.WS_POPUP | win.WS_VISIBLE | win.WS_SYSMENU,
		X = win.CW_USEDEFAULT,
		Y = win.CW_USEDEFAULT,
		nWidth = rect.right - rect.left,
		nHeight = rect.bottom - rect.top,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)

	// message/event loop
	message:win.MSG
	for running {
		// Using PeekMessageW and not GetMessageW
		// Peak does not wait for a message to arrive if there is not one
		// Whereas GetMessageW does
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
	}
}
