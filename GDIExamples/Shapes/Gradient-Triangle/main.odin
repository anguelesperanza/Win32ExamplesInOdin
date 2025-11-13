package maing

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"



// Globals
running := true

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
			win.OutputDebugStringW(win.L("WM_CREATE\n"))
		case win.WM_PAINT:
			// The event for painting to the window
			paint: win.PAINTSTRUCT
			device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(device_context, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window

			// Vertices for the triangle -- The points that make up the triange
			vertex: [3]win.TRIVERTEX = {
				{150, 0, 0xff00, 0x8000, 0x0000, 0x0000},
				{0, 150, 0x9000, 0x0000, 0x9000, 0x0000},
				{300, 150, 0x9000, 0x0000, 0x9000, 0x0000},
			}

			gTriangle:win.GRADIENT_TRIANGLE = {
				Vertex1 = 0,
				Vertex2 = 1,
				Vertex3 = 2,
			}
			
			win.GdiGradientFill(
				hdc = device_context,
				pVertex = raw_data(&vertex),
				nVertex = 3,
				pMesh = &gTriangle,
				nCount = 1,
				ulMode = win.GRADIENT_FILL_TRIANGLE,
			) // Draw triangle


			
			win.EndPaint(hWnd = window, lpPaint = &paint)
		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}
	}

	return win.DefWindowProcW(window, message, wParam, lParam)
}


main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("TriangleWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Triangle"),
		dwStyle = win.WS_OVERLAPPED | win.WS_VISIBLE | win.WS_SYSMENU,
		X = 0,
		Y = 0,
		nWidth = 640,
		nHeight = 480,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)

	// message/event loop
	message:win.MSG
	for running {
		if win.GetMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0, wMsgFilterMax = 0) > 0 {
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
		
	}
}
