package main

import "core:fmt"
import "core:strings"
import win "core:sys/windows"

main :: proc() {

	dialog:^win.IFileOpenDialog

	win.CoInitialize(nil)

	win.CoCreateInstance(
		rclsid = win.CLSID_FileOpenDialog,
		pUnkOuter = nil,
		dwClsContext = win.CLSCTX_ALL,
		riid = win.IID_IFileOpenDialog,
		ppv = cast(^rawptr)&dialog,
	)// -> HRESULT ---

	dialog -> Show(nil)

	item:^win.IShellItem
	items:^win.IShellItemArray

	dialog->GetResults(&items)

	file_path:^u16
	items->GetItemAt(0, &item)
	item->GetDisplayName(.FILESYSPATH, &file_path)

	str, _ := win.wstring_to_utf8(cast(win.wstring)file_path, -1)


	// Directly deleting str will cause the application to crash/exit improperly.
	// So cloning str to a new value then deleting that clone will fix the issue
	value := strings.clone(str)
	delete(value)

	win.CoTaskMemFree(file_path)
	item->Release()
	dialog->Release()

}