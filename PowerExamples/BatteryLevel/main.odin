package main


import "core:fmt"
import win "core:sys/windows"

/*
	Batter Level
	============
	
	This example shows how to get the battery level related to your system.

	references:
		https://stackoverflow.com/questions/233446/monitor-battery-charge-with-win32-api
		https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getsystempowerstatus
*/

main :: proc() {
	power_status:win.SYSTEM_POWER_STATUS
	win.GetSystemPowerStatus(lpSystemPowerStatus = &power_status) // -> BOOL ---
	fmt.println(power_status)
}
