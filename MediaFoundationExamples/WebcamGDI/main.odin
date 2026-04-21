
package main

import "core:fmt"
import "core:mem"
import win "core:sys/windows"
import "base:runtime"
import mf "../"

// Globals
g_hwnd:       win.HWND
g_width:      u32
g_height:     u32
g_window_dc:  win.HDC
g_memory_dc:  win.HDC
g_dib:        win.HBITMAP
g_dib_old:    win.HBITMAP
g_dib_pixels: [^]u8
running:      bool = true

show_error :: proc(msg: string, hr: win.HRESULT) {
    buf := fmt.aprintf("%s\nHRESULT: 0x%08X", msg, u32(hr))
    win.MessageBoxW(g_hwnd, win.utf8_to_wstring(buf), "Error", win.MB_OK | win.MB_ICONERROR)
}

window_proc :: proc "stdcall" (
    hwnd:   win.HWND,
    msg:    win.UINT,
    wparam: win.WPARAM,
    lparam: win.LPARAM,
) -> win.LRESULT {
    context = runtime.default_context()
    switch msg {
    case win.WM_PAINT:
        ps: win.PAINTSTRUCT
        win.BeginPaint(hwnd, &ps)
        win.EndPaint(hwnd, &ps)
        return 0
    case win.WM_DESTROY:
        running = false
        win.PostQuitMessage(0)
        return 0
    case win.WM_KEYDOWN:
        if wparam == win.VK_ESCAPE {
            running = false
            win.PostQuitMessage(0)
        }
    }
    return win.DefWindowProcW(hwnd, msg, wparam, lparam)
}

init_gdi :: proc() -> bool {
    g_window_dc = win.GetDC(g_hwnd)
    if g_window_dc == nil {
        show_error("GetDC failed", 0)
        return false
    }

    g_memory_dc = win.CreateCompatibleDC(g_window_dc)
    if g_memory_dc == nil {
        show_error("CreateCompatibleDC failed", 0)
        return false
    }

    bmi := win.BITMAPINFO{
        bmiHeader = {
            biSize        = size_of(win.BITMAPINFOHEADER),
            biWidth       = i32(g_width),
            biHeight      = -i32(g_height),
            biPlanes      = 1,
            biBitCount    = 32,
            biCompression = win.BI_RGB,
        },
    }

    g_dib = win.CreateDIBSection(
        g_window_dc,
        &bmi,
        win.DIB_RGB_COLORS,
        cast(^rawptr)&g_dib_pixels,
        nil,
        0,
    )
    if g_dib == nil {
        show_error("CreateDIBSection failed", 0)
        return false
    }

    g_dib_old = win.HBITMAP(win.SelectObject(g_memory_dc, win.HGDIOBJ(g_dib)))
    return true
}

cleanup_gdi :: proc() {
    if g_dib_old   != nil do win.SelectObject(g_memory_dc, win.HGDIOBJ(g_dib_old))
    if g_dib       != nil do win.DeleteObject(win.HGDIOBJ(g_dib))
    if g_memory_dc != nil do win.DeleteDC(g_memory_dc)
    if g_window_dc != nil do win.ReleaseDC(g_hwnd, g_window_dc)
}

render_frame :: proc(camera_data: [^]u8, data_len: u32) {
    expected := g_width * g_height * 4
    if g_dib_pixels == nil || data_len < expected do return

    mem.copy(g_dib_pixels, camera_data, int(expected))

    win.BitBlt(
        g_window_dc,
        0, 0, i32(g_width), i32(g_height),
        g_memory_dc,
        0, 0,
        win.SRCCOPY,
    )
}

