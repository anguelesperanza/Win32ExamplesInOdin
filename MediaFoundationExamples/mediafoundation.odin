package mf

import win "core:sys/windows"

HRESULT :: win.HRESULT
GUID    :: win.GUID
BOOL    :: win.BOOL
DWORD   :: win.DWORD
LPVOID  :: win.LPVOID

// -------------------------------------------------------------------------
// Foreign libs
// -------------------------------------------------------------------------

foreign import mfplat    "system:mfplat.lib"
foreign import mf        "system:mf.lib"
foreign import mfreadwrite "system:mfreadwrite.lib"
foreign import mfuuid    "system:mfuuid.lib"
foreign import ole32     "system:ole32.lib"

// -------------------------------------------------------------------------
// Constants
// -------------------------------------------------------------------------

MF_VERSION                        :: 0x00020070
MFSTARTUP_FULL                    :: 0x3
MF_SOURCE_READER_FIRST_VIDEO_STREAM : u32 : 0xFFFFFFFC
MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING_STRING :: "9C3C3BEA-6EAF-4C8B-8DC7-D3A2D1CD53A1"
MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING : GUID = {
    0x9C3C3BEA, 0x6EAF, 0x4C8B,
    {0x8D, 0xC7, 0xD3, 0xA2, 0xD1, 0xCD, 0x53, 0xA1},
}


MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING : GUID = {
    0x0F81DA2C, 0xB537, 0x4672,
    {0xA8, 0xB2, 0xA6, 0x81, 0xB1, 0x73, 0x07, 0xA3},
}
// Source reader flags
MF_SOURCE_READERF_ERROR          :: 0x00000001
MF_SOURCE_READERF_ENDOFSTREAM    :: 0x00000002
MF_SOURCE_READERF_STREAMTICK     :: 0x00000100

// CoInitializeEx values
COINIT_MULTITHREADED :: 0x0

// -------------------------------------------------------------------------
// GUIDs for media types
// -------------------------------------------------------------------------

MFMediaType_Video : GUID = {
    0x73646976, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}

MFVideoFormat_RGB32 : GUID = {
    0x00000016, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}

MFVideoFormat_MJPG : GUID = {
    0x47504A4D, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}

MFVideoFormat_YUY2 : GUID = {
    0x32595559, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}

// -------------------------------------------------------------------------
// GUIDs for attributes
// -------------------------------------------------------------------------

MF_MT_MAJOR_TYPE : GUID = {
    0x48eba18e, 0xf8c9, 0x4687,
    {0xbf, 0x11, 0x0a, 0x74, 0xc9, 0xf9, 0x6a, 0x8f},
}

MF_MT_SUBTYPE : GUID = {
    0xf7e34c9a, 0x42e8, 0x4714,
    {0xb7, 0x4b, 0xcb, 0x29, 0xd7, 0x2c, 0x35, 0xe5},
}

MF_MT_FRAME_SIZE : GUID = {
    0x1652c33d, 0xd6b2, 0x4012,
    {0xb8, 0x34, 0x72, 0x03, 0x08, 0x49, 0xa3, 0x7d},
}

MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE : GUID = {
    0xc60ac5fe, 0x252a, 0x478f,
    {0xa0, 0xef, 0xbc, 0x8f, 0xa5, 0xf7, 0xca, 0xd3},
}

MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID : GUID = {
    0x8ac3587a, 0x4ae7, 0x42d8,
    {0x99, 0xe0, 0x0a, 0x60, 0x13, 0xee, 0xf9, 0x0f},
}

// IID for IMFMediaSource
IID_IMFMediaSource : GUID = {
    0x279a808d, 0xaec7, 0x40c8,
    {0x9c, 0x6b, 0xa6, 0xb4, 0x92, 0xc7, 0x8a, 0x66},
}

// -------------------------------------------------------------------------
// IUnknown (base for all COM interfaces)
// -------------------------------------------------------------------------

