
package main

import "core:fmt"
import win "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

// According to Win32 Docs (https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlocaltime)
// GetLocalTime takes a pointer to SYSTEMTIME (types.odin) <-- This Exists in the odin bindings but not LPSYSTEMTIME.
// For the sake of having matching arguments here and in offical docs, created LPSYSTEMTIME, but really, just gonna pass pointer to SYSTEMTIME
//
// You may have noticed this looks exactly like GetLocalTime....that's cause it is.
// GetLocalTime has todays date in it, in addition to the current time
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
