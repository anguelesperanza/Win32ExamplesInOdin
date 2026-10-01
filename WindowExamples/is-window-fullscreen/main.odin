package main

/*
	Is Window Fullscreen
	====================

	This checks if a window if fullscreened

	From what I can tell, the calls for this are not in the odin bindings for win32
	They need to be manually FFI'd

	The stackoverflow link in the below resources goes into detail for why it's done this way

	This example only covers .QUINS_BUSY and .QUINS_ACCEPTS_NOTIFICATIONS but the other are simple to add in the switch statement as
	other cases

	Resources:
		https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryusernotificationstate
		https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
		https://stackoverflow.com/questions/7009080/detecting-full-screen-mode-in-windows		
	According to docs
	SHQueryUserNotificationState returns a HRESULT. The function signature shows SHSTDAPI to be the return value;
	thus, making SHSTDAPI a distinct HRESULT

	Windows reports a fullscreen application as QUNS_BUSY
	
*/

SHSTDAPI :: win.HRESULT

foreign import shell32 "system:Shell32.lib"

// For getting if an application is fullscreen (different from maxamized)
@(default_calling_convention="system")
foreign shell32 {
	SHQueryUserNotificationState :: proc(pquns:^QUERY_USER_NOTIFICATION_STATE ) -> SHSTDAPI ---
}


import "core:fmt"
import win "core:sys/windows"


QUERY_USER_NOTIFICATION_STATE :: enum {
	QUNS_NOT_PRESENT = 1,
	QUNS_BUSY = 2,
	QUNS_RUNNING_D3D_FULL_SCREEN = 3,
	QUNS_PRESENTATION_MODE = 4,
	QUNS_ACCEPTS_NOTIFICATIONS = 5,
	QUNS_QUIET_TIME = 6,
	QUNS_APP = 7
}

main :: proc() {
	query:QUERY_USER_NOTIFICATION_STATE
	SHQueryUserNotificationState(pquns = &query)

	#partial switch query {
		case .QUNS_BUSY:
			fmt.println("Application is in fullscreen")
		case .QUNS_ACCEPTS_NOTIFICATIONS:
			fmt.println("Application is not in fullscreen")
	}
}
