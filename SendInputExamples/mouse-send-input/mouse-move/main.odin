package main


/*
	Input - Mouse Move Example.

	This will move the mouse. If unsure if working,
	plece mouse in corner of screen first
	
*/

import win "core:sys/windows"

main :: proc() {

	inputs: [1]win.INPUT
	inputs[0].type = .MOUSE

	inputs[0].mi.dx = 400
	inputs[0].mi.dy = 400

	inputs[0].mi.dwFlags = win.MOUSEEVENTF_MOVE

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)

}
