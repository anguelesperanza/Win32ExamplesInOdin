package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:image"
import "core:image/png"
import "core:mem"

/*
    Upscalling Image:
    =================
    There's a few ways to upscale an image, but this way specifically uses the win32 api.
    
    A couple of things to note: This was created while working on another project so a lot of these seems weird.
    load_png_image just takes in a png and converts it to a .bmp image that win32 uses. 
    It's looks complicated (and kinda is) but you can use a .bmp compatible file if you have one and know how to load it in.
    
    Once you have an image loaded that you can use, the process is the same.
    
    This example uses a back buffer to prevent flickering
    
    there's a 60 fps fixed framerate -- this was copied mid project that's why
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

// Creating a 'blendfunction' struct for rendering alpha transparency
blend_function:win.BLENDFUNCTION

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

            // win.SetStretchBltMode(hdc = device_context, iStretchMode = win.HALFTONE)
			
            // Upscale and draw the image to 128x128
            win.StretchBlt(hdcDest = device_context, xDest = 0, yDest = 0, wDest = 128, hDest = 128, hdcSrc = mem_dc, xSrc = 0, ySrc = 0, wSrc = buf.bmWidth, hSrc = buf.bmHeight, rop = win.SRCCOPY) // -> BOOL ---
			win.BitBlt(hdc = device_context, x = 130, y = 0, cx = buf.bmWidth, cy = buf.bmHeight, hdcSrc = mem_dc, x1 = 0, y1 = 0, rop = win.SRCCOPY) // -> BOOL ---
			
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

load_image:: proc(filename:string, window_handle:win.HWND) -> win.HBITMAP {
    
    // image_data, err := os2.read_entire_file_from_path(name = filename, allocator = context.allocator)
    image_data, err := png.load_from_file(filename = filename)
    if err != nil {
        fmt.eprintln(err)
        empty_hbitmap:win.HBITMAP
        return empty_hbitmap
    }
    
    pixel_count := image_data.width * image_data.height
   	for i := 0; i < pixel_count; i += 1 {
   	    base := i * 4
   	    // Swap the Red (index 0) and Blue (index 2) channels.
   	    temp := image_data.pixels.buf[base + 0];
   	    image_data.pixels.buf[base + 0] = image_data.pixels.buf[base + 2]
   	    image_data.pixels.buf[base + 2] = temp
   	}
    bitmap_info := win.BITMAPINFO {
		bmiHeader = {
			biSize = size_of(win.BITMAPINFOHEADER),
			biWidth = i32(image_data.width),
			biHeight = i32(-image_data.height),
			biPlanes = 1,
			biBitCount = 32,
			biCompression = win.BI_RGB,
		},
	}   
	pixel_buffer:^win.VOID
	screen_dc := win.GetDC(nil)
	// CreateDIBSection :: proc(             hdc: HDC,        pbmi: ^BITMAPINFO,   usage: UINT,                ppvBits: ^^VOID,         hSection: HANDLE, offset: DWORD) -> HBITMAP ---
    image:win.HBITMAP = win.CreateDIBSection(hdc = screen_dc, pbmi = &bitmap_info, usage = win.DIB_RGB_COLORS, ppvBits = &pixel_buffer, hSection = nil, offset = 0) // -> HBITMAP ---
    
    win.ReleaseDC(nil, screen_dc)

    if image == nil || pixel_buffer == nil {
        fmt.eprintln("CreateDIBSection failed")
        return nil
    }
    
    mem.copy_non_overlapping(dst = cast(rawptr)pixel_buffer, src = cast(rawptr)raw_data(image_data.pixels.buf), len = image_data.width * image_data.height * 4)// -> rawptr 
 
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
		lpszClassName = win.L("UpscalePNGClass"),
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &win_rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Upscale PNG"),
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
	loaded_image = load_image("./images/girl.png", window)
	
	
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