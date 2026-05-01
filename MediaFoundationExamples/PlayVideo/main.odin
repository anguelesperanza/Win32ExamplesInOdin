package playback

/*
This is a project to try and playback video using Windows Media Foundation
	https://learn.microsoft.com/en-us/windows/win32/medfound/how-to-play-unprotected-media-files

This project is based on a minimal working c example I had Copilot Generate.
The above api documentation shows function related information but is not good at showing how it all
works together.

Global Structs: WindowInformation
WindowInformation has information for window creating and loop management

*/

import "core:fmt"
import win "core:sys/windows"
import mf "../"

import "base:runtime"

WindowInformation: struct {
	running: bool,
	size:    win.RECT,
}

/*Media Foundation Related Procedures*/
CreateMediaSource :: proc(filename:string, ppSource:^^mf.IMFMediaSource) -> mf.HRESULT {
	resolver:^mf.IMFSourceResolver
	src:^mf.IUnknown
	object_type:mf.OBJECT_TYPE

	result := mf.CreateSourceResolver(&resolver)
	if win.FAILED(result) {
		fmt.println("Failed to create Source Resolver")
		return result
	}

	result = resolver->CreateObjectFromURL(cast([^]u16)win.utf8_to_wstring(filename), mf.RESOLUTION_MEDIASOURCE, nil, &object_type, &src)
	if win.FAILED(result) {
		fmt.println("Failed to create object from URL")
		return result
	}

	result = src.iunknown_vtable.QueryInterface(src, &mf.IID_IMFMediaSource, cast(^rawptr)ppSource)

	if src != nil {src.iunknown_vtable.Release(src)}
	if resolver != nil {resolver->Release()}
	return result
}

AddSourceNode :: proc(topology:^mf.IMFTopology, source:^mf.IMFMediaSource, pd:^mf.IMFPresentationDescriptor, sd:^mf.IMFStreamDescriptor, ppNode:^^mf.IMFTopologyNode) -> mf.HRESULT {
	node:^mf.IMFTopologyNode

    result := mf.CreateTopologyNode(.SourceStream, &node)
    if win.FAILED(result) { return result }

    result = node->SetUnknown(&mf.TOPONODE_SOURCE, cast(^mf.IUnknown)source)
    if win.FAILED(result) {
        node->Release()
        return result
    }

    result = node->SetUnknown(&mf.TOPONODE_PRESENTATION_DESCRIPTOR, cast(^mf.IUnknown)pd)
    if win.FAILED(result) {
        node->Release()
        return result
    }

    result = node->SetUnknown(&mf.TOPONODE_STREAM_DESCRIPTOR, cast(^mf.IUnknown)sd)
    if win.FAILED(result) {
        node->Release()
        return result
    }

    result = topology->AddNode(node)
    if win.FAILED(result) {
        node->Release()
        return result
    }

    ppNode^ = node
    return win.S_OK
}

AddOutputNode :: proc(topology:^mf.IMFTopology, video_handle:win.HWND, sd:^mf.IMFStreamDescriptor, ppNode:^^mf.IMFTopologyNode) -> win.HRESULT {

    activate:^mf.IMFActivate
    node:^mf.IMFTopologyNode
    handler:^mf.IMFMediaTypeHandler
    major:mf.GUID

    result := sd->GetMediaTypeHandler(&handler)
    if win.FAILED(result) { return result }

    result = handler->GetMajorType(&major)
    if win.FAILED(result) { handler->Release(); return result }

    result = mf.CreateTopologyNode(.Output, &node)
    if win.FAILED(result) { handler->Release(); return result }

    if mf.IsEqualGuid(&major, &mf.MediaType_Video) {
        result = mf.CreateVideoRendererActivate(video_handle, &activate)
    } else {
        result = mf.CreateAudioRendererActivate(&activate)
    }
    if win.FAILED(result) {
        handler->Release()
        node->Release()
        return result
    }

    result = node->SetObject(cast(^mf.IUnknown)activate)
    if win.FAILED(result) {
        activate->Release()
        handler->Release()
        node->Release()
        return result
    }

    result = topology->AddNode(node)
    if win.FAILED(result) {
        activate->Release()
        handler->Release()
        node->Release()
        return result
    }

    ppNode^ = node

    activate->Release()
    handler->Release()

    return win.S_OK
}

