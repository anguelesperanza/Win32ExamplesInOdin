package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:image"
import "core:image/png"


/*
	Parallax Backgrounds / Scrolling

	This is an example on how to do parallax backgrounds in GDI
	Game runs at a fixed timestamp / speed; no variable deltatime
*/

// Globals
running := true // Exiting main loop (which in turn leads to exiting application)
win_rect:win.RECT = {left = 0, top = 0, right = 320, bottom = 240} // Window borders
parallax_root:string
parallax_base_offset:f64


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
	speed:f64,
	pos:[2]f64,
	offset_x:f64,
}

DrawingBuffers :: struct {
	back_buffer:win.HDC,
	front_buffer:win.HDC,
	hBitmap:win.HBITMAP,
	parallax:[6]Parallax,
}
drawing_buffers:DrawingBuffers

// Creating a 'blendfunction' struct for rendering alpha transparency
blend_function:win.BLENDFUNCTION

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

			// For right now, single backbuffer for rendering to the screen; however, if doing paralax scrolling, should use multiple buffers
			drawing_buffers.front_buffer = win.GetDC(hWnd = window) // Gets the main device context
			drawing_buffers.back_buffer = win.CreateCompatibleDC(hdc = drawing_buffers.front_buffer)
			drawing_buffers.hBitmap = win.CreateCompatibleBitmap(hdc = drawing_buffers.front_buffer, cx = win_rect.right, cy = win_rect.bottom)
			win.SelectObject(hdc = drawing_buffers.back_buffer, h = cast(win.HGDIOBJ)drawing_buffers.hBitmap)


			blend_function = {
				BlendOp = win.AC_SRC_OVER,
				BlendFlags = 0,
				SourceConstantAlpha = 255,
				AlphaFormat = win.AC_SRC_ALPHA,
			}
			
			add_parallax_layer(filename = "images/sky.png", layer = 5, speed = 0)
			add_parallax_layer(filename = "images/far-mountains.png", layer = 4, speed = 0)
			add_parallax_layer(filename = "images/middle-mountains.png", layer = 3, speed = 0.000007)
			add_parallax_layer(filename = "images/far-trees.png", layer = 2, speed = 0.000006)
			add_parallax_layer(filename = "images/myst.png", layer = 1, speed = 0.0005)
			add_parallax_layer(filename = "images/near-trees.png", layer = 0, speed = 0.0017)
			
		case win.WM_PAINT:
			// The event for painting to the window
			paint: win.PAINTSTRUCT
			device_context := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			// reversing the order of the for loop for logical reasoning -> 5 is closer to 0 than 4 so 5 should be the farthest back
			#reverse for &i in drawing_buffers.parallax{
				if i.hBitmap != nil {
					win.SelectObject(hdc = i.hdc, h = cast(win.HGDIOBJ)i.hBitmap)

					if i32(i.pos.x) <= -320 {
						i.pos.x = 320
					}
					if i.offset_x <= -320 {
						i.offset_x = i.pos.x + 320
					}

					if i.pos.x + 320 < 0 {
						i.pos.x = f64(win_rect.right)
					}					
					result := win.AlphaBlend(
						hdcDest = drawing_buffers.back_buffer,
						xoriginDest = i32(i.pos.x),
						yoriginDest = 0,
						wDest = 320,
						hDest = 240,
						hdcSrc = i.hdc,
						xoriginSrc = 0,
						yoriginSrc = 0,
						wSrc = 320,
						hSrc = 240,
						ftn = blend_function
					)
					result = win.AlphaBlend(
						hdcDest = drawing_buffers.back_buffer,
						xoriginDest = i32(i.offset_x),
						yoriginDest = 0,
						wDest = 320,
						hDest = 240,
						hdcSrc = i.hdc,
						xoriginSrc = 0,
						yoriginSrc = 0,
						wSrc = 320,
						hSrc = 240,
						ftn = blend_function
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

add_parallax_layer :: proc(filename:string, layer:int, speed:f64) {
	/*Adds the image to drawing_buffers.parallax at index 'layer'
	layer 0 is closest to the player, the higher then number, the farther back it is.*/
	if layer > len(drawing_buffers.parallax){
		fmt.println("Layer must be 0, 1, 2, 3, 4, 5")
		return
	}

	drawing_buffers.parallax[layer].filename = filename
	drawing_buffers.parallax[layer].hdc = win.CreateCompatibleDC(hdc = drawing_buffers.front_buffer)
	drawing_buffers.parallax[layer].hBitmap = load_image(filename)
	drawing_buffers.parallax[layer].speed = speed
	
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

    
	drawing_buffers.parallax[layer].offset_x = drawing_buffers.parallax[layer].pos.x + 320
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
	parallax_base_offset = 1.0


	// Setting up Player
	player.rect = {
		left = i32(player.pos.x),
		top = i32(player.pos.y),
		right = i32(player.pos.x) + 32,
		bottom = i32(player.pos.y) + 64
	} // Sets up the rectangle
	player.speed = 0.01
	
	// player.color = win.RGB(r = 200, g = 100, b = 50) // Sets up the color of the rectangle
	player.color = win.RGB(r = 255, g = 0, b = 0) // Sets up the color of the rectangle
	player.brush = win.CreateSolidBrush(color = player.color) // Sets up the brush hande used color the rectangle
	
	parallax_root = "./images/"


	// blend_function = { win.AC_SRC_OVER, 0, 128, 0 }; // 50% transparency	
}

update :: proc(deltatime:f64) {
	parallax_base_offset += 1.0
	#reverse for &layer in drawing_buffers.parallax {
		if layer.speed > 0 {
			layer.pos.x -= layer.speed * deltatime
			layer.offset_x -= layer.speed * deltatime
			// layer.speed *= deltatime
			// fmt.printf("%v: %v\n", layer.filename,(layer.pos.x))
			// fmt.printf("%v: %v: %v\n", layer.filename,layer.speed, layer.speed + deltatime)
		}
	}

	
		
	/*Update Loop / Game Loop*/
	// player.pos.x += player.speed * deltatime
	// player.rect = {
	// 	left = i32(player.pos.x),
	// 	top = i32(player.pos.y),
	// 	right = i32(player.pos.x) + 32,
	// 	bottom = i32(player.pos.y) + 64
	// } // Updates the player's position and rectangle

	// fmt.println(player.rect)
}

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("ParallaxWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &win_rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Parallax Backgrounds"),
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
