package webcam

import "core:fmt"
import "core:mem"
import win "core:sys/windows"
import "base:runtime"
import mf "../"
import d3d11 "vendor:directx/d3d11"
import dxgi  "vendor:directx/dxgi"
import d3dc  "vendor:directx/d3d_compiler"

// Globals
g_hwnd:              win.HWND
g_width:             u32
g_height:            u32
running:             bool = true

// D3D11 globals
g_device:            ^d3d11.IDevice
g_ctx:               ^d3d11.IDeviceContext
g_swapchain:         ^dxgi.ISwapChain
g_rtv:               ^d3d11.IRenderTargetView
g_texture:           ^d3d11.ITexture2D
g_texture_srv:       ^d3d11.IShaderResourceView
g_sampler:           ^d3d11.ISamplerState
g_vs:                ^d3d11.IVertexShader
g_ps:                ^d3d11.IPixelShader
g_input_layout:      ^d3d11.IInputLayout
g_vertex_buffer:     ^d3d11.IBuffer

// Fullscreen quad shader -- no vertex buffer needed, positions generated in VS


SHADER_SRC :: `
struct VS_OUT {
    float4 pos : SV_POSITION;
    float2 uv  : TEXCOORD;
};

VS_OUT vs_main(uint id : SV_VertexID) {
    VS_OUT o;
    o.uv  = float2((id << 1) & 2, id & 2);
    o.pos = float4(o.uv * float2(2, -2) + float2(-1, 1), 0, 1);
    return o;
}

Texture2D    tex  : register(t0);
SamplerState samp : register(s0);

float4 ps_main(VS_OUT i) : SV_TARGET {
    return tex.Sample(samp, i.uv);
}
`

show_error :: proc(msg: string, hr: win.HRESULT) {
    buf := fmt.aprintf("%s\nHRESULT: 0x%08X", msg, u32(hr))
    win.MessageBoxW(g_hwnd, win.utf8_to_wstring(buf), win.L("Error"), win.MB_OK | win.MB_ICONERROR)
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

init_d3d11 :: proc() -> bool {
    // Create device and swap chain
    sc_desc := dxgi.SWAP_CHAIN_DESC{
        BufferCount = 2,
        BufferDesc  = {
            Width            = g_width,
            Height           = g_height,
            Format           = .B8G8R8A8_UNORM,
            RefreshRate      = {Numerator = 60, Denominator = 1},
        },
        BufferUsage  = {.RENDER_TARGET_OUTPUT},
        OutputWindow = dxgi.HWND(g_hwnd),
        SampleDesc   = {Count = 1, Quality = 0},
        Windowed     = true,
        SwapEffect   = .DISCARD,
    }

    feature_level := d3d11.FEATURE_LEVEL._11_0
    hr := d3d11.CreateDeviceAndSwapChain(
        nil,
        .HARDWARE,
        nil,
        {.SINGLETHREADED},
        &feature_level, 1,
        d3d11.SDK_VERSION,
        &sc_desc,
        &g_swapchain,
        &g_device,
        nil,
        &g_ctx,
    )
    if hr < 0 {
        show_error("CreateDeviceAndSwapChain failed", hr)
        return false
    }

    // Render target view
    back_buffer: ^d3d11.ITexture2D
    g_swapchain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr)&back_buffer)
    g_device->CreateRenderTargetView(back_buffer, nil, &g_rtv)
    back_buffer->Release()

    // Camera frame texture (CPU write, GPU read)


    tex_desc := d3d11.TEXTURE2D_DESC{
        Width          = g_width,
        Height         = g_height,
        MipLevels      = 1,
        ArraySize      = 1,
        Format         = .B8G8R8X8_UNORM,  // matches what MF actually outputs
        SampleDesc     = {Count = 1},
        Usage          = .DYNAMIC,
        BindFlags      = {.SHADER_RESOURCE},
        CPUAccessFlags = {.WRITE},
    }

    hr = g_device->CreateTexture2D(&tex_desc, nil, &g_texture)
    if hr < 0 {
        show_error("CreateTexture2D failed", hr)
        return false
    }

    // Shader resource view for the texture
    hr = g_device->CreateShaderResourceView(g_texture, nil, &g_texture_srv)
    if hr < 0 {
        show_error("CreateShaderResourceView failed", hr)
        return false
    }

    // Sampler
    samp_desc := d3d11.SAMPLER_DESC{
        Filter         = .MIN_MAG_MIP_LINEAR,
        AddressU       = .CLAMP,
        AddressV       = .CLAMP,
        AddressW       = .CLAMP,
        ComparisonFunc = .NEVER,
        MaxLOD         = d3d11.FLOAT32_MAX,
    }
    hr = g_device->CreateSamplerState(&samp_desc, &g_sampler)
    if hr < 0 {
        show_error("CreateSamplerState failed", hr)
        return false
    }

    // Compile and create vertex shader
    vs_blob: ^d3d11.IBlob
    err_blob: ^d3d11.IBlob
    hr = d3dc.Compile(
        raw_data(transmute([]byte)string(SHADER_SRC)),
        len(SHADER_SRC),
        "shader",
        nil, nil,
        "vs_main", "vs_5_0",
        0, 0,
        &vs_blob,
        &err_blob,
    )
    if hr < 0 {
        if err_blob != nil {
            msg := string(cstring(err_blob->GetBufferPointer()))
            win.MessageBoxW(g_hwnd, win.utf8_to_wstring(msg), "VS compile error", win.MB_OK)
            err_blob->Release()
            
        }
        return false
    }

    hr = g_device->CreateVertexShader(
        vs_blob->GetBufferPointer(),
        vs_blob->GetBufferSize(),
        nil,
        &g_vs,
    )
    vs_blob->Release()
    if hr < 0 {
        show_error("CreateVertexShader failed", hr)
        return false
    }

    // Compile and create pixel shader
    ps_blob: ^d3d11.IBlob
    hr = d3dc.Compile(
        raw_data(transmute([]byte)string(SHADER_SRC)),
        len(SHADER_SRC),
        "shader",
        nil, nil,
        "ps_main", "ps_5_0",
        0, 0,
        &ps_blob,
        &err_blob,
    )
    if hr < 0 {
        if err_blob != nil {
            msg := string(cstring(err_blob->GetBufferPointer()))
            win.MessageBoxW(g_hwnd, win.utf8_to_wstring(msg), win.L("VS compile error"), win.MB_OK)
            err_blob->Release()
            
        }
        return false
    }

    hr = g_device->CreatePixelShader(
        ps_blob->GetBufferPointer(),
        ps_blob->GetBufferSize(),
        nil,
        &g_ps,
    )
    ps_blob->Release()
    if hr < 0 {
        show_error("CreatePixelShader failed", hr)
        return false
    }

    return true
}