IUnknown :: struct #raw_union {
    #subtype iunknown_vtable: ^IUnknown_VTable,
}
IUnknown_VTable :: struct {
    QueryInterface: proc "system" (this: ^IUnknown, riid: ^GUID, ppvObject: ^rawptr) -> HRESULT,
    AddRef:         proc "system" (this: ^IUnknown) -> u32,
    Release:        proc "system" (this: ^IUnknown) -> u32,
}

// -------------------------------------------------------------------------
// IMFAttributes
// -------------------------------------------------------------------------

IMFAttributes :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfattributes_vtable: ^IMFAttributes_VTable,
}
IMFAttributes_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetItem:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pValue: rawptr) -> HRESULT,
    GetItemType:        proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pType: ^u32) -> HRESULT,
    CompareItem:        proc "system" (this: ^IMFAttributes, guidKey: ^GUID, Value: rawptr, pbResult: ^BOOL) -> HRESULT,
    Compare:            proc "system" (this: ^IMFAttributes, pTheirs: ^IMFAttributes, MatchType: u32, pbResult: ^BOOL) -> HRESULT,
    GetUINT32:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, punValue: ^u32) -> HRESULT,
    GetUINT64:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, punValue: ^u64) -> HRESULT,
    GetDouble:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pfValue: ^f64) -> HRESULT,
    GetGUID:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pguidValue: ^GUID) -> HRESULT,
    GetStringLength:    proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pcchLength: ^u32) -> HRESULT,
    GetString:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pwszValue: [^]u16, cchBufSize: u32, pcchLength: ^u32) -> HRESULT,
    GetAllocatedString: proc "system" (this: ^IMFAttributes, guidKey: ^GUID, ppwszValue: ^[^]u16, pcchLength: ^u32) -> HRESULT,
    GetBlobSize:        proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pcbBlobSize: ^u32) -> HRESULT,
    GetBlob:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pBuf: [^]u8, cbBufSize: u32, pcbBlobSize: ^u32) -> HRESULT,
    GetAllocatedBlob:   proc "system" (this: ^IMFAttributes, guidKey: ^GUID, ppBuf: ^[^]u8, pcbSize: ^u32) -> HRESULT,
    GetUnknown:         proc "system" (this: ^IMFAttributes, guidKey: ^GUID, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
    SetItem:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, Value: rawptr) -> HRESULT,
    DeleteItem:         proc "system" (this: ^IMFAttributes, guidKey: ^GUID) -> HRESULT,
    DeleteAllItems:     proc "system" (this: ^IMFAttributes) -> HRESULT,
    SetUINT32:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, unValue: u32) -> HRESULT,
    SetUINT64:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, unValue: u64) -> HRESULT,
    SetDouble:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, fValue: f64) -> HRESULT,
    SetGUID:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, guidValue: ^GUID) -> HRESULT,
    SetString:          proc "system" (this: ^IMFAttributes, guidKey: ^GUID, wszValue: [^]u16) -> HRESULT,
    SetBlob:            proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pBuf: [^]u8, cbBufSize: u32) -> HRESULT,
    SetUnknown:         proc "system" (this: ^IMFAttributes, guidKey: ^GUID, pUnknown: ^IUnknown) -> HRESULT,
    LockStore:          proc "system" (this: ^IMFAttributes) -> HRESULT,
    UnlockStore:        proc "system" (this: ^IMFAttributes) -> HRESULT,
    GetCount:           proc "system" (this: ^IMFAttributes, pcItems: ^u32) -> HRESULT,
    GetItemByIndex:     proc "system" (this: ^IMFAttributes, unIndex: u32, pguidKey: ^GUID, pValue: rawptr) -> HRESULT,
    CopyAllItems:       proc "system" (this: ^IMFAttributes, pDest: ^IMFAttributes) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFActivate
// -------------------------------------------------------------------------

