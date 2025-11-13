
package maing

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"


/*
	Moving a rectangle:
	This file shows how to move a GDI created rectangle; specifically a gradient rectangle;
	as such this is built on top of the Gradient Rectangle file

	Changes to this file:
	move_x, move_y global values to update the gradient rectangle's position
	This redraw function:
		RedrawWindow :: proc(hwnd: HWND, lprcUpdate: LPRECT, hrgnUpdate: HRGN, flags: RedrawWindowFlags) -> BOOL ---
	This is places at the end of each key event. It will for the screen to repaint after we press a key (wasd specifically)
*/


// Globals
running := true // Exiting main loop (which in turn leads to exiting application)

// Movements based on keypress
move_x:i32
move_y:i32

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

			gRect:win.GRADIENT_RECT = {
				UpperLeft = 0,
				LowerRight = 1,
			}


			// Vertices for the rectangle -- The points that make up the triange -- only need upper left and lower right
			// For moving the rectangle, added variables to the x and y positions to adjust accordingly
			vertex: [2]win.TRIVERTEX = {
				{move_x, move_y, 0xff00, 0x8000, 0x0000, 0x0000},
				{150 + move_x, 150 + move_y, 0x9000, 0x0000, 0x9000, 0x0000},
			}

			win.GdiGradientFill(
			hdc = device_context,
			pVertex = raw_data(&vertex),
			nVertex = 2,
			pMesh = &gRect,
			nCount = 1,
			ulMode = win.GRADIENT_FILL_RECT_H
			)

			win.EndPaint(hWnd = window, lpPaint = &paint)


		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}

		case win.WM_CHAR:
			// The event for k presses (like, w,a,s,d etc)
			switch(wParam) {
				case:
					key := win.GET_KEYSTATE_WPARAM(wParam = wParam)
					fmt.println(rune(key))

					// Could be switch/case statements but chose if because why not
					if key == 'w'{
						move_y -= 1
						fmt.println(move_y)

						result := win.RedrawWindow(
						hwnd = window,
						lprcUpdate = nil,
						hrgnUpdate = nil,
						flags = .RDW_UPDATENOW | .RDW_INVALIDATE // invalidate lets window be redrawn and updatenow forces window to update/redraw
						)

						if result {
							fmt.println("Redrawn Successully")
						} else {
							fmt.println("Redrawn Failed")
						}

						
					}
					else if key == 's'{
						move_y += 1
						fmt.println(move_y)


						result := win.RedrawWindow(
						hwnd = window,
						lprcUpdate = nil,
						hrgnUpdate = nil,
						flags = .RDW_UPDATENOW | .RDW_INVALIDATE // invalidate lets window be redrawn and updatenow forces window to update/redraw
						)

						if result {
							fmt.println("Redrawn Successully")
						} else {
							fmt.println("Redrawn Failed")
						}

						
					}
					else if key == 'a'{
						move_x -= 1
						fmt.println(move_x)

						
						result := win.RedrawWindow(
						hwnd = window,
						lprcUpdate = nil,
						hrgnUpdate = nil,
						flags = .RDW_UPDATENOW | .RDW_INVALIDATE // invalidate lets window be redrawn and updatenow forces window to update/redraw
 						)

						if result {
							fmt.println("Redrawn Successully")
						} else {
							fmt.println("Redrawn Failed")
						}

					}
					else if key == 'd'{
						move_x += 1
						fmt.println(move_x)
						
						result := win.RedrawWindow(
						hwnd = window,
						lprcUpdate = nil,
						hrgnUpdate = nil,
						flags = .RDW_UPDATENOW | .RDW_INVALIDATE // invalidate lets window be redrawn and updatenow forces window to update/redraw
						)

						if result {
							fmt.println("Redrawn Successully")
						} else {
							fmt.println("Redrawn Failed")
						}

					}
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
		lpszClassName = win.L("RectangleleWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Rectangle"),
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
