package main

/*
	This is an example on how to take in basic input with Win32 API and display the text to the screen.
	Technically, this uses GDI to display the text so really it should be in the GDI Examples.

	This is built on top of the basic-input-singleline example but further adding multiline

	It does this by checking if the enter key is pressed, if so, 10 is appened (unicode for linefeed)

	Then when rendering the text, it checks if the letter is 10, if so, it gets the the height of the text
	using TEXTMETRICW and adds that to the font_pos[1]

	You can find more information about: GetTextMetricsW here: https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-gettextmetricsw
	You can find more information about: TEXTMETRICW here: https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-textmetricw
*/


// Core Imports
import "core:fmt"
import "core:time"
import "core:slice"
import "core:strings"
import win "core:sys/windows"

// Base Imports
import "base:runtime"



foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	GetCharWidth32W :: proc(hdc:win.HDC, iFirst:win.UINT, iLast:win.UINT, lpBuffer:^win.INT) -> win.BOOL ---
}

running := true
winsize:[2]i32 = {1080, 720}


letters:[dynamic]win.WORD
render_background:win.RECT

/*Windows Event procedure/callback/function --> Handles window events*/
window_event_proc :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	// Check which type of messages are coming into the application
	switch message {
	case win.WM_SIZE:
		win.OutputDebugStringW(win.L("WM_SIZE\n"))
	case win.WM_DESTROY:
		delete(letters)
		running = false
	case win.WM_CLOSE:
		running = false
	case win.WM_ACTIVATEAPP:
		win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
	case win.WM_CREATE:
		win.OutputDebugStringW(win.L("WM_CREATE\n"))

	// Grahics using win32 paint
	case win.WM_PAINT:
		// DRAW
		paint: win.PAINTSTRUCT
		device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)


		// Setting the background mode to Transparent prevents the text from having a white background
		win.SetBkMode(hdc = device_context, mode = .TRANSPARENT) // -> INT ---
		x := paint.rcPaint.left
		y := paint.rcPaint.top
		width := paint.rcPaint.right - paint.rcPaint.left
		height := paint.rcPaint.bottom - paint.rcPaint.top

		win.PatBlt(device_context, x, y, width, height, win.BLACKNESS)

		// win.Rectangle(hdc = device_context, left = 10, top = 10, right = 10, bottom = 10)
		brush:win.HBRUSH = win.CreateSolidBrush(win.RGB(r = 155, g = 155, b = 155)) // -> HBRUSH ---
		win.FillRect(hDC = device_context, lprc = &render_background, hbr = brush) //-> int ---

		font_pos:[2]i32 = {0, 0}	
		for letter in letters {
			buf:[1]u16 = {letter}

			width:win.INT
			
			GetCharWidth32W(
				hdc = device_context,
				iFirst = cast(win.UINT)letter,
				iLast = cast(win.UINT)letter,
				lpBuffer = &width
			) // -> win.BOOL ---


			if letter == 10 {
				text_metric:win.TEXTMETRICW
				win.GetTextMetricsW(
					hdc = device_context,
					lptm = &text_metric 
				)  //-> BOOL ---
		
				font_pos[0] = 0
				font_pos[1] += text_metric.tmHeight
				continue
			}

			win.TextOutW(
				hdc = device_context,
				x = font_pos[0],
				y = font_pos[1],
				lpString = cast(cstring16)raw_data(buf[:]),
				c = cast(i32)len(buf)
			)// -> BOOL ---

			font_pos[0] += width
		}

		win.EndPaint(hWnd = window, lpPaint = &paint)

	case win.WM_LBUTTONDOWN:
		x := cast(i32)win.LOWORD(lParam)
		y := cast(i32)win.HIWORD(lParam)
		
	// Key down press events
	case win.WM_KEYDOWN:
		switch (wParam) {
		case win.VK_ESCAPE:
			running = false
		}

	// If a character key (a-z, 0-9, etc) is pressed
	case win.WM_CHAR:
		switch (wParam) {
		case 13: // If enter is pressed
			append(&letters, 10)
		case 8:
			if len(letters) > 0{
				pop(&letters)
			}
			
			win.InvalidateRect(
				hWnd = window,
				lpRect = nil,
				bErase = win.TRUE
			)// -> BOOL ---
		case:
			key := win.GET_KEYSTATE_WPARAM(wParam = wParam)
			append(&letters, key)
			win.InvalidateRect(
				hWnd = window,
				lpRect = nil,
				bErase = win.TRUE
			)// -> BOOL ---
		}
	}

	return win.DefWindowProcW(window, message, wParam, lParam)
}

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Window Instance (nil)

	// Windows Class W (wide/unicode class varient)
	window_class := win.WNDCLASSW {
		style         = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc   = window_event_proc,
		hInstance     = instance,
		lpszClassName = win.L("TextEditClass"),
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the windows class 

	// Creating a window (ex w)
		// | win.SWP_NOMOVE | win.SWP_NOSIZE | win.SWP_NOACTIVATE | win.SWP_SHOWWINDOW,
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("TextEditExample"), // win.L is a c macro to convert string to Long
		dwStyle = win.WS_OVERLAPPED | win.WS_VISIBLE | win.WS_SYSMENU,
		X = 0,
		Y = 0,
		nWidth = winsize[0],
		nHeight = winsize[1],
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)

	render_background = {0, 0, winsize[0], winsize[1]}
	
	// Message loop
	message: win.MSG
	for running {
		if win.GetMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0, wMsgFilterMax = 0) >
		   0 {
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
	} // end of running loop
}