main :: proc() {
    hr := win.CoInitializeEx(nil, win.COINIT.MULTITHREADED)
    if hr < 0 {
        show_error("CoInitializeEx failed", hr)
        return
    }
    defer win.CoUninitialize()

    hr = mf.MFStartup(mf.MF_VERSION, mf.MFSTARTUP_FULL)
    if hr < 0 {
        show_error("MFStartup failed", hr)
        return
    }
    defer mf.MFShutdown()

    instance := win.HINSTANCE(win.GetModuleHandleW(nil))
    wc: win.WNDCLASSW
    wc.lpfnWndProc   = window_proc
    wc.hInstance     = instance
    wc.lpszClassName = win.L("GDICameraWindow")
    win.RegisterClassW(&wc)

    g_hwnd = win.CreateWindowExW(
        0,
        wc.lpszClassName,
        win.L("GDI Camera Preview"),
        win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, 800, 600,
        nil, nil, instance, nil,
    )
    if g_hwnd == nil {
        show_error("CreateWindowExW failed", 0)
        return
    }

    // Enumerate cameras
    attrs: ^mf.IMFAttributes
    hr = mf.MFCreateAttributes(&attrs, 1)
    if hr < 0 {
        show_error("MFCreateAttributes failed", hr)
        return
    }

    src_type_guid := mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE
    vidcap_guid   := mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID
    attrs->SetGUID(&src_type_guid, &vidcap_guid)

    devices: ^^mf.IMFActivate
    count:   u32
    hr = mf.MFEnumDeviceSources(attrs, &devices, &count)
    attrs->Release()
    if hr < 0 {
        show_error("MFEnumDeviceSources failed", hr)
        return
    }

    if count == 0 {
        win.MessageBoxW(g_hwnd, win.L("No camera found."), win.L("Error"), win.MB_OK)
        return
    }

    device_list := ([^]^mf.IMFActivate)(devices)

    // Activate camera source
    source: ^mf.IMFMediaSource
    hr = device_list[0]->ActivateObject(&mf.IID_IMFMediaSource, cast(^rawptr)&source)
    if hr < 0 {
        show_error("ActivateObject failed", hr)
        return
    }
    defer source->Release()

    // Create source reader with video processing enabled
    reader_attrs: ^mf.IMFAttributes
    hr = mf.MFCreateAttributes(&reader_attrs, 2)
    if hr < 0 {
        show_error("MFCreateAttributes for reader failed", hr)
        return
    }

    vp_guid := mf.MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING
    hr = reader_attrs->SetUINT32(&vp_guid, 1)
    if hr < 0 {
        show_error("SetUINT32 VIDEO_PROCESSING failed", hr)
        return
    }

    avp_guid := mf.MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING
    hr = reader_attrs->SetUINT32(&avp_guid, 1)
    if hr < 0 {
        show_error("SetUINT32 ADVANCED_VIDEO_PROCESSING failed", hr)
        return
    }

    reader: ^mf.IMFSourceReader
    hr = mf.MFCreateSourceReaderFromMediaSource(source, reader_attrs, &reader)
    reader_attrs->Release()
    if hr < 0 {
        show_error("MFCreateSourceReaderFromMediaSource failed", hr)
        return
    }
    defer reader->Release()

    // Request RGB32
    media_type: ^mf.IMFMediaType
    hr = mf.MFCreateMediaType(&media_type)
    if hr < 0 {
        show_error("MFCreateMediaType failed", hr)
        return
    }

    major_type_guid := mf.MF_MT_MAJOR_TYPE
    video_guid      := mf.MFMediaType_Video
    subtype_guid    := mf.MF_MT_SUBTYPE
    rgb32_guid      := mf.MFVideoFormat_RGB32

    media_type->SetGUID(&major_type_guid, &video_guid)
    media_type->SetGUID(&subtype_guid,    &rgb32_guid)

    hr = reader->SetCurrentMediaType(mf.MF_SOURCE_READER_FIRST_VIDEO_STREAM, nil, media_type)
    media_type->Release()
    if hr < 0 {
        show_error("SetCurrentMediaType failed", hr)
        return
    }

    // Get actual negotiated dimensions
    actual_type: ^mf.IMFMediaType
    hr = reader->GetCurrentMediaType(mf.MF_SOURCE_READER_FIRST_VIDEO_STREAM, &actual_type)
    if hr < 0 {
        show_error("GetCurrentMediaType failed", hr)
        return
    }

    frame_size_guid := mf.MF_MT_FRAME_SIZE
    frame_size: u64
    actual_type->GetUINT64(&frame_size_guid, &frame_size)
    actual_type->Release()

    g_width  = u32(frame_size >> 32)
    g_height = u32(frame_size & 0xFFFFFFFF)
    if g_width == 0 || g_height == 0 {
        g_width  = 640
        g_height = 480
    }

    win.SetWindowPos(g_hwnd, nil, 0, 0, i32(g_width), i32(g_height),
                     win.SWP_NOMOVE | win.SWP_NOZORDER)

    if !init_gdi() do return
    defer cleanup_gdi()

    hr = reader->SetStreamSelection(mf.MF_SOURCE_READER_FIRST_VIDEO_STREAM, true)
    if hr < 0 {
        show_error("SetStreamSelection failed", hr)
        return
    }

    // Main loop
    msg: win.MSG
    for running {
        for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
            win.TranslateMessage(&msg)
            win.DispatchMessageW(&msg)
        }
        if msg.message == win.WM_QUIT do break

        sample:       ^mf.IMFSample
        stream_index: u32
        flags:        u32
        timestamp:    i64

        hr = reader->ReadSample(
            mf.MF_SOURCE_READER_FIRST_VIDEO_STREAM,
            0,
            &stream_index,
            &flags,
            &timestamp,
            &sample,
        )

        if hr < 0 {
            show_error("ReadSample failed", hr)
            break
        }
        if flags & mf.MF_SOURCE_READERF_ENDOFSTREAM != 0 do break
        if flags & mf.MF_SOURCE_READERF_ERROR        != 0 do continue
        if sample == nil do continue

        buffer: ^mf.IMFMediaBuffer
        hr = sample->ConvertToContiguousBuffer(&buffer)
        if hr < 0 {
            sample->Release()
            continue
        }

        data:    [^]u8
        max_len: u32
        cur_len: u32
        hr = buffer->Lock(&data, &max_len, &cur_len)
        if hr >= 0 {
            render_frame(data, cur_len)
            buffer->Unlock()
        }

        buffer->Release()
        sample->Release()
    }

    // Free device list
    for i in 0..<count {
        device_list[i]->Release()
    }
    win.CoTaskMemFree(rawptr(devices))
}


