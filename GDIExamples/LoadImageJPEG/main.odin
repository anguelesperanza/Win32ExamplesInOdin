

package maing


import "base:runtime"

import "core:fmt"
import win "core:sys/windows"

import stbi "vendor:stb/image"


/*

	NOTE: 9/20/2025: This was written before JPEG support in core, so it uses stb in the vendor package instead

	This file loads an .jpg
	GDI only works with .bmp files so the goal here is to load the image
	using not using GDI and then convert that image into a .bmp to then be displayed.

	Then this image data will be converted into a .bmp using the win32 api
	"CreateDIBitmap"

	WIC is not used as there are not full bindings for WIC in Odin. CoCreateInstance is there and
	but I couldn't find much else and didn't want to write WIC bindings at 5:30 in the morning.
	If there are full bindings, I cannot find them.

	Reference: https://github.com/karl-zylinski/odin-win32-software-rendering/blob/main/win32_software_rendering.odin

*/

// Globals
running := true
hBitmap:win.HBITMAP
image_data:[^]u8
image_width:i32
image_height:i32



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
			image_data = stbi.load("./truth.jpg", &image_width, &image_height, nil, 4)

			// Essentially, the GDI function: CreateDIBitmap -- which is uses to render our PNG after we convert it to a bitmap
			// Expects the color value to be BGRA (Blue, Green, Red, Alpha), however,
			// Typical PNGS are usually RGBA (Red, Green, Blue, Alpha)
			// So this code will shift the RGBA values around to now be BGRA
			// If left as normal; the image will be tinted blue
			pixel_count := image_width * image_height
			for i:i32 = 0; i < pixel_count; i += i32(1) {
			    base := i * 4
			    // Swap the Red (index 0) and Blue (index 2) channels.
			    temp := image_data[base + 0];
			    image_data[base + 0] = image_data[base + 2]
			    image_data[base + 2] = temp
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
			
			// So this struct takes in a BITMAPINFOHEADER and a bmiColors
			// Thie BITMAPINFOHEADER is also a struct (can be found in types.odin for the windows package)
			// So setting those values here.			
			pbmi := win.BITMAPINFO {
				bmiHeader = {
					biSize = size_of(win.BITMAPINFOHEADER),
					biWidth = i32(image_width),
					biHeight = i32(-image_height),
					biPlanes = 1,
					biBitCount = 32,
					biCompression = win.BI_RGB,
				}
			}

			hBitmap = win.CreateDIBitmap(
			hdc = device_context,
			pbmih = &pbmi.bmiHeader,
			flInit = win.CBM_INIT ,
			pjBits = rawptr(image_data),
			pbmi = &pbmi,
			iUsage = win.DIB_RGB_COLORS,
			)

			hOldBitmap:win.HBITMAP = cast(win.HBITMAP)win.SelectObject(hdc = hdc_memory, h = cast(win.HGDIOBJ)hBitmap)
			bm:win.BITMAP

			win.GetObjectW(h = cast(win.HANDLE)hBitmap, c = size_of(win.BITMAP), pv = &bm)

			win.BitBlt(
				hdc = device_context,
				x = 0,
				y = 0,
				cx = bm.bmWidth,
				cy = bm.bmHeight ,
				hdcSrc = hdc_memory,
				x1 = 0,
				y1 =0,
				rop = win.SRCCOPY
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
		lpszClassName = win.L("LoadImageJPEGClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("LoadImageJPEG"),
		dwStyle = win.WS_OVERLAPPED | win.WS_VISIBLE | win.WS_SYSMENU,
		X = 0,
		Y = 0,
		nWidth = 720,
		nHeight = 713,
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
