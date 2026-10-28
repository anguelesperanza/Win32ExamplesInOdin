package keyboard

/*
	Controller Input
	================

	This shows how to read keyboard input using GameInput

	How this works; The important thing to remember is you need an active window in focus to read input.
	This means that running the application in the terminal will not work -- the won't crash, however the button state won't update

	As such, the BasicWindow example is used here with a slight modification:
			if win.PeekMessageW(lpMsg = &message, hWnd = window, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
												        |> Here (formally nil)

			In the BasicWindow example, the hWnd paraemter of PeekMessageW is nil - which means the event loop will poll events from every window
			For GameInput, this means our input is also getting consumed by PeekMessageW

			Instead, we pass `window` - which is the value returned by CreateWindowExW(...), this will cause PeekMessageW to only
			consume events from the created window, and not consume the GameInput events.

	GameInput specific Keyboard code sits in two places
		1: In the main loop, after we process the PeekMessageW events
		2: Right before the main loop, after we create and show the window
	
	The idea is this (overview): Every interation of the loop (frame) we grab a new stream of input data to read. Because GameInput
	combines different input stream into one; we need to filter specifically for a Keybaord (or whatever input device you want).

	Then we'll want to grab the Keyboard if we don't already have one -- GameInput will return the first matching device in the input stream
	So if we're filtering for a Keyboard, the first gamepad to send input is what will be returend when doing reading->GetDevice(...)

	Then once we have the input we can check it for device information or the Keyboard Key State. However, we can lose connection to a Keyboard
		- It becomes unplugged, batteries die, etc, so when checking for anything related to the Keyboard, we want to make sure we still have the conneciton

	Unlike a Gamepad, the Keyboard returns a KeyState array -- This array only contains the keys that were pressed when the input stream was read.
	That means this array grows and shrinks as needed. However, GetKeyState(...) requires a lenght value so it knows how to size this array.

	That is handled by GetKeyCount(). This returns the number of keys currently pressed when the input stream is read.

	The array that returns from GetKeyState(...) takes a buffer that will hold that returned data.

	Since the array grows and shrinks, we can't pass a fixed array size, so we remake a new array, sized at key_count and then
	pass that to GetKeyState() and since GetKeyState takes a multi-pointer we pass the raw_data for our key state array.

	Note: GetDeviceInfo can return a `displayName` with is a ^String --> this is a pointer to a GameInput struct, not an pointer to an Odin string
	This can return nil as not every keyboard has this information

	One way to tell is to use the vendorId that returns form GetDeviceInfo(). You can then use that ID on a website like: https://devicehunt.com/
	and switch the type from PCI to USB
	Though it takes the hex value of it so you'll want to convert it to hexadecimal
	
 		- info := gamepad->GetDeviceInfo()
		- fmt.printfln("vendor id: 0%x", info.vendorId)
		- That should print out in hex

	In that list should be your controller - or at least the brand -- specifics may vary but the brand is the important part, that way you can tell
	that at least that controller (by brand) is being picked up in the input stream

	References:
		https://learn.microsoft.com/en-us/gaming/gdk/docs/features/common/input/advanced/input-keyboard-mouse?view=gdk-2604
		https://learn.microsoft.com/en-us/gaming/gdk/docs/reference/input/gameinput/structs/gameinputkeystate?view=gdk-2604	
		https://learn.microsoft.com/en-us/gaming/gdk/docs/reference/input/gameinput/interfaces/igameinputreading/methods/igameinputreading_getdevice?view=gdk-2604
		https://learn.microsoft.com/en-us/gaming/gdk/docs/features/common/input/overviews/input-devices?view=gdk-2604*/

import "core:fmt"

import win "core:sys/windows"
import gi "vendor:windows/GameInput"

running := true // Exiting main loop (which in turn leads to exiting application)
// window size
rect:win.RECT = {left = 0, top = 0, right = 1280, bottom = 720}


// Callback function for handling events
window_event_proc :: proc "stdcall" (window: win.HWND, message: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) -> win.LRESULT {

	switch message {
		case win.WM_PAINT:
			// Very basic window painting to make the window black
			paint: win.PAINTSTRUCT
			hdc := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(hdc, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window; causing flickering but without it, painting does not work right

		case win.WM_DESTROY:
			running = false
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


	// Create a handle to the instance of the application - The thing the OS uses to ID the executable
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

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
		lpszClassName = win.L("Basic_Window_Class"),
		hIconSm = nil,
	}

	
	win.RegisterClassExW(&window_class)
	win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Basic Window"),
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

	
	input:^gi.IGameInput
	keyboard:^gi.IDevice
	reading:^gi.IReading // reading the input stream for the input

	result := gi.Create(&input)

	if win.SUCCEEDED(result) == false {
		fmt.println("Could not get input")
		return
	}

	// message/event loop
	message:win.MSG
	for running {
		// Using PeekMessageW and not GetMessageW
		// Peak does not wait for a message to arrive if there is not one
		// Whereas GetMessageW does
		
		if win.PeekMessageW(lpMsg = &message, hWnd = window, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		} 

		result := input->GetCurrentReading({.Keyboard}, keyboard, &reading)
		
		if win.SUCCEEDED(result) {
			if keyboard == nil do reading->GetDevice(&keyboard)
			if keyboard != nil  {

				key_count := reading->GetKeyCount()

				state:[]gi.KeyState = make([]gi.KeyState, key_count)
				ok := reading->GetKeyState(key_count, raw_data(state))
				reading->Release()

				for key in state {
					fmt.println(key.virtualKey)
				}

				// The rest of the buttons and such
				
			} else {
				fmt.println("No keyboard found")
			}
		}
	}
	
	if input != nil do input->Release()
	if keyboard != nil do keyboard->Release()
}
