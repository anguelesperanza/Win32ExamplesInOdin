package main


/*
	Mouse Click
	===========

	When run, right click be pressed.

	If nothing happens, try copying text before running. This will prompt the terminal (usually)
	to ask if you want to paste your clipboard (right click action)
		- This is a feature of powershell however, so other shells might not do it. 
*/

import win "core:sys/windows"

main :: proc() {

	inputs: [1]win.INPUT
	inputs[0].type = .MOUSE

	inputs[0].mi.dwFlags = win.MOUSEEVENTF_RIGHTDOWN

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)

}
