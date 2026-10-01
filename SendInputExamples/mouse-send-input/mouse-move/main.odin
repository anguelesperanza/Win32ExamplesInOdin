package main


/*

	Mouse Move
	==========
	This will move the mouse. If unsure if working,
	plece mouse in corner of screen first

	Depending on the editor your using, the mouse might not move (helix)

	Best to run odin build . and launch the executable from file explorer
	
*/

import win "core:sys/windows"

main :: proc() {

	inputs: [1]win.INPUT
	inputs[0].type = .MOUSE

	inputs[0].mi.dx = 200
	inputs[0].mi.dy = 400

	inputs[0].mi.dwFlags = win.MOUSEEVENTF_MOVE

	win.SendInput(
		cInputs = len(inputs),
		pInputs = raw_data(inputs[:]),
		cbSize = size_of(win.INPUT),
	)

}
