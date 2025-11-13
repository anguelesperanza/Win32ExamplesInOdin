package main


import "core:fmt"
import win "core:sys/windows"

/*
	Batter Level
	============
	This example shows how to get the battery level related to your system.
	Not gonna lie, doing research for this made this seem 1000% more complicated then it was.
	Then boom, random stack overflow article (https://stackoverflow.com/questions/233446/monitor-battery-charge-with-win32-api)
	had this as a solution. 
*/

main :: proc() {
	power_status:win.SYSTEM_POWER_STATUS
	win.GetSystemPowerStatus(lpSystemPowerStatus = &power_status) // -> BOOL ---
	fmt.println(power_status)
}
