package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"


/*
    Back Buffer BMP:
    ================
    This shows how to do a back buffer (load frame into an memory off buffer screen and move it to the onscreen buffer)
    In this also includes an empty update proc that runs at a fixed 60 fps. 
    
    For the sake of the back buffer, those aren't needed. In fact they aren't really being used. But this is a template I may 
    use later on so I've left it in as to not redo that logic
    
    To use other image formats intead of .bmp, please refer to LoadImage* examples in this repository and apply those here.
    BMP was chosen as the example as it required the least work to setup given that .bmp is a windows format and supported by GDI.
*/

// Globals
running := true // Exiting main loop (which in turn leads to exiting application)
win_rect:win.RECT = {left = 0, top = 0, right = 1080, bottom = 720} // Window borders
loaded_image:win.HBITMAP

Timestamp :: struct {
	fixed_timestamp:f64,
	accumulator:f64,
	deltatime:f64,
	current_time:win.LARGE_INTEGER,
	last_time: win.LARGE_INTEGER,
	frequency: win.LARGE_INTEGER,
	counter: win.LARGE_INTEGER,
}
timestamp:Timestamp

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
			// When the window is destroyed

			running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:
			/*On window creation*/


		case win.WM_PAINT:
			// The event for painting to the window
			paint: win.PAINTSTRUCT
			device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			// Rendering an Image:
			// First: Create a Compatable DC Image (a device context that lives only in memory)
			mem_dc:win.HDC = win.CreateCompatibleDC(hdc = device_context)
			
			// Second: Select that bitmap into the compatible dc
			old_bitmap:win.HBITMAP = cast(win.HBITMAP)win.SelectObject(hdc = mem_dc , h = cast(win.HGDIOBJ)loaded_image) //-> HGDIOBJ ---
						
			// Third: Get Bitmap Dimensions
			buf:win.BITMAP
			image_data := win.GetObjectW(h = cast(win.HANDLE)loaded_image, c = size_of(win.BITMAP), pv = &buf)// -> int ---
			fmt.println(buf.bmWidth)
			
			win.BitBlt(hdc = device_context, x = 0, y = 0, cx = buf.bmWidth, cy = buf.bmHeight, hdcSrc = mem_dc, x1 = 0, y1 = 0, rop = win.SRCCOPY) // -> BOOL ---
			
			// Fourth: Clean up
			win.SelectObject(hdc = mem_dc , h = cast(win.HGDIOBJ)old_bitmap) //-> HGDIOBJ ---
			win.DeleteDC(hdc = mem_dc)

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
					switch key {
						case ' ': // Spacebar was pressed
						fmt.println("Space was pressed")
					}
			}
	}

	return win.DefWindowProcW(window, message, wParam, lParam)
}

get_current_time :: proc() -> win.LARGE_INTEGER{
	/*In C, a LARGE_INTEGER is a struct, In Odin, it's a c_longlong --> an f64*/
	win.QueryPerformanceFrequency(lpFrequency = &timestamp.frequency)
	win.QueryPerformanceCounter(lpPerformanceCount = &timestamp.counter)
	current_time := timestamp.counter / timestamp.frequency
	return current_time
}

load_bitmap_image :: proc(filename:string) -> win.HBITMAP {
    
    name:win.wstring = win.utf8_to_wstring(s = filename, allocator = context.temp_allocator)// -> wstring 
    // HANDLE ( or win.HANDLE ) is just a rawptr so it can be type cast into what we need
 	image := cast(win.HBITMAP)win.LoadImageW(hInst = nil, name = name, type = win.IMAGE_BITMAP, cx = 0, cy = 0, fuLoad = win.LR_LOADFROMFILE | win.LR_CREATEDIBSECTION) // -> HANDLE ---
    return image
}

update :: proc(deltatime:f64) {
}

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("SoftwareTestingClass"),
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &win_rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Software Testing"),
		dwStyle = win.WS_OVERLAPPED | win.WS_VISIBLE | win.WS_SYSMENU,
		X = 0,
		Y = 0,
		nWidth = win_rect.right - win_rect.left,
		nHeight = win_rect.bottom - win_rect.top,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)

	// Loading in BITMAP image
	loaded_image = load_bitmap_image("guy.bmp")
	
	if loaded_image == nil {
	    fmt.println("could not load image")
		return
	}
	// message/event loop
	message:win.MSG

	for running {
		// Check events
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}else {
			// Setting up fixed framerate data
			timestamp.fixed_timestamp = 1.0 / 60.0
			timestamp.last_time = get_current_time()
			timestamp.current_time = get_current_time()
			timestamp.deltatime = f64(timestamp.current_time) / f64(timestamp.last_time)
			timestamp.accumulator += timestamp.deltatime
			for timestamp.accumulator >= timestamp.fixed_timestamp {
				update(timestamp.deltatime)
				timestamp.accumulator -= timestamp.fixed_timestamp
 			}
			// Redraw the window
			win.InvalidateRect(hWnd = window, lpRect = nil, bErase = win.TRUE)

			// win.RedrawWindow(hwnd = window, lprcUpdate = nil, hrgnUpdate = nil, flags = .RDW_INVALIDATE | .RDW_UPDATENOW)
			win.UpdateWindow(hWnd = window)
			// fmt.println("Screen redrawn")
		}
	}
}