IMFActivate :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfactivate_vtable: ^IMFActivate_VTable,
}
IMFActivate_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    ActivateObject:  proc "system" (this: ^IMFActivate, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
    ShutdownObject:  proc "system" (this: ^IMFActivate) -> HRESULT,
    DetachObject:    proc "system" (this: ^IMFActivate) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaType
// -------------------------------------------------------------------------

IMFMediaType :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfmediatype_vtable: ^IMFMediaType_VTable,
}
IMFMediaType_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetMajorType:          proc "system" (this: ^IMFMediaType, pguidMajorType: ^GUID) -> HRESULT,
    IsCompressedFormat:    proc "system" (this: ^IMFMediaType, pfCompressed: ^BOOL) -> HRESULT,
    IsEqual:               proc "system" (this: ^IMFMediaType, pIMediaType: ^IMFMediaType, pdwFlags: ^u32) -> HRESULT,
    GetRepresentation:     proc "system" (this: ^IMFMediaType, guidRepresentation: GUID, ppvRepresentation: ^rawptr) -> HRESULT,
    FreeRepresentation:    proc "system" (this: ^IMFMediaType, guidRepresentation: GUID, pvRepresentation: rawptr) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaBuffer
// -------------------------------------------------------------------------

IMFMediaBuffer :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediabuffer_vtable: ^IMFMediaBuffer_VTable,
}
IMFMediaBuffer_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    Lock:           proc "system" (this: ^IMFMediaBuffer, ppbBuffer: ^[^]u8, pcbMaxLength: ^u32, pcbCurrentLength: ^u32) -> HRESULT,
    Unlock:         proc "system" (this: ^IMFMediaBuffer) -> HRESULT,
    GetCurrentLength: proc "system" (this: ^IMFMediaBuffer, pcbCurrentLength: ^u32) -> HRESULT,
    SetCurrentLength: proc "system" (this: ^IMFMediaBuffer, cbCurrentLength: u32) -> HRESULT,
    GetMaxLength:   proc "system" (this: ^IMFMediaBuffer, pcbMaxLength: ^u32) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFSample
// -------------------------------------------------------------------------

IMFSample :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfsample_vtable: ^IMFSample_VTable,
}
IMFSample_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetSampleFlags:             proc "system" (this: ^IMFSample, pdwSampleFlags: ^u32) -> HRESULT,
    SetSampleFlags:             proc "system" (this: ^IMFSample, dwSampleFlags: u32) -> HRESULT,
    GetSampleTime:              proc "system" (this: ^IMFSample, phnsSampleTime: ^i64) -> HRESULT,
    SetSampleTime:              proc "system" (this: ^IMFSample, hnsSampleTime: i64) -> HRESULT,
    GetSampleDuration:          proc "system" (this: ^IMFSample, phnsSampleDuration: ^i64) -> HRESULT,
    SetSampleDuration:          proc "system" (this: ^IMFSample, hnsSampleDuration: i64) -> HRESULT,
    GetBufferCount:             proc "system" (this: ^IMFSample, pdwBufferCount: ^u32) -> HRESULT,
    GetBufferByIndex:           proc "system" (this: ^IMFSample, dwIndex: u32, ppBuffer: ^^IMFMediaBuffer) -> HRESULT,
    ConvertToContiguousBuffer:  proc "system" (this: ^IMFSample, ppBuffer: ^^IMFMediaBuffer) -> HRESULT,
    AddBuffer:                  proc "system" (this: ^IMFSample, pBuffer: ^IMFMediaBuffer) -> HRESULT,
    RemoveBufferByIndex:        proc "system" (this: ^IMFSample, dwIndex: u32) -> HRESULT,
    RemoveAllBuffers:           proc "system" (this: ^IMFSample) -> HRESULT,
    GetTotalLength:             proc "system" (this: ^IMFSample, pcbTotalLength: ^u32) -> HRESULT,
    CopyToBuffer:               proc "system" (this: ^IMFSample, pBuffer: ^IMFMediaBuffer) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaSource
// -------------------------------------------------------------------------

