package main

/*
	Get Local Time
	==============

	According to the docs:
		GetLocalTime takes a pointer to SYSTEMTIME (types.odin) <-- This Exists in the odin bindings but not LPSYSTEMTIME.
		
	For the sake of having matching arguments here and in offical docs, created LPSYSTEMTIME, but really, just gonna pass pointer to SYSTEMTIME

	Resources
		https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlocaltime
*/


import "core:fmt"
import win "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

LPSYSTEMTIME :: ^win.SYSTEMTIME

@(default_calling_convention="system")
foreign kernel32 {
	GetLocalTime :: proc(lpSystemTime:LPSYSTEMTIME) --- 

}
main :: proc() {
	local_time:win.SYSTEMTIME
	GetLocalTime(lpSystemTime = &local_time)
	fmt.println(local_time)
}
