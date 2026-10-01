package main

/*
	Basic Single Line Text
	======================

	This uses GDI to display text to the screen.
	This does not sit in the GDI Examples folder as text/font rendering can get very complicated.
	It was best to put it in its own folder at root level to avoid nesting too may folders in one another.

	As with everything else in this repo; this is just a basic way of rendering text.

	What this example does:
		- Takes input typed on keyboard and displays it to the screen.
		- Uses a dynamic array to store characters used for rendering and editing
		- Uses backspace to delete characters -- popping the last character in the array.
		- Displays white text on a black background -- involves changing the color

	From what I can tell, GetCharWidth32W does not exist in the Odin bindings and needs to be added manually

	We need this to properly space out the text when displaying it. Otherwise one of two things happen:
		A) All the text renders on top of each other
		B) We manually supply a value for the spacing which can cause issues if not done correctly

	There is also: GetCharABCWidthsW
	This binding also does not exist in odin so it would need to be created, along with the ABC Struct that it needs as an argument.
	This turned out to be more complicated than what I was trying to do, and as such, I didn't go with this approach.

	-----

	DrawTextW -> Odin does have these bindings. And it does have its usecases for drawing text withing a bounds (rectangle)
	However, TextOutW (and ExTextOutW) gives finer control of text at the cost of complexity.
	
	These examples use TextOutW as at the time this example was written, I was still reasonably unfamiliar with Odin and Win32
	and couldn't figure out how to use DrawTextW, but somehow figured out TextOutW.

	Resources:
		https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-textoutw?redirectedfrom=MSDN
		https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getcharwidth32w
		https://stackoverflow.com/questions/3612024/hbrush-to-rgb-value
		https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getobject		

*/


// Core Imports
import "core:fmt"
import win "core:sys/windows"

// Base Imports
import "base:runtime"


foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	GetCharWidth32W :: proc(hdc:win.HDC, iFirst:win.UINT, iLast:win.UINT, lpBuffer:^win.INT) -> win.BOOL ---
}

running := true
rect:win.RECT = {left = 0, top = 0, right = 1280, bottom = 720}

letters:[dynamic]win.WORD
render_background:win.RECT

/*Windows Event procedure/callback/function --> Handles window events*/
window_event_proc :: proc "stdcall" (window: win.HWND, message: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) -> win.LRESULT {
	context = runtime.default_context()

	// Check which type of messages are coming into the application
	switch message {
	case win.WM_DESTROY:
		delete(letters)
		running = false
	case win.WM_CLOSE:
		running = false

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

		color := win.RGB(255, 255, 255)
		result := win.SetTextColor(device_context, color)

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
		case 8:
			if len(letters) > 0{
				pop(&letters)
			}

			// Invalidating a Rectangle (the window) for redrawing it
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
		lpszClassName = win.L("Single_Line_Window_Class"),
		hIconSm = nil,
	}

	win.RegisterClassExW(&window_class)
	win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Single Line Text Window"),
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
	
	// Message loop
	message: win.MSG
	for running {
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
	} // end of running loop
}
