package controllerinput

/*
	Controller Input
	================

	This shows how to read controller input using GameInput

	How this works; The important thing to remember is you need an active window in focus to read input.
	This means that running the application in the terminal will not work -- the won't crash, however the button state won't update

	As such, the BasicWindow example is used here

	GameInput specific controller code sits in two places
		1: In the main loop, after we process the PeekMessageW events
		2: Right before the main loop, after we create and show the window
	
	The idea is this (overview): Every interation of the loop (frame) we grab a new stream of input data to read. Because GameInput
	combines different input stream into one; we need to filter specifically for a Gamepad (or whatever input device you want).

	Then we'll want to grab the gamepad if we don't already have one -- GameInput will return the first matching device in the input stream
	So if we're filtering for a gamepad, the first gamepad to send input is what will be returend when doing reading->GetDevice(...)

	Then once we have the input we can check it for device information or the gamepad state. However, we can lose connection to a gamepad
		- It becomes unplugged, batteries die, etc, so when checking for anything related to the gamepad, we want to make sure we still have the conneciton

	The gamepad state is a bit_set that will have the values set in it if the button is pressed -- this means you can query the bit set as you normally would.
	In this example I've done a "if .some_valid_value in GameInput-BitSet" and then just print out a string saying the button was pressed

	The analogue sticks work the same way, excempt their default state is 0 instead of a value in a bitset

	Note: GetDeviceInfo can return a `displayName` with is a ^String --> this is a pointer to a GameInput struct, not an pointer to an Odin string
	This can return nil as not every controller has this information

	One way to tell is to use the vendorId that returns form GetDeviceInfo(). You can then use that ID on a website like: https://devicehunt.com/
	and switch the type from PCI to USB
	Though it takes the hex value of it so you'll want to convert it to hexadecimal
	
 		- info := gamepad->GetDeviceInfo()
		- fmt.printfln("vendor id: 0%x", info.vendorId)
		- That should print out in hex

	In that list should be your controller - or at least the brand -- specifics may vary but the brand is the important part, that way you can tell
	that at least that controller (by brand) is being picked up in the input stream

	References:
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
	gamepad:^gi.IDevice
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
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}

		result := input->GetCurrentReading({.Gamepad}, gamepad, &reading)
		
		if win.SUCCEEDED(result) {
			if gamepad == nil do reading->GetDevice(&gamepad)
			if gamepad != nil  {

				state:gi.GamepadState
				ok := reading->GetGamepadState(&state)
				reading->Release()

				if .A in state.buttons  {
					fmt.println("A is pressed")
				}

				if .X in state.buttons  {
					fmt.println("X is pressed")
				}
				if .Y in state.buttons  {
					fmt.println("Y is pressed")
				}

				if .B in state.buttons  {
					fmt.println("B is pressed")
				}

				if state.leftThumbstickX != 0 {
					fmt.println("Left thumstick X", state.leftThumbstickX)
				}
				if state.leftThumbstickY != 0 {
					fmt.println("Left thumstick Y ", state.leftThumbstickX)
				}

				// The rest of the buttons and such
				
			} else {
				fmt.println("No Gamepad found")
			}
		}
	}
	
	if input != nil do input->Release()
	if gamepad != nil do gamepad->Release()
}