CreatePlaybackTopology :: proc(source:^mf.IMFMediaSource, video_handle:win.HWND, ppTopology:^^mf.IMFTopology) -> mf.HRESULT {

	topology:^mf.IMFTopology
	pd:^mf.IMFPresentationDescriptor


	result := mf.CreateTopology(&topology)
	if win.FAILED(result) {
		fmt.println("Failed to create topology")
		return result
	}

	result = source->CreatePresentationDescriptor(&pd)
	if win.FAILED(result) {
		fmt.println("Failed to create PresentationDescriptor")
		return result
	}

	streamCount:u32
	result = pd->GetStreamDescriptorCount(&streamCount)
	if win.FAILED(result) {
		fmt.println("Failed to create stream count")
		return result
	}

	for i in 0..<streamCount {
		selected:win.BOOL = win.FALSE
		sd:^mf.IMFStreamDescriptor

		result = pd->GetStreamDescriptorByIndex(i, &selected, &sd)
		if win.FAILED(result) {
		    fmt.printf("GetStreamDescriptorByIndex failed: 0x%X\n", result)
		    return result
		}
		if !selected {
			sd->Release()
			continue
		}

		srcNode:^mf.IMFTopologyNode
		outNode:^mf.IMFTopologyNode

		result = AddSourceNode(topology, source, pd, sd, &srcNode)
		if win.FAILED(result) {
			fmt.println("Failed to add source node")
			return result
		}
		result = AddOutputNode(topology, video_handle, sd, &outNode)
		if win.FAILED(result) {
			fmt.println("Failed to add output node")
			return result
		}
		result = srcNode->ConnectOutput(0, outNode, 0)
		if win.FAILED(result) {
			fmt.println("Failed to connect output node to source node")
			return result
		}

		srcNode->Release()
		outNode->Release()
		sd->Release()

	}

	ppTopology^ = topology
	pd->Release()

	return win.S_OK
}



// window size
// Callback function for handling events
window_event_proc :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	switch message {
		case win.WM_SIZE:
			win.OutputDebugStringW(win.L("WM_SIZE\n"))
		case win.WM_DESTROY:
			WindowInformation.running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:

		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					WindowInformation.running = false
			}

		case win.WM_CHAR:
			// The event for keyboard presses (like, w,a,s,d etc)
			switch(wParam) {
			}
		}

	return win.DefWindowProcW(window, message, wParam, lParam)
}

main :: proc() {

	/*Step 0: Initial COM/MediaFoundation*/
	result := win.CoInitializeEx(nil, .MULTITHREADED)
	if win.FAILED(result) {
		panic("Could not initialize COM API. Aborted application!")
	}

	result = mf.Startup(mf.VERSION, mf.STARTUP_FULL)
	if win.FAILED(result) {
		panic("Could not initialize Media Foundations API. Aborted application!")
	}

	/*Step 1: Create and display basic window | This is what the video will be rendered too*/

	WindowInformation = {
		size = {left = 0, top = 0, right = 1920, bottom = 1080},
		running = true
	}

	// Window Creation Start
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance
	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("MediaPlaybackClass"),
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &WindowInformation.size, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("Media Playback"),
		dwStyle = win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE | win.WS_SYSMENU,
		X = win.CW_USEDEFAULT,
		Y = win.CW_USEDEFAULT,
		nWidth = WindowInformation.size.right - WindowInformation.size.left,
		nHeight = WindowInformation.size.bottom - WindowInformation.size.top,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)

	/*Step 2: Create a media session*/
	media_session:^mf.IMFMediaSession
	result = mf.CreateMediaSession(nil, &media_session)
	if win.FAILED(result) {
		panic("Could not create media session. Aborted application!")
	}

	/*Step 3: Create media source*/

	media_source:^mf.IMFMediaSource
	result = CreateMediaSource("[PATH TO VIDEO HERE]", &media_source)
	if win.FAILED(result) {
		panic("Could not create media source. Aborted application!")
	}

	topology:^mf.IMFTopology
	result = CreatePlaybackTopology(media_source, window, &topology)
	if win.FAILED(result) {
		panic("Could not create Playback Topology. Aborted application!")
	}

	result = media_session->SetTopology(0, topology)
	if win.FAILED(result) {
		fmt.printf("SetTopology failed: 0x%08X\n", u32(result))
		panic("Could not set Topology. Aborted application!")
	}


	// message/event loop
	message:win.MSG
	for WindowInformation.running {
		// Using PeekMessageW and not GetMessageW
		// Peak does not wait for a message to arrive if there is not one
		// Whereas GetMessageW does
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}

		event:^mf.IMFMediaEventType
		result = media_session->GetEvent(mf.EVENT_FLAG_NO_WAIT, &event)

		if win.SUCCEEDED(result) {
			type:mf.MediaEventType
			event->GetType(&type)

			#partial switch (type) {
				case .SessionTopologyStatus:
					status:u32
					event->GetUINT32(&mf.EVENT_TOPOLOGY_STATUS, &status)

					if status == mf.TOPOSTATUS_READY {
						var:mf.PROPVARIANT
						// PropVariantInit -> Just sets the value of var to {}. Odin already does this by default
						// As such, no bindings for PropVariantInit
						media_session->Start(&mf.GUID_NULL, &var)
						mf.PropVariantClear(&var)
					}
				case .SessionEnded:
					media_session->Stop()
				case .SessionClosed:
					// Kill the window when the media session is done
					// Works for this example as it only plays the video and that's it
					WindowInformation.running = false
 			}

    		event->Release()
		}

	}

	media_session->Release()
	media_source->Release()
	topology->Release()
	mf.Shutdown()
	mf.CoUninitialize()
}