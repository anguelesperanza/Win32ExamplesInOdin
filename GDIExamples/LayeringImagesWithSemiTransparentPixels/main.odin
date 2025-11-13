package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:image"
import "core:image/png"


/*
	This is an example on how to render multiple images on top of one each other but with semi(partial) transparency.
	This runs at a fixed timestamp / speed; no variable deltatime

	Art comes from itch.io:	https://ansimuz.itch.io/mountain-dusk-parallax-background
*/

// Globals
running := true // Exiting main loop (which in turn leads to exiting application)
win_rect:win.RECT = {left = 0, top = 0, right = 320, bottom = 240} // Window borders
parallax_root:string

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

Parallax :: struct {
	hdc:win.HDC,
	hBitmap:win.HBITMAP,
	filename:string,
	bitmap:win.BITMAP,
	blend:win.BLENDFUNCTION,
}

DrawingBuffers :: struct {
	back_buffer:win.HDC,
	front_buffer:win.HDC,
	hBitmap:win.HBITMAP,
	parallax:[6]Parallax,
}
drawing_buffers:DrawingBuffers

// Structs
Player :: struct {
	rect:win.RECT,
	pos:[2]f64,
	brush:win.HBRUSH,
	color:win.COLORREF,
	jumping:bool,
	speed:f64,
}
player:Player

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
			
			win.DeleteDC(hdc = drawing_buffers.back_buffer) // removes the device context that was created in memory
			win.DeleteObject(ho = cast(win.HGDIOBJ)drawing_buffers.hBitmap) // removes the bitmap
			win.ReleaseDC(hWnd = window, hDC = drawing_buffers.front_buffer)
			
			running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:
			/*On window creation*/
			set_defaults()

			drawing_buffers.front_buffer = win.GetDC(hWnd = window) // Gets the main device context
			drawing_buffers.back_buffer = win.CreateCompatibleDC(hdc = drawing_buffers.front_buffer)
			drawing_buffers.hBitmap = win.CreateCompatibleBitmap(hdc = drawing_buffers.front_buffer, cx = win_rect.right, cy = win_rect.bottom)
			win.SelectObject(hdc = drawing_buffers.back_buffer, h = cast(win.HGDIOBJ)drawing_buffers.hBitmap)

			blend:win.BLENDFUNCTION = {BlendOp = win.AC_SRC_OVER,BlendFlags = 0,SourceConstantAlpha = 255,AlphaFormat = win.AC_SRC_ALPHA}
			semi_blend:win.BLENDFUNCTION = {BlendOp = win.AC_SRC_OVER,BlendFlags = 0,SourceConstantAlpha = 128,AlphaFormat = win.AC_SRC_ALPHA}

			add_parallax_layer(filename = "images/sky.png", layer = 5,blend = blend)
			add_parallax_layer(filename = "images/far-mountains.png", layer = 4,blend = blend)
			add_parallax_layer(filename = "images/middle-mountains.png", layer = 3,blend = blend)
			add_parallax_layer(filename = "images/far-trees.png", layer = 2,blend = blend)
			add_parallax_layer(filename = "images/near-trees.png", layer = 1,blend = blend)
			add_parallax_layer(filename = "images/myst.png", layer = 0,blend = semi_blend)
			
		case win.WM_PAINT:
			// The event for painting to the window
			paint: win.PAINTSTRUCT
			device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			// reversing the order of the for loop for logical reasoning -> 5 is closer to 0 than 4 so 5 should be the farthest back
			#reverse for i in drawing_buffers.parallax{
				if i.hBitmap != nil {
					win.SelectObject(hdc = i.hdc, h = cast(win.HGDIOBJ)i.hBitmap)
					
					result := win.AlphaBlend(
						hdcDest = drawing_buffers.back_buffer,
						xoriginDest = 0,
						yoriginDest = 0,
						wDest = 320,
						hDest = 240,
						hdcSrc = i.hdc,
						xoriginSrc = 0,
						yoriginSrc = 0,
						wSrc = 320,
						hSrc = 240,
						ftn = i.blend
					)

					if result == false {
						fmt.printf("Result: %v: Could not display parallax image: %v\n", result,i.filename)
					}
				}
			}

			result := win.BitBlt(
				hdc = device_context,
				x = 0,
				y = 0,
				cx = 320,
				cy = 240,
				hdcSrc = drawing_buffers.back_buffer,
				x1 = 0,
				y1 =0,
				rop = win.SRCCOPY
			)

			// result := win.GdiAlphaBlend(
			// 	hdcDest = device_context,
			// 	xoriginDest = 0,
			// 	yoriginDest = 0,
			// 	wDest = 320,
			// 	hDest = 240,
			// 	hdcSrc = drawing_buffers.back_buffer,
			// 	xoriginSrc = 0,
			// 	yoriginSrc = 0,
			// 	wSrc = 320,
			// 	hSrc = 240,
			// 	ftn = {BlendOp = win.AC_SRC_OVER,BlendFlags = 0,SourceConstantAlpha = 255,AlphaFormat = win.AC_SRC_ALPHA}
			// )


			if result == false {
				fmt.printf("Could not display final image\n")
			}
		
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

load_image :: proc(filename:string) -> win.HBITMAP {
	/*Loads a png file to be used by GDI
	For more information: please check: https://github.com/anguelesperanza/Odin-Win32-Graphics-Examples/blob/main/LoadImagePNG/main.odin */
	
	image_data, err := image.load_from_file(filename) // Load png

	// Check if there was an error loading the image
	if err != nil {
		fmt.printf("Error: %v: returning empty HBITMAP", err)
		temp:win.HBITMAP
		return temp
	}

	// Correct pixel channels to match bitmap
	pixel_count := image_data.width * image_data.height
	for i := 0; i < pixel_count; i += 1 {
	    base := i * 4
	    // Swap the Red (index 0) and Blue (index 2) channels.
	    temp := image_data.pixels.buf[base + 0];
	    image_data.pixels.buf[base + 0] = image_data.pixels.buf[base + 2]
	    image_data.pixels.buf[base + 2] = temp
	}

	// Create BitmapInfo
	pbmi := win.BITMAPINFO {
		bmiHeader = {
			biSize = size_of(win.BITMAPINFOHEADER),
			biWidth = i32(image_data.width),
			biHeight = i32(-image_data.height),
			biPlanes = 1,
			biBitCount = 32,
			biCompression = win.BI_RGB,
		}
	}

	// Create a Bitmap
	hBitmap := win.CreateDIBitmap(
		hdc = drawing_buffers.front_buffer,
		pbmih = &pbmi.bmiHeader,
		flInit = win.CBM_INIT ,
		pjBits = raw_data(image_data.pixels.buf),
		pbmi = &pbmi,
		iUsage = win.DIB_RGB_COLORS,
	)

	return hBitmap
}

add_parallax_layer :: proc(filename:string, layer:int, blend:win.BLENDFUNCTION) {
	/*Adds the image to drawing_buffers.parallax at index 'layer'
	layer 0 is closest to the player, the higher then number, the farther back it is.*/
	if layer > len(drawing_buffers.parallax){
		fmt.println("Layer must be 0, 1, 2, 3, 4, 5")
		return
	}

	drawing_buffers.parallax[layer].filename = filename
	// drawing_buffers.parallax[layer].hdc = drawing_buffers.back_buffer
	// drawing_buffers.parallax[layer].hdc = drawing_buffers.front_buffer
	drawing_buffers.parallax[layer].hdc = win.CreateCompatibleDC(hdc = drawing_buffers.front_buffer)
	drawing_buffers.parallax[layer].hBitmap = load_image(filename)
	drawing_buffers.parallax[layer].blend = blend
	
	
	if drawing_buffers.parallax[layer].hBitmap == nil {
        fmt.printf("Failed to load image: %s\n", filename)
        return
    }

    // Get bitmap info
    win.GetObjectW(
	   	h = cast(win.HANDLE)drawing_buffers.parallax[layer].hBitmap, 
    	c = size_of(win.BITMAP), 
     	pv = &drawing_buffers.parallax[layer].bitmap
    )
}

get_current_time :: proc() -> win.LARGE_INTEGER{
	/*In C, a LARGE_INTEGER is a struct, In Odin, it's a c_longlong --> an f64*/
	win.QueryPerformanceFrequency(lpFrequency = &timestamp.frequency)
	win.QueryPerformanceCounter(lpPerformanceCount = &timestamp.counter)
	current_time := timestamp.counter / timestamp.frequency
	return current_time
}

set_defaults :: proc(){
	/*Run before main function to setup defaults for world objects/player*/
	fmt.println("Setting Defaults")
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
		lpszClassName = win.L("SemiTransparentImageLayeringWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &win_rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Layering Images with Semi-transparent pixels "),
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
