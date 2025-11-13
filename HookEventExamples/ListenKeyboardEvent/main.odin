package main



/*
	Low Level Keyboard Hook
	=======================
	This example shows how to use a hook event to listen to keyboard input even when the application is not in focus.
	Low Level Keyboard Hooks do not need to be a seperate .dll process (according to copilot)
*/

import "core:c"
import "core:fmt"
import "core:strings"
import win "core:sys/windows"

import "base:runtime"
// event loop boolean
running: bool = true

hook_proc :: proc "system" (code: c.int, wParam: win.WPARAM, lParam: win.LPARAM) -> win.LRESULT {
	context = runtime.default_context()
	if code == win.HC_ACTION {

		// lParam is a long pointer (uint), so converting to a pointer, and that pointer into a KBDLLHOOKSTRUCT
		keyboard:^win.KBDLLHOOKSTRUCT = cast(^win.KBDLLHOOKSTRUCT)uintptr(lParam)
		
		switch wParam {
		case win.WM_SYSKEYDOWN:
			fmt.println("ALT Key was pressed")
		case win.WM_KEYDOWN:
			fmt.println("KEYDOWN",keyboard.scanCode)
		case win.WM_KEYUP:
			fmt.println("KEYUP:", keyboard.scanCode)
		}
	}

	return win.CallNextHookEx(hhk = nil, nCode = code, wParam = wParam, lParam = lParam)
}

main :: proc() {
	windows_hook: win.HHOOK = win.SetWindowsHookExW(
		idHook = win.WH_KEYBOARD_LL,
		lpfn = hook_proc,
		hmod = nil,
		dwThreadId = 0,
	) // -> HHOOK ---
	defer win.UnhookWindowsHookEx(hhk = windows_hook) // -> BOOL ---
	// Second: 'Navigate' between windows (bring to top)
	message: win.MSG
	for running {
		// Using PeekMessageW and not GetMessageW
		// Peak does not wait for a message to arrive if there is not one
		// Whereas GetMessageW does
		if win.PeekMessageW(
			lpMsg = &message,
			hWnd = nil,
			wMsgFilterMin = 0,
			wMsgFilterMax = 0,
			wRemoveMsg = win.PM_REMOVE,
		) {
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
	}
}