// package webcam


// import mf "../"

// import "core:fmt"
// import win "core:sys/windows"
// import "base:runtime"

// import d3d11 "vendor:directx/d3d11"
// import dxgi  "vendor:directx/dxgi"
// import d3d   "vendor:directx/d3d_compiler"


// // Globals
// running := true
// rect: win.RECT = {left = 0, top = 0, right = 800, bottom = 600}
// window: win.HWND

// // GDI Globals
// device_context:        win.HDC
// memory_device_context: win.HDC
// back_buffer:           win.HBITMAP
// back_buffer_old:       win.HBITMAP

// init_gdi :: proc() {
//     device_context = win.GetDC(window)

//     // Create a memory DC compatible with the window DC
//     memory_device_context = win.CreateCompatibleDC(device_context)

//     // Create a bitmap for the back buffer
//     back_buffer = win.CreateCompatibleBitmap(
//         device_context,
//         rect.right  - rect.left,
//         rect.bottom - rect.top,
//     )

//     // Select the bitmap into the memory DC, saving the old one
//     back_buffer_old = win.HBITMAP(win.SelectObject(memory_device_context, win.HGDIOBJ(back_buffer)))
// }

// resize_gdi :: proc(width, height: i32) {
//     // Clean up old back buffer
//     win.SelectObject(memory_device_context, win.HGDIOBJ(back_buffer_old))
//     win.DeleteObject(win.HGDIOBJ(back_buffer))

//     // Recreate at new size
//     back_buffer = win.CreateCompatibleBitmap(device_context, width, height)
//     back_buffer_old = win.HBITMAP(win.SelectObject(memory_device_context, win.HGDIOBJ(back_buffer)))

//     rect.right  = rect.left + width
//     rect.bottom = rect.top  + height
// }

// cleanup_gdi :: proc() {
//     win.SelectObject(memory_device_context, win.HGDIOBJ(back_buffer_old))
//     win.DeleteObject(win.HGDIOBJ(back_buffer))
//     win.DeleteDC(memory_device_context)
//     win.ReleaseDC(window, device_context)
// }

// render :: proc() {
//     width  := rect.right  - rect.left
//     height := rect.bottom - rect.top

//     // --- Draw to back buffer (memory DC) ---

//     // Clear background to black
//     win.PatBlt(memory_device_context, 0, 0, width, height, win.BLACKNESS)

