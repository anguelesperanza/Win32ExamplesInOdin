
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

    hr = mf.Startup(mf.VERSION, mf.STARTUP_FULL)
    if hr < 0 {
        show_error("Startup failed", hr)
        return
    }
    defer mf.Shutdown()

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
    hr = mf.CreateAttributes(&attrs, 1)
    if hr < 0 {
        show_error("CreateAttributes failed", hr)
        return
    }

    src_type_guid := mf.DEVSOURCE_ATTRIBUTE_SOURCE_TYPE
    vidcap_guid   := mf.DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID
    attrs->SetGUID(&src_type_guid, &vidcap_guid)

    devices: ^^mf.IMFActivate
    count:   u32
    hr = mf.EnumDeviceSources(attrs, &devices, &count)
    attrs->Release()
    if hr < 0 {
        show_error("EnumDeviceSources failed", hr)
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
    hr = mf.CreateAttributes(&reader_attrs, 2)
    if hr < 0 {
        show_error("CreateAttributes for reader failed", hr)
        return
    }

    vp_guid := mf.SOURCE_READER_ENABLE_VIDEO_PROCESSING
    hr = reader_attrs->SetUINT32(&vp_guid, 1)
    if hr < 0 {
        show_error("SetUINT32 VIDEO_PROCESSING failed", hr)
        return
    }

    avp_guid := mf.SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING
    hr = reader_attrs->SetUINT32(&avp_guid, 1)
    if hr < 0 {
        show_error("SetUINT32 ADVANCED_VIDEO_PROCESSING failed", hr)
        return
    }

    reader: ^mf.IMFSourceReader
    hr = mf.CreateSourceReaderFromMediaSource(source, reader_attrs, &reader)
    reader_attrs->Release()
    if hr < 0 {
        show_error("CreateSourceReaderFromMediaSource failed", hr)
        return
    }
    defer reader->Release()

    // Request RGB32
    media_type: ^mf.IMFMediaType
    hr = mf.CreateMediaType(&media_type)
    if hr < 0 {
        show_error("CreateMediaType failed", hr)
        return
    }

    major_type_guid := mf.MT_MAJOR_TYPE
    video_guid      := mf.MediaType_Video
    subtype_guid    := mf.MT_SUBTYPE
    rgb32_guid      := mf.VideoFormat_RGB32

    media_type->SetGUID(&major_type_guid, &video_guid)
    media_type->SetGUID(&subtype_guid,    &rgb32_guid)

    hr = reader->SetCurrentMediaType(mf.SOURCE_READER_FIRST_VIDEO_STREAM, nil, media_type)
    media_type->Release()
    if hr < 0 {
        show_error("SetCurrentMediaType failed", hr)
        return
    }

    // Get actual negotiated dimensions
    actual_type: ^mf.IMFMediaType
    hr = reader->GetCurrentMediaType(mf.SOURCE_READER_FIRST_VIDEO_STREAM, &actual_type)
    if hr < 0 {
        show_error("GetCurrentMediaType failed", hr)
        return
    }

    frame_size_guid := mf.MT_FRAME_SIZE
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

    hr = reader->SetStreamSelection(mf.SOURCE_READER_FIRST_VIDEO_STREAM, true)
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
            mf.SOURCE_READER_FIRST_VIDEO_STREAM,
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
        if flags & mf.SOURCE_READERF_ENDOFSTREAM != 0 do break
        if flags & mf.SOURCE_READERF_ERROR        != 0 do continue
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