cleanup_d3d11 :: proc() {
    if g_sampler     != nil do g_sampler->Release()
    if g_texture_srv != nil do g_texture_srv->Release()
    if g_texture     != nil do g_texture->Release()
    if g_ps          != nil do g_ps->Release()
    if g_vs          != nil do g_vs->Release()
    if g_rtv         != nil do g_rtv->Release()
    if g_swapchain   != nil do g_swapchain->Release()
    if g_ctx         != nil do g_ctx->Release()
    if g_device      != nil do g_device->Release()
}

render_frame :: proc(camera_data: [^]u8, data_len: u32) {
    expected := g_width * g_height * 4
    if data_len < expected do return

    // Upload camera frame into the dynamic texture
    mapped: d3d11.MAPPED_SUBRESOURCE
    hr := g_ctx->Map(g_texture, 0, .WRITE_DISCARD, {}, &mapped)
    if hr < 0 do return
    defer g_ctx->Unmap(g_texture, 0)

    // Copy row by row in case pitch differs
    src_row  := camera_data
    dst_row  := cast([^]u8)mapped.pData
    row_size := g_width * 4
    for y in 0..<g_height {
        mem.copy(dst_row, src_row, int(row_size))
        src_row  = src_row[row_size:]
        dst_row  = dst_row[mapped.RowPitch:]
    }

    // Set up pipeline for fullscreen quad
    vp := d3d11.VIEWPORT{
        Width    = f32(g_width),
        Height   = f32(g_height),
        MaxDepth = 1,
    }
    g_ctx->RSSetViewports(1, &vp)
    g_ctx->OMSetRenderTargets(1, &g_rtv, nil)

    clear_color := [4]f32{0, 0, 0, 1}
    g_ctx->ClearRenderTargetView(g_rtv, &clear_color)

    g_ctx->VSSetShader(g_vs, nil, 0)
    g_ctx->PSSetShader(g_ps, nil, 0)
    g_ctx->PSSetShaderResources(0, 1, &g_texture_srv)
    g_ctx->PSSetSamplers(0, 1, &g_sampler)
    g_ctx->IASetPrimitiveTopology(.TRIANGLELIST)
    g_ctx->IASetInputLayout(nil)

    // 3 vertices, no vertex buffer -- positions generated in VS from SV_VertexID
    g_ctx->Draw(3, 0)

    g_swapchain->Present(1, {})
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
    wc.lpszClassName = win.L("D3D11CameraWindow")
    win.RegisterClassW(&wc)

    g_hwnd = win.CreateWindowExW(
        0,
        wc.lpszClassName,
        win.L("D3D11 Camera Preview"),
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

    source: ^mf.IMFMediaSource
    hr = device_list[0]->ActivateObject(&mf.IID_IMFMediaSource, cast(^rawptr)&source)
    if hr < 0 {
        show_error("ActivateObject failed", hr)
        return
    }
    defer source->Release()

    reader_attrs: ^mf.IMFAttributes
    hr = mf.MFCreateAttributes(&reader_attrs, 2)
    if hr < 0 {
        show_error("MFCreateAttributes for reader failed", hr)
        return
    }

    vp_guid := mf.MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING
    reader_attrs->SetUINT32(&vp_guid, 1)

    avp_guid := mf.MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING
    reader_attrs->SetUINT32(&avp_guid, 1)

    reader: ^mf.IMFSourceReader
    hr = mf.MFCreateSourceReaderFromMediaSource(source, reader_attrs, &reader)
    reader_attrs->Release()
    if hr < 0 {
        show_error("MFCreateSourceReaderFromMediaSource failed", hr)
        return
    }
    defer reader->Release()

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

    if !init_d3d11() do return
    defer cleanup_d3d11()

    hr = reader->SetStreamSelection(mf.MF_SOURCE_READER_FIRST_VIDEO_STREAM, true)
    if hr < 0 {
        show_error("SetStreamSelection failed", hr)
        return
    }

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

    for i in 0..<count {
        device_list[i]->Release()
    }
    win.CoTaskMemFree(rawptr(devices))
}
