package main


/*
	Basic Window
	============
	This example shows how to grab mouse data

	The mouse emits events through WM_MOUSE* events
	For example: Mouse position: WM_MOUSEMOVE, Wheel Direction: WM_MOUSEWHEEL

	Resources:
		Built on the basic window exmaple
*/

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"


// Globals
running := true // Exiting main loop (which in turn leads to exiting application)
// window size
rect:win.RECT = {left = 0, top = 0, right = 1280, bottom = 720}

// Callback function for handling events
window_event_proc :: proc "stdcall" (window: win.HWND, message: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) -> win.LRESULT {
	context = runtime.default_context()

	switch message {
		case win.WM_PAINT:
			// Very basic window painting to make the window black
			paint: win.PAINTSTRUCT
			hdc := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(hdc, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window; causing flickering but without it, painting does not work right

		case win.WM_DESTROY:
			running = false
		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}
		case win.WM_MOUSEMOVE:
			x := win.GET_X_LPARAM(lParam)
			y := win.GET_Y_LPARAM(lParam)

			// fmt.println("Move", x,y)
			
		case win.WM_MOUSEWHEEL:

			wheel := win.GET_WHEEL_DELTA_WPARAM(wParam)

			fmt.println("wheel", wheel)

		case win.WM_LBUTTONDOWN:
			fmt.println("Left Mouse pressed")
		case win.WM_RBUTTONDOWN:
			fmt.println("Right Mouse pressed")
		case win.WM_MBUTTONDOWN:
			fmt.println("Middle Mouse pressed")
		
		case win.WM_XBUTTONDOWN: // The two side buttons on some mice
			button := win.GET_KEYSTATE_WPARAM(wParam)
			fmt.println(button)
		
		
		}
		
	return win.DefWindowProcW(window, message, wParam, lParam)
}

main :: proc() {


	// Create a handle to the instance of the application - The thing the OS uses to ID the executable
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

	// Create the attributes that the window will use when it's registered
	window_class: win.WNDCLASSEXW = {
		cbSize = size_of(win.WNDCLASSEXW),
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc,
		cbClsExtra = 0,
		cbWndExtra = 0,
		hInstance = instance,
		hIcon = nil,
		hCursor = nil,
		hbrBackground = nil,
		lpszMenuName = nil,
		lpszClassName = win.L("Basic_Window_Class"),
		hIconSm = nil,
	}

	
	win.RegisterClassExW(&window_class)
	win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Basic Window"),
		dwStyle = win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE | win.WS_SYSMENU,
		X = win.CW_USEDEFAULT,
		Y = win.CW_USEDEFAULT,
		nWidth = rect.right - rect.left,
		nHeight = rect.bottom - rect.top,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)
	
	if window == nil {
		error := win.GetLastError()
		fmt.println(error)
	}

	win.ShowWindow(window,win.SW_SHOW)

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