IMFMediaSource :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediasource_vtable: ^IMFMediaSource_VTable,
}
IMFMediaSource_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetEvent:           proc "system" (this: ^IMFMediaSource, dwFlags: u32, ppEvent: ^rawptr) -> HRESULT,
    BeginGetEvent:      proc "system" (this: ^IMFMediaSource, pCallback: rawptr, punkState: ^IUnknown) -> HRESULT,
    EndGetEvent:        proc "system" (this: ^IMFMediaSource, pResult: rawptr, ppEvent: ^rawptr) -> HRESULT,
    QueueEvent:         proc "system" (this: ^IMFMediaSource, met: u32, guidExtendedType: ^GUID, hrStatus: HRESULT, pvValue: rawptr) -> HRESULT,
    GetCharacteristics: proc "system" (this: ^IMFMediaSource, pdwCharacteristics: ^u32) -> HRESULT,
    CreatePresentationDescriptor: proc "system" (this: ^IMFMediaSource, ppPresentationDescriptor: ^rawptr) -> HRESULT,
    Start:              proc "system" (this: ^IMFMediaSource, pPresentationDescriptor: rawptr, pguidTimeFormat: ^GUID, pvarStartPosition: rawptr) -> HRESULT,
    Stop:               proc "system" (this: ^IMFMediaSource) -> HRESULT,
    Pause:              proc "system" (this: ^IMFMediaSource) -> HRESULT,
    Shutdown:           proc "system" (this: ^IMFMediaSource) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFSourceReader
// -------------------------------------------------------------------------

IMFSourceReader :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfsourcereader_vtable: ^IMFSourceReader_VTable,
}
IMFSourceReader_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetStreamSelection:     proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, pfSelected: ^BOOL) -> HRESULT,
    SetStreamSelection:     proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, fSelected: BOOL) -> HRESULT,
    GetNativeMediaType:     proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, dwMediaTypeIndex: u32, ppMediaType: ^^IMFMediaType) -> HRESULT,
    GetCurrentMediaType:    proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, ppMediaType: ^^IMFMediaType) -> HRESULT,
    SetCurrentMediaType:    proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, pdwReserved: ^u32, pMediaType: ^IMFMediaType) -> HRESULT,
    SetCurrentPosition:     proc "system" (this: ^IMFSourceReader, guidTimeFormat: ^GUID, varPosition: rawptr) -> HRESULT,
    ReadSample:             proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, dwControlFlags: u32, pdwActualStreamIndex: ^u32, pdwStreamFlags: ^u32, pllTimestamp: ^i64, ppSample: ^^IMFSample) -> HRESULT,
    Flush:                  proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32) -> HRESULT,
    GetServiceForStream:    proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, guidService: ^GUID, riid: ^GUID, ppvObject: ^rawptr) -> HRESULT,
    GetPresentationAttribute: proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, guidAttribute: ^GUID, pvarAttribute: rawptr) -> HRESULT,
}

// -------------------------------------------------------------------------
// Free functions
// -------------------------------------------------------------------------

@(default_calling_convention = "system")
foreign mfplat {
    MFStartup          :: proc(Version: u32, dwFlags: u32) -> HRESULT ---
    MFShutdown         :: proc() -> HRESULT ---
    MFCreateAttributes :: proc(ppMFAttributes: ^^IMFAttributes, cInitialSize: u32) -> HRESULT ---
    MFCreateMediaType  :: proc(ppMFType: ^^IMFMediaType) -> HRESULT ---
}

@(default_calling_convention = "system")
foreign mf {
    MFEnumDeviceSources :: proc(pAttributes: ^IMFAttributes, pppSourceActivate: ^^^IMFActivate, pcSourceActivate: ^u32) -> HRESULT ---
}

@(default_calling_convention = "system")
foreign mfreadwrite {
    MFCreateSourceReaderFromMediaSource :: proc(pMediaSource: ^IMFMediaSource, pAttributes: ^IMFAttributes, ppSourceReader: ^^IMFSourceReader) -> HRESULT ---
}
