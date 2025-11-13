package main


import "core:fmt"
import win "core:sys/windows"

foreign import shell32 "system:Shell32.lib"

/*
	According to docs (https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryusernotificationstate)
	SHQueryUserNotificationState returns a HRESULT. The function signature shows SHSTDAPI to be the return value;
	thus, making SHSTDAPI a distinct HRESULT

	Windows reports a fullscreen application as QUNS_BUSY
	
*/

SHSTDAPI :: win.HRESULT


QUERY_USER_NOTIFICATION_STATE :: enum {
	QUNS_NOT_PRESENT = 1,
	QUNS_BUSY = 2,
	QUNS_RUNNING_D3D_FULL_SCREEN = 3,
	QUNS_PRESENTATION_MODE = 4,
	QUNS_ACCEPTS_NOTIFICATIONS = 5,
	QUNS_QUIET_TIME = 6,
	QUNS_APP = 7
}
// For getting if an application is fullscreen (different from maxamized)
@(default_calling_convention="system")
foreign shell32 {
	SHQueryUserNotificationState :: proc(pquns:^QUERY_USER_NOTIFICATION_STATE ) -> SHSTDAPI ---
}


main :: proc() {
	query:QUERY_USER_NOTIFICATION_STATE
	SHQueryUserNotificationState(pquns = &query)
	fmt.println(query)
}