//     // Example: draw a filled white rectangle in the center
//     box_w : i32 = 100
//     box_h : i32 = 100
//     box_x := (width  - box_w) / 2
//     box_y := (height - box_h) / 2
//     brush := win.CreateSolidBrush(0x00FFFFFF) // white
//     box_rect := win.RECT{ box_x, box_y, box_x + box_w, box_y + box_h }
//     win.FillRect(memory_device_context, &box_rect, brush)
//     win.DeleteObject(win.HGDIOBJ(brush))

//     // --- Blit back buffer to screen ---
//     win.BitBlt(
//         device_context,
//         0, 0, width, height,
//         memory_device_context,
//         0, 0,
//         win.SRCCOPY,
//     )
// }

// window_event_proc :: proc "stdcall" (
//     window: win.HWND,
//     message: win.UINT,
//     wParam: win.WPARAM,
//     lParam: win.LPARAM,
// ) -> win.LRESULT {
//     context = runtime.default_context()
//     switch message {
//     case win.WM_SIZE:
//         if memory_device_context != nil {
//             new_width  := i32(win.LOWORD(cast(win.DWORD)lParam))
//             new_height := i32(win.HIWORD(cast(win.DWORD)lParam))
//             if new_width > 0 && new_height > 0 {
//                 resize_gdi(new_width, new_height)
//             }
//         }
//     case win.WM_PAINT:
//         ps: win.PAINTSTRUCT
//         win.BeginPaint(window, &ps)
//         // Painting is handled in render(), just validate the region
//         win.EndPaint(window, &ps)
//     case win.WM_DESTROY:
//         running = false
//     case win.WM_KEYDOWN:
//         switch wParam {
//         case win.VK_ESCAPE:
//             running = false
//         }
//     }
//     return win.DefWindowProcW(window, message, wParam, lParam)
// }

// main :: proc() {

//     // Setting up COM
//     mf.CoInitializeEx(nil, mf.COINIT_MULTITHREADED)
//     mf.MFStartup(mf.MF_VERSION, mf.MFSTARTUP_FULL)

//     // Setting up Window
//     instance := win.HINSTANCE(win.GetModuleHandleW(nil))

//     window_class := win.WNDCLASSW{
//         style         = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
//         lpfnWndProc   = window_event_proc,
//         hInstance     = instance,
//         lpszClassName = win.L("GDIWindowClass"),
//     }
//     win.RegisterClassW(lpWndClass = &window_class)
//     win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE)

//     window = win.CreateWindowExW(
//         dwExStyle    = 0,
//         lpClassName  = window_class.lpszClassName,
//         lpWindowName = win.L("GDI Window"),
//         dwStyle      = win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE | win.WS_SYSMENU,
//         X            = win.CW_USEDEFAULT,
//         Y            = win.CW_USEDEFAULT,
//         nWidth       = rect.right  - rect.left,
//         nHeight      = rect.bottom - rect.top,
//         hWndParent   = nil,
//         hMenu        = nil,
//         hInstance    = instance,
//         lpParam      = nil,
//     )

//     // Enumerate cameras
//     attrs:^mf.IMFAttributes
//     devices:^^mf.IMFActivate
//     count:win.UINT32

//     mf.MFCreateAttributes(&attrs, 1)
//     // attrs.SetGUID(attrs,mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE^, mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID^)
//     attrs->SetGUID(mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE^, mf.MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID^)
//     mf.MFEnumDeviceSources(attrs, &devices, &count)
//     attrs.Release(attrs)

//     source:mf.IMFMediaSource
//     devices[0].ActivateObject(devices[0], &mf.IID_IMFMediaSource, cast(^rawptr)&source)
//     // devices.ActivateObject(devices, )

//     // Setting up GDI 
//     init_gdi()
//     defer cleanup_gdi()


//     message: win.MSG
//     for running {
//         if win.PeekMessageW(
//             lpMsg         = &message,
//             hWnd          = nil,
//             wMsgFilterMin = 0,
//             wMsgFilterMax = 0,
//             wRemoveMsg    = win.PM_REMOVE,
//         ) {
//             win.TranslateMessage(lpMsg = &message)
//             win.DispatchMessageW(lpMsg = &message)
//         }

//         render()
//     }
// }
