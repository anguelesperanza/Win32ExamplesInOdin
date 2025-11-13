
package maing

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"

import stbi "vendor:stb/image"

// Globals
running := true
hBitmap:win.HBITMAP


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
			// Upon window creation, load the bitmap image


			// IMPORTANT NOTE: If loading a .bmp file and hBItmap is still nil / 0x0 but win.GetLastError() returns 0
			// Open .bmp in paint and save as a 24 color bmp. Sometimes. the .bmp image was created using a compression algorithm
			// that win.LoadImageW(...) doesn't support.			
			hBitmap = cast(win.HBITMAP)win.LoadImageW(
				hInst = nil,
				name = win.L("mlg.bmp"),
				type = win.IMAGE_BITMAP,
				cx = 0,
				cy = 0,
				fuLoad = win.LR_LOADFROMFILE | win.LR_CREATEDIBSECTION
			)

			// If the image could not be loaded, then print out the last error
			// That error can be checked here under System Error Codes: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
			if hBitmap == nil {
				fmt.println("Could not create bitmap")
				fmt.println(hBitmap)
				fmt.println(win.GetLastError())
			}
			
		case win.WM_PAINT:
			// The event for painting to the window
			paint: win.PAINTSTRUCT
			device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(device_context, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window

			hdc_memory := win.CreateCompatibleDC(hdc = device_context)

			hOldBitmap:win.HBITMAP = cast(win.HBITMAP)win.SelectObject(hdc = hdc_memory, h = cast(win.HGDIOBJ)hBitmap)
			bm:win.BITMAP

			win.GetObjectW(h = cast(win.HANDLE)hBitmap, c = size_of(win.BITMAP), pv = &bm)

			// Instead of using BitBlt, use StretchBlt and define the wDest and hDest to be the resize target
			win.StretchBlt(
				hdcDest = device_context,
				xDest = 0,
				yDest = 0,
				wDest = 640,
				hDest = 480,
				hdcSrc = hdc_memory,
				xSrc = 0,
				ySrc = 0,
				wSrc = bm.bmWidth,
				hSrc = bm.bmHeight,
				rop = win.SRCCOPY,
			)

			win.SelectObject(hdc = hdc_memory, h = cast(win.HGDIOBJ)hOldBitmap)
			win.DeleteDC(hdc = hdc_memory)
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
		lpfnWndProc = window_event_proc,
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
