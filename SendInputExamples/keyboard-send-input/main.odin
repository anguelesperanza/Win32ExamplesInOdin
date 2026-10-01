package main


/*
	Send Keyboard Input
	===================

	When run, a w should appear in the terminal

	When running with odin run . , a w should appear in the terminal around when the program exits

	resources:
		https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput

*/

import win "core:sys/windows"

main :: proc() {
	inputs: [2]win.INPUT
	inputs[0].type = .KEYBOARD
	inputs[0].ki.wVk = win.VK_W

	inputs[1].type = .KEYBOARD
	inputs[1].ki.wVk = win.VK_W

	// 0x0002 is the release key flag.
	inputs[1].ki.dwFlags = 0x0002

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)
}
