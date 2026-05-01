package mf

import win "core:sys/windows"

HRESULT :: win.HRESULT
GUID    :: win.GUID
BOOL    :: win.BOOL
DWORD   :: win.DWORD
LPVOID  :: win.LPVOID
MFTIME  :: i64
TOPOID  :: u64

// -------------------------------------------------------------------------
// Foreign libs
// -------------------------------------------------------------------------

foreign import mfplat      "system:mfplat.lib"
foreign import mf          "system:mf.lib"
foreign import mfreadwrite "system:mfreadwrite.lib"
foreign import mfuuid      "system:mfuuid.lib"
foreign import ole32       "system:ole32.lib"

// -------------------------------------------------------------------------
// Constants
// -------------------------------------------------------------------------

VERSION                          :: 0x00020070
STARTUP_FULL                     :: 0x0
SOURCE_READER_FIRST_VIDEO_STREAM : u32 : 0xFFFFFFFC
SOURCE_READER_ENABLE_VIDEO_PROCESSING_STRING :: "9C3C3BEA-6EAF-4C8B-8DC7-D3A2D1CD53A1"
SOURCE_READER_ENABLE_VIDEO_PROCESSING : GUID = {
    0x9C3C3BEA, 0x6EAF, 0x4C8B,
    {0x8D, 0xC7, 0xD3, 0xA2, 0xD1, 0xCD, 0x53, 0xA1},
}
SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING : GUID = {
    0x0F81DA2C, 0xB537, 0x4672,
    {0xA8, 0xB2, 0xA6, 0x81, 0xB1, 0x73, 0x07, 0xA3},
}

// Source reader flags
SOURCE_READERF_ERROR       :: 0x00000001
SOURCE_READERF_ENDOFSTREAM :: 0x00000002
SOURCE_READERF_STREAMTICK  :: 0x00000100

// VARTYPE for PROPVARIANT
VT_UNKNOWN :: u16(13)

// MF error codes
E_INVALIDTYPE    :: HRESULT(-1072875852) // 0xC00D36B4
E_INVALIDREQUEST :: HRESULT(-1072875854) // 0xC00D36B2

// MF_TOPOSTATUS values
TOPOSTATUS_INVALID         :: u32(0)
TOPOSTATUS_READY           :: u32(100)
TOPOSTATUS_STARTED_SOURCE  :: u32(200)
TOPOSTATUS_DYNAMIC_CHANGED :: u32(210)
TOPOSTATUS_SINK_SWITCHED   :: u32(300)
TOPOSTATUS_ENDED           :: u32(400)

// CoInitializeEx values
COINIT_MULTITHREADED :: 0x0

// IMFMediaEventGenerator::GetEvent flags
EVENT_FLAG_NO_WAIT :: u32(0x00000001)

// MF_RESOLUTION flags (used with IMFSourceResolver)
RESOLUTION_MEDIASOURCE           :: 0x00000001
RESOLUTION_BYTESTREAM            :: 0x00000002
RESOLUTION_CONTENT_DOES_NOT_HAVE_TO_MATCH_EXTENSION_OR_MIME_TYPE :: 0x00000004
RESOLUTION_KEEP_BYTE_STREAM_ALIVE_ON_FAIL :: 0x00000008
RESOLUTION_DISABLE_LOCAL_PLUGINS :: 0x00000010
RESOLUTION_READ                  :: 0x00010000
RESOLUTION_WRITE                 :: 0x00020000

// MFSESSION_SETTOPOLOGY_FLAGS
SESSION_SETTOPOLOGY_IMMEDIATE     :: 0x00000001
SESSION_SETTOPOLOGY_NORESOLUTION  :: 0x00000002
SESSION_SETTOPOLOGY_CLEAR_CURRENT :: 0x00000004

// MFSESSION_GETFULLTOPOLOGY_FLAGS
SESSION_GETFULLTOPOLOGY_CURRENT :: 0x00000001

// Session capability flags
SESSIONCAP_START                :: 0x00000001
SESSIONCAP_SEEK                 :: 0x00000002
SESSIONCAP_PAUSE                :: 0x00000004
SESSIONCAP_RATE_FORWARD         :: 0x00000010
SESSIONCAP_RATE_REVERSE         :: 0x00000020
SESSIONCAP_DOES_NOT_USE_NETWORK :: 0x00000040

// -------------------------------------------------------------------------
// GUIDs for media types
// -------------------------------------------------------------------------

MediaType_Audio : GUID = {
    0x73647561, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}
MediaType_Video : GUID = {
    0x73646976, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}
VideoFormat_RGB32 : GUID = {
    0x00000016, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}
VideoFormat_MJPG : GUID = {
    0x47504A4D, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}
VideoFormat_YUY2 : GUID = {
    0x32595559, 0x0000, 0x0010,
    {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71},
}

GUID_NULL : GUID = {}

// MFGetService service GUIDs
MR_VIDEO_RENDER_SERVICE : GUID = {
    0x1092a86c, 0xab1a, 0x459a,
    {0xa3, 0x36, 0x83, 0x1f, 0xbc, 0x4d, 0x11, 0xff},
}

// MF_EVENT_TOPOLOGY_STATUS attribute key
EVENT_TOPOLOGY_STATUS : GUID = {
    0x30c5018d, 0x9a53, 0x454b,
    {0xad, 0x9e, 0x6d, 0x5f, 0x8f, 0xa7, 0xc4, 0x3b},
}

// -------------------------------------------------------------------------
// GUIDs for topology node attributes
// -------------------------------------------------------------------------

TOPONODE_MEDIASTART : GUID = {
    0x835c58ea, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_MEDIASTOP : GUID = {
    0x835c58eb, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_SOURCE : GUID = {
    0x835c58ec, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_PRESENTATION_DESCRIPTOR : GUID = {
    0x835c58ed, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_STREAM_DESCRIPTOR : GUID = {
    0x835c58ee, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_SEQUENCE_ELEMENTID : GUID = {
    0x835c58ef, 0xe075, 0x4bc7,
    {0xbc, 0xba, 0x4d, 0xe0, 0x00, 0xdf, 0x9a, 0xe6},
}
TOPONODE_TRANSFORM_OBJECTID : GUID = {
    0x88dcc0c9, 0x293e, 0x4e8b,
    {0x9a, 0xeb, 0x0a, 0xd6, 0x4c, 0xc0, 0x16, 0xb0},
}
TOPONODE_CONNECT_METHOD : GUID = {
    0x494bbcf4, 0xb031, 0x4e38,
    {0x97, 0xc4, 0xd5, 0x42, 0x2d, 0xd6, 0x18, 0xdc},
}
TOPONODE_DECODER : GUID = {
    0x494bbce1, 0xb031, 0x4e38,
    {0x97, 0xc4, 0xd5, 0x42, 0x2d, 0xd6, 0x18, 0xdc},
}
TOPONODE_ERRORCODE : GUID = {
    0x494bbcee, 0xb031, 0x4e38,
    {0x97, 0xc4, 0xd5, 0x42, 0x2d, 0xd6, 0x18, 0xdc},
}
TOPONODE_NOSHUTDOWN_ON_REMOVE : GUID = {
    0x14932f9e, 0x9087, 0x4bb4,
    {0x84, 0x12, 0x51, 0x67, 0x14, 0x5c, 0xbe, 0x04},
}
TOPONODE_STREAMID : GUID = {
    0x14932f9b, 0x9087, 0x4bb4,
    {0x84, 0x12, 0x51, 0x67, 0x14, 0x5c, 0xbe, 0x04},
}

// -------------------------------------------------------------------------
// GUIDs for attributes
// -------------------------------------------------------------------------

MT_MAJOR_TYPE : GUID = {
    0x48eba18e, 0xf8c9, 0x4687,
    {0xbf, 0x11, 0x0a, 0x74, 0xc9, 0xf9, 0x6a, 0x8f},
}
MT_SUBTYPE : GUID = {
    0xf7e34c9a, 0x42e8, 0x4714,
    {0xb7, 0x4b, 0xcb, 0x29, 0xd7, 0x2c, 0x35, 0xe5},
}
MT_FRAME_SIZE : GUID = {
    0x1652c33d, 0xd6b2, 0x4012,
    {0xb8, 0x34, 0x72, 0x03, 0x08, 0x49, 0xa3, 0x7d},
}
DEVSOURCE_ATTRIBUTE_SOURCE_TYPE : GUID = {
    0xc60ac5fe, 0x252a, 0x478f,
    {0xa0, 0xef, 0xbc, 0x8f, 0xa5, 0xf7, 0xca, 0xd3},
}
DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID : GUID = {
    0x8ac3587a, 0x4ae7, 0x42d8,
    {0x99, 0xe0, 0x0a, 0x60, 0x13, 0xee, 0xf9, 0x0f},
}

// -------------------------------------------------------------------------
// Interface IIDs
// -------------------------------------------------------------------------

IID_IMFMediaSource : GUID = {
    0x279a808d, 0xaec7, 0x40c8,
    {0x9c, 0x6b, 0xa6, 0xb4, 0x92, 0xc7, 0x8a, 0x66},
}
IID_IMFAsyncCallback : GUID = {
    0xa27003cf, 0x2354, 0x4f2a,
    {0x8d, 0x6a, 0xab, 0x7c, 0xff, 0x15, 0x43, 0x7e},
}
IID_IMFAsyncResult : GUID = {
    0xac6b7889, 0x0740, 0x4d51,
    {0x86, 0x19, 0x90, 0x5d, 0x9c, 0xb3, 0x26, 0x17},
}
IID_IMFMediaEventGenerator : GUID = {
    0x2CD0BD52, 0xBCD5, 0x4B89,
    {0xB6, 0x2C, 0xEA, 0xBC, 0x0F, 0xDA, 0x4D, 0x29},
}
IID_IMFMediaEvent : GUID = {
    0xDF598932, 0xF10C, 0x4E39,
    {0xBB, 0xA2, 0xC3, 0x08, 0xF1, 0x01, 0xDA, 0xA3},
}
IID_IMFMediaSession : GUID = {
    0x90377834, 0x21D0, 0x4dee,
    {0x82, 0x14, 0xBA, 0x2E, 0x3E, 0x6C, 0x11, 0x27},
}
IID_IMFTopology : GUID = {
    0x83CF873A, 0xF6DA, 0x4BC3,
    {0xBE, 0xD4, 0xB8, 0x0E, 0xA7, 0x53, 0x15, 0xEB},
}
IID_IMFClock : GUID = {
    0x2EB1E945, 0x18B8, 0x4139,
    {0x9B, 0x1A, 0xD5, 0xD5, 0x84, 0x08, 0x18, 0x38},
}
IID_IMFPresentationClock : GUID = {
    0x868CE85C, 0x8EA9, 0x4F55,
    {0xAB, 0x82, 0xB0, 0x09, 0xA9, 0x10, 0xA8, 0x05},
}
IID_IMFClockStateSink : GUID = {
    0xF6696E82, 0x74F7, 0x4F3D,
    {0xA1, 0x78, 0x8A, 0x5E, 0x09, 0xC3, 0x65, 0x9F},
}
IID_IMFSourceResolver : GUID = {
    0xFBE5A32D, 0xA497, 0x4b61,
    {0xBB, 0x85, 0x97, 0xB1, 0xA8, 0x48, 0xA6, 0xE8},
}
IID_IMFPresentationDescriptor : GUID = {
    0x03CB2711, 0x24D7, 0x4db6,
    {0xA1, 0x7F, 0xF3, 0xA7, 0xA4, 0x79, 0xA5, 0x36},
}
IID_IMFStreamDescriptor : GUID = {
    0x56C03D9C, 0x9DBB, 0x45F5,
    {0xAB, 0x4B, 0xD8, 0x0F, 0x47, 0xC0, 0x59, 0x38},
}
IID_IMFMediaTypeHandler : GUID = {
    0xE93DCF6C, 0x4B07, 0x4e1e,
    {0x88, 0x25, 0x92, 0x97, 0xAC, 0x9C, 0x85, 0x23},
}
IID_IMFMediaSink : GUID = {
    0x6EF2A660, 0x47C0, 0x4666,
    {0xB1, 0x3D, 0xCB, 0xB7, 0x17, 0xF2, 0xFA, 0x2C},
}
IID_IMFStreamSink : GUID = {
    0x0A97B3CF, 0x8E7C, 0x4a3d,
    {0x8F, 0x8C, 0x0C, 0x84, 0x3D, 0xC2, 0x47, 0xF4},
}
IID_IMFVideoDisplayControl : GUID = {
    0xa490b1e4, 0xab84, 0x4d31,
    {0xa1, 0xb2, 0x18, 0x1e, 0x03, 0xb1, 0x07, 0x7a},
}

// -------------------------------------------------------------------------
// Enums
// -------------------------------------------------------------------------

OBJECT_TYPE :: enum u32 {
    MediaSource = 0,
    ByteStream  = 1,
    Invalid     = 2,
}

CLOCK_STATE :: enum u32 {
    Invalid = 0,
    Running = 1,
    Stopped = 2,
    Paused  = 3,
}

TOPOLOGY_TYPE :: enum u32 {
    Output       = 0,
    SourceStream = 1,
    Transform    = 2,
    Tee          = 3,
}

// MF_CONNECT_METHOD — from mfidl.h
CONNECT_METHOD :: enum u32 {
    DIRECT                       = 0x00000000,
    ALLOW_CONVERTER              = 0x00000001,
    ALLOW_DECODER                = 0x00000002,
    RESOLVE_INDEPENDENT_OUTPUTTYPES = 0x00000004,
    AS_OPTIONAL                  = 0x00000008,
    AS_OPTIONAL_BRANCH           = 0x00000010
}

MediaEventType :: enum u32 {
    Unknown                       = 0,
    Error                         = 1,
    ExtendedType                  = 2,
    NonFatalError                 = 3,
    // Session events (100–129)
    SessionUnknown                = 100,
    SessionTopologySet            = 101,
    SessionTopologiesCleared      = 102,
    SessionStarted                = 103,
    SessionPaused                 = 104,
    SessionStopped                = 105,
    SessionClosed                 = 106,
    SessionEnded                  = 107,
    SessionRateChanged            = 108,
    SessionScrubSampleComplete    = 109,
    SessionCapabilitiesChanged    = 110,
    SessionTopologyStatus         = 111,
    SessionNotifyPresentationTime = 112,
    NewPresentation               = 113,
    LicenseAcquisitionStart       = 114,
    LicenseAcquisitionCompleted   = 115,
    IndividualizationStart        = 116,
    IndividualizationCompleted    = 117,
    EnablerProgress               = 118,
    EnablerCompleted              = 119,
    PolicyError                   = 120,
    PolicyReport                  = 121,
    BufferingStarted              = 122,
    BufferingStopped              = 123,
    ConnectStart                  = 124,
    ConnectEnd                    = 125,
    ReconnectStart                = 126,
    ReconnectEnd                  = 127,
    RendererEvent                 = 128,
    SessionStreamSinkFormatChanged = 129,
    // Source events (200–212) — values match mfobjects.h exactly
    SourceUnknown                 = 200,
    SourceStarted                 = 201,
    SourceOpenedStream            = 202,
    SourceStopped                 = 203,
    SourcePaused                  = 204,
    SourceSeeked                  = 205,
    SourceFlushNotify             = 206,
    SourceEndOfPresentation       = 207,
    SourceRateChanged             = 208,
    EndOfPresentation             = 209, // MEEndOfPresentation — fired to the session
    SourceCharacteristicsChanged  = 210,
    SourceRateChangeRequested     = 211,
    SourceMetadataChanged         = 212,
    // Stream events (300–311)
    StreamUnknown                 = 300,
    MediaStream                   = 301,
    StreamStarted                 = 302,
    StreamStopped                 = 303,
    StreamPaused                  = 304,
    EndOfStream                   = 305, // MEEndOfStream — one stream finished
    MediaSample                   = 306,
    StreamThinMode                = 307,
    StreamFormatChanged           = 308,
    StreamSubtypeChanged          = 309,
    DropSamplesBegin              = 310,
    DropSamplesEnd                = 311,
    // Sink/output events (400–421)
    SinkUnknown                   = 400,
    StreamSinkStarted             = 401,
    StreamSinkStopped             = 402,
    StreamSinkPaused              = 403,
    StreamSinkRateChanged         = 404,
    StreamSinkRequestSample       = 405,
    StreamSinkMarker              = 406,
    StreamSinkPrerolled           = 407,
    StreamSinkScrubSampleComplete = 408,
    StreamSinkFormatChanged       = 409,
    StreamSinkDeviceChanged       = 410,
    QualityNotify                 = 411,
    SinkInvalidated               = 412,
    AudioSessionNameChanged       = 413,
    AudioSessionVolumeChanged     = 414,
    AudioSessionDeviceRemoved     = 415,
    AudioSessionServerShutdown    = 416,
    AudioSessionGroupingParamChanged = 417,
    AudioSessionIconChanged       = 418,
    AudioSessionFormatChanged     = 419,
    AudioSessionDisconnected      = 420,
    AudioSessionExclusiveModeOverride = 421,
    // MFT/transform events (700–705)
    TransformUnknown              = 700,
    TransformNeedInput            = 701,
    TransformHaveOutput           = 702,
    TransformDrainComplete        = 703,
    TransformMarker               = 704,
    TransformInputStreamStateChanged = 705,
    // Misc
    ByteStreamCharacteristicsChanged = 800,
    VideoCaptureDeviceRemoved     = 850,
    VideoCaptureDevicePreempted   = 851,
    StreamSinkFormatInvalidated   = 860,
    EncodingParameters            = 900,
}

// -------------------------------------------------------------------------
// Plain structs
// -------------------------------------------------------------------------

CLOCK_PROPERTIES :: struct {
    qwCorrelationRate: u64,
    guidClockId:       GUID,
    dwClockFlags:      u32,
    qwClockFrequency:  u64,
    dwClockTolerance:  u32,
    dwClockJitter:     u32,
}

// Minimal PROPVARIANT — matches Windows ABI (24 bytes on x64).
// Only exposes vt and punkVal; other union members accessible via _raw.
_PROPVARIANT_UNION :: struct #raw_union {
    punkVal: ^IUnknown,
    _raw:    [16]u8,
}
PROPVARIANT :: struct {
    vt:   u16,
    _r:   [3]u16,    // wReserved1/2/3
    data: _PROPVARIANT_UNION,
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
    ActivateObject: proc "system" (this: ^IMFActivate, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
    ShutdownObject: proc "system" (this: ^IMFActivate) -> HRESULT,
    DetachObject:   proc "system" (this: ^IMFActivate) -> HRESULT,
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
    GetMajorType:       proc "system" (this: ^IMFMediaType, pguidMajorType: ^GUID) -> HRESULT,
    IsCompressedFormat: proc "system" (this: ^IMFMediaType, pfCompressed: ^BOOL) -> HRESULT,
    IsEqual:            proc "system" (this: ^IMFMediaType, pIMediaType: ^IMFMediaType, pdwFlags: ^u32) -> HRESULT,
    GetRepresentation:  proc "system" (this: ^IMFMediaType, guidRepresentation: GUID, ppvRepresentation: ^rawptr) -> HRESULT,
    FreeRepresentation: proc "system" (this: ^IMFMediaType, guidRepresentation: GUID, pvRepresentation: rawptr) -> HRESULT,
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
    Lock:             proc "system" (this: ^IMFMediaBuffer, ppbBuffer: ^[^]u8, pcbMaxLength: ^u32, pcbCurrentLength: ^u32) -> HRESULT,
    Unlock:           proc "system" (this: ^IMFMediaBuffer) -> HRESULT,
    GetCurrentLength: proc "system" (this: ^IMFMediaBuffer, pcbCurrentLength: ^u32) -> HRESULT,
    SetCurrentLength: proc "system" (this: ^IMFMediaBuffer, cbCurrentLength: u32) -> HRESULT,
    GetMaxLength:     proc "system" (this: ^IMFMediaBuffer, pcbMaxLength: ^u32) -> HRESULT,
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
    GetSampleFlags:            proc "system" (this: ^IMFSample, pdwSampleFlags: ^u32) -> HRESULT,
    SetSampleFlags:            proc "system" (this: ^IMFSample, dwSampleFlags: u32) -> HRESULT,
    GetSampleTime:             proc "system" (this: ^IMFSample, phnsSampleTime: ^i64) -> HRESULT,
    SetSampleTime:             proc "system" (this: ^IMFSample, hnsSampleTime: i64) -> HRESULT,
    GetSampleDuration:         proc "system" (this: ^IMFSample, phnsSampleDuration: ^i64) -> HRESULT,
    SetSampleDuration:         proc "system" (this: ^IMFSample, hnsSampleDuration: i64) -> HRESULT,
    GetBufferCount:            proc "system" (this: ^IMFSample, pdwBufferCount: ^u32) -> HRESULT,
    GetBufferByIndex:          proc "system" (this: ^IMFSample, dwIndex: u32, ppBuffer: ^^IMFMediaBuffer) -> HRESULT,
    ConvertToContiguousBuffer: proc "system" (this: ^IMFSample, ppBuffer: ^^IMFMediaBuffer) -> HRESULT,
    AddBuffer:                 proc "system" (this: ^IMFSample, pBuffer: ^IMFMediaBuffer) -> HRESULT,
    RemoveBufferByIndex:       proc "system" (this: ^IMFSample, dwIndex: u32) -> HRESULT,
    RemoveAllBuffers:          proc "system" (this: ^IMFSample) -> HRESULT,
    GetTotalLength:            proc "system" (this: ^IMFSample, pcbTotalLength: ^u32) -> HRESULT,
    CopyToBuffer:              proc "system" (this: ^IMFSample, pBuffer: ^IMFMediaBuffer) -> HRESULT,
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
    GetEvent:                    proc "system" (this: ^IMFMediaSource, dwFlags: u32, ppEvent: ^rawptr) -> HRESULT,
    BeginGetEvent:               proc "system" (this: ^IMFMediaSource, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndGetEvent:                 proc "system" (this: ^IMFMediaSource, pResult: ^IMFAsyncResult, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    QueueEvent:                  proc "system" (this: ^IMFMediaSource, met: u32, guidExtendedType: ^GUID, hrStatus: HRESULT, pvValue: rawptr) -> HRESULT,
    GetCharacteristics:          proc "system" (this: ^IMFMediaSource, pdwCharacteristics: ^u32) -> HRESULT,
    CreatePresentationDescriptor: proc "system" (this: ^IMFMediaSource, ppPresentationDescriptor: ^^IMFPresentationDescriptor) -> HRESULT,
    Start:                       proc "system" (this: ^IMFMediaSource, pPresentationDescriptor: ^IMFPresentationDescriptor, pguidTimeFormat: ^GUID, pvarStartPosition: rawptr) -> HRESULT,
    Stop:                        proc "system" (this: ^IMFMediaSource) -> HRESULT,
    Pause:                       proc "system" (this: ^IMFMediaSource) -> HRESULT,
    Shutdown:                    proc "system" (this: ^IMFMediaSource) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaTypeHandler
// -------------------------------------------------------------------------

IMFMediaTypeHandler :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediatypehandler_vtable: ^IMFMediaTypeHandler_VTable,
}
IMFMediaTypeHandler_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    IsMediaTypeSupported: proc "system" (this: ^IMFMediaTypeHandler, pMediaType: ^IMFMediaType, ppClosestMediaType: ^^IMFMediaType) -> HRESULT,
    GetMediaTypeCount:    proc "system" (this: ^IMFMediaTypeHandler, pdwTypeCount: ^u32) -> HRESULT,
    GetMediaTypeByIndex:  proc "system" (this: ^IMFMediaTypeHandler, dwIndex: u32, ppType: ^^IMFMediaType) -> HRESULT,
    SetCurrentMediaType:  proc "system" (this: ^IMFMediaTypeHandler, pMediaType: ^IMFMediaType) -> HRESULT,
    GetCurrentMediaType:  proc "system" (this: ^IMFMediaTypeHandler, ppMediaType: ^^IMFMediaType) -> HRESULT,
    GetMajorType:         proc "system" (this: ^IMFMediaTypeHandler, pguidMajorType: ^GUID) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFStreamDescriptor
// -------------------------------------------------------------------------

IMFStreamDescriptor :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfstreamdescriptor_vtable: ^IMFStreamDescriptor_VTable,
}
IMFStreamDescriptor_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetStreamIdentifier: proc "system" (this: ^IMFStreamDescriptor, pdwStreamIdentifier: ^u32) -> HRESULT,
    GetMediaTypeHandler: proc "system" (this: ^IMFStreamDescriptor, ppMediaTypeHandler: ^^IMFMediaTypeHandler) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFPresentationDescriptor
// -------------------------------------------------------------------------

IMFPresentationDescriptor :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfpresentationdescriptor_vtable: ^IMFPresentationDescriptor_VTable,
}
IMFPresentationDescriptor_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetStreamDescriptorCount:   proc "system" (this: ^IMFPresentationDescriptor, pdwDescriptorCount: ^u32) -> HRESULT,
    GetStreamDescriptorByIndex: proc "system" (this: ^IMFPresentationDescriptor, dwIndex: u32, pfSelected: ^BOOL, ppDescriptor: ^^IMFStreamDescriptor) -> HRESULT,
    SelectStream:               proc "system" (this: ^IMFPresentationDescriptor, dwDescriptorIndex: u32) -> HRESULT,
    DeselectStream:             proc "system" (this: ^IMFPresentationDescriptor, dwDescriptorIndex: u32) -> HRESULT,
    Clone:                      proc "system" (this: ^IMFPresentationDescriptor, ppPresentationDescriptor: ^^IMFPresentationDescriptor) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFAsyncResult
// -------------------------------------------------------------------------

IMFAsyncResult :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfasyncresult_vtable: ^IMFAsyncResult_VTable,
}
IMFAsyncResult_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetState:        proc "system" (this: ^IMFAsyncResult, ppunkState: ^^IUnknown) -> HRESULT,
    GetStatus:       proc "system" (this: ^IMFAsyncResult) -> HRESULT,
    SetStatus:       proc "system" (this: ^IMFAsyncResult, hrStatus: HRESULT) -> HRESULT,
    GetObject:       proc "system" (this: ^IMFAsyncResult, ppObject: ^^IUnknown) -> HRESULT,
    GetStateNoAddRef: proc "system" (this: ^IMFAsyncResult) -> ^IUnknown,
}

// -------------------------------------------------------------------------
// IMFAsyncCallback
// -------------------------------------------------------------------------

IMFAsyncCallback :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfasynccallback_vtable: ^IMFAsyncCallback_VTable,
}
IMFAsyncCallback_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetParameters: proc "system" (this: ^IMFAsyncCallback, pdwFlags: ^u32, pdwQueue: ^u32) -> HRESULT,
    Invoke:        proc "system" (this: ^IMFAsyncCallback, pAsyncResult: ^IMFAsyncResult) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaEventGenerator
// -------------------------------------------------------------------------

IMFMediaEventGenerator :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediaeventgenerator_vtable: ^IMFMediaEventGenerator_VTable,
}
IMFMediaEventGenerator_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetEvent:      proc "system" (this: ^IMFMediaEventGenerator, dwFlags: u32, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    BeginGetEvent: proc "system" (this: ^IMFMediaEventGenerator, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndGetEvent:   proc "system" (this: ^IMFMediaEventGenerator, pResult: ^IMFAsyncResult, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    QueueEvent:    proc "system" (this: ^IMFMediaEventGenerator, met: u32, guidExtendedType: ^GUID, hrStatus: HRESULT, pvValue: rawptr) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaEvent
// -------------------------------------------------------------------------

IMFMediaEvent :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imfmediaevent_vtable: ^IMFMediaEvent_VTable,
}
IMFMediaEvent_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetType:         proc "system" (this: ^IMFMediaEvent, pmet: ^MediaEventType) -> HRESULT,
    GetExtendedType: proc "system" (this: ^IMFMediaEvent, pguidExtendedType: ^GUID) -> HRESULT,
    GetStatus:       proc "system" (this: ^IMFMediaEvent, phrStatus: ^HRESULT) -> HRESULT,
    GetValue:        proc "system" (this: ^IMFMediaEvent, pvValue: ^PROPVARIANT) -> HRESULT,
}

// IMFMediaEventType is an alias; the event interface is IMFMediaEvent
IMFMediaEventType :: IMFMediaEvent

// -------------------------------------------------------------------------
// IMFTopologyNode
// -------------------------------------------------------------------------

IMFTopologyNode :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imftopologynode_vtable: ^IMFTopologyNode_VTable,
}
IMFTopologyNode_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    SetObject:        proc "system" (this: ^IMFTopologyNode, pObject: ^IUnknown) -> HRESULT,
    GetObject:        proc "system" (this: ^IMFTopologyNode, ppObject: ^^IUnknown) -> HRESULT,
    GetNodeType:      proc "system" (this: ^IMFTopologyNode, pType: ^TOPOLOGY_TYPE) -> HRESULT,
    GetTopoNodeID:    proc "system" (this: ^IMFTopologyNode, pID: ^TOPOID) -> HRESULT,
    SetTopoNodeID:    proc "system" (this: ^IMFTopologyNode, ulTopoID: TOPOID) -> HRESULT,
    GetInputCount:    proc "system" (this: ^IMFTopologyNode, pcInputs: ^u32) -> HRESULT,
    GetOutputCount:   proc "system" (this: ^IMFTopologyNode, pcOutputs: ^u32) -> HRESULT,
    ConnectOutput:    proc "system" (this: ^IMFTopologyNode, dwOutputIndex: u32, pDownstreamNode: ^IMFTopologyNode, dwInputIndexOnDownstreamNode: u32) -> HRESULT,
    DisconnectOutput: proc "system" (this: ^IMFTopologyNode, dwOutputIndex: u32) -> HRESULT,
    GetInput:         proc "system" (this: ^IMFTopologyNode, dwInputIndex: u32, ppUpstreamNode: ^^IMFTopologyNode, pdwOutputIndexOnUpstreamNode: ^u32) -> HRESULT,
    GetOutput:        proc "system" (this: ^IMFTopologyNode, dwOutputIndex: u32, ppDownstreamNode: ^^IMFTopologyNode, pdwInputIndexOnDownstreamNode: ^u32) -> HRESULT,
    SetOutputPrefType: proc "system" (this: ^IMFTopologyNode, dwOutputIndex: u32, pType: ^IMFMediaType) -> HRESULT,
    GetOutputPrefType: proc "system" (this: ^IMFTopologyNode, dwOutputIndex: u32, ppType: ^^IMFMediaType) -> HRESULT,
    SetInputPrefType:  proc "system" (this: ^IMFTopologyNode, dwInputIndex: u32, pType: ^IMFMediaType) -> HRESULT,
    GetInputPrefType:  proc "system" (this: ^IMFTopologyNode, dwInputIndex: u32, ppType: ^^IMFMediaType) -> HRESULT,
    CloneFrom:        proc "system" (this: ^IMFTopologyNode, pNode: ^IMFTopologyNode) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFCollection
// -------------------------------------------------------------------------

IMFCollection :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfcollection_vtable: ^IMFCollection_VTable,
}
IMFCollection_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetElementCount: proc "system" (this: ^IMFCollection, pcElements: ^u32) -> HRESULT,
    GetElement:      proc "system" (this: ^IMFCollection, dwElementIndex: u32, ppUnkElement: ^^IUnknown) -> HRESULT,
    AddElement:      proc "system" (this: ^IMFCollection, pUnkElement: ^IUnknown) -> HRESULT,
    RemoveElement:   proc "system" (this: ^IMFCollection, dwElementIndex: u32, ppUnkElement: ^^IUnknown) -> HRESULT,
    InsertElementAt: proc "system" (this: ^IMFCollection, dwIndex: u32, pUnkElement: ^IUnknown) -> HRESULT,
    RemoveAllElements: proc "system" (this: ^IMFCollection) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFTopology
// -------------------------------------------------------------------------

IMFTopology :: struct #raw_union {
    #subtype imfattributes: IMFAttributes,
    using imftopology_vtable: ^IMFTopology_VTable,
}
IMFTopology_VTable :: struct {
    using imfattributes_vtable: IMFAttributes_VTable,
    GetTopologyID:           proc "system" (this: ^IMFTopology, pID: ^TOPOID) -> HRESULT,
    AddNode:                 proc "system" (this: ^IMFTopology, pNode: ^IMFTopologyNode) -> HRESULT,
    RemoveNode:              proc "system" (this: ^IMFTopology, pNode: ^IMFTopologyNode) -> HRESULT,
    GetNodeCount:            proc "system" (this: ^IMFTopology, pwNodes: ^u16) -> HRESULT,
    GetNode:                 proc "system" (this: ^IMFTopology, wIndex: u16, ppNode: ^^IMFTopologyNode) -> HRESULT,
    Clear:                   proc "system" (this: ^IMFTopology) -> HRESULT,
    CloneFrom:               proc "system" (this: ^IMFTopology, pTopology: ^IMFTopology) -> HRESULT,
    GetNodeByID:             proc "system" (this: ^IMFTopology, qwTopoNodeID: TOPOID, ppNode: ^^IMFTopologyNode) -> HRESULT,
    GetSourceNodeCollection: proc "system" (this: ^IMFTopology, ppCollection: ^^IMFCollection) -> HRESULT,
    GetOutputNodeCollection: proc "system" (this: ^IMFTopology, ppCollection: ^^IMFCollection) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFClock
// -------------------------------------------------------------------------

IMFClock :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfclock_vtable: ^IMFClock_VTable,
}
IMFClock_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetClockCharacteristics: proc "system" (this: ^IMFClock, pdwCharacteristics: ^u32) -> HRESULT,
    GetCorrelatedTime:       proc "system" (this: ^IMFClock, dwReserved: u32, pllClockTime: ^i64, phnsSystemTime: ^MFTIME) -> HRESULT,
    GetContinuityKey:        proc "system" (this: ^IMFClock, pdwContinuityKey: ^u32) -> HRESULT,
    GetState:                proc "system" (this: ^IMFClock, dwReserved: u32, peClockState: ^CLOCK_STATE) -> HRESULT,
    GetProperties:           proc "system" (this: ^IMFClock, pClockProperties: ^CLOCK_PROPERTIES) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFClockStateSink
// -------------------------------------------------------------------------

IMFClockStateSink :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfclockstatesink_vtable: ^IMFClockStateSink_VTable,
}
IMFClockStateSink_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    OnClockStart:   proc "system" (this: ^IMFClockStateSink, hnsSystemTime: MFTIME, llClockStartOffset: i64) -> HRESULT,
    OnClockStop:    proc "system" (this: ^IMFClockStateSink, hnsSystemTime: MFTIME) -> HRESULT,
    OnClockPause:   proc "system" (this: ^IMFClockStateSink, hnsSystemTime: MFTIME) -> HRESULT,
    OnClockRestart: proc "system" (this: ^IMFClockStateSink, hnsSystemTime: MFTIME) -> HRESULT,
    OnClockSetRate: proc "system" (this: ^IMFClockStateSink, hnsSystemTime: MFTIME, flRate: f32) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFPresentationClock
// -------------------------------------------------------------------------

IMFPresentationClock :: struct #raw_union {
    #subtype imfclock: IMFClock,
    using imfpresentationclock_vtable: ^IMFPresentationClock_VTable,
}
IMFPresentationClock_VTable :: struct {
    using imfclock_vtable: IMFClock_VTable,
    SetTimeSource:        proc "system" (this: ^IMFPresentationClock, pTimeSource: rawptr) -> HRESULT,
    GetTimeSource:        proc "system" (this: ^IMFPresentationClock, ppTimeSource: ^rawptr) -> HRESULT,
    GetTime:              proc "system" (this: ^IMFPresentationClock, phnsClockTime: ^MFTIME) -> HRESULT,
    AddClockStateSink:    proc "system" (this: ^IMFPresentationClock, pStateSink: ^IMFClockStateSink) -> HRESULT,
    RemoveClockStateSink: proc "system" (this: ^IMFPresentationClock, pStateSink: ^IMFClockStateSink) -> HRESULT,
    Start:                proc "system" (this: ^IMFPresentationClock, llClockStartOffset: i64) -> HRESULT,
    Stop:                 proc "system" (this: ^IMFPresentationClock) -> HRESULT,
    Pause:                proc "system" (this: ^IMFPresentationClock) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaSink
// -------------------------------------------------------------------------

IMFMediaSink :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediasink_vtable: ^IMFMediaSink_VTable,
}
IMFMediaSink_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetCharacteristics:   proc "system" (this: ^IMFMediaSink, pdwCharacteristics: ^u32) -> HRESULT,
    AddStreamSink:        proc "system" (this: ^IMFMediaSink, dwStreamSinkIdentifier: u32, pMediaType: ^IMFMediaType, ppStreamSink: ^^IMFStreamSink) -> HRESULT,
    RemoveStreamSink:     proc "system" (this: ^IMFMediaSink, dwStreamSinkIdentifier: u32) -> HRESULT,
    GetStreamSinkCount:   proc "system" (this: ^IMFMediaSink, pcStreamSinkCount: ^u32) -> HRESULT,
    GetStreamSinkByIndex: proc "system" (this: ^IMFMediaSink, dwIndex: u32, ppStreamSink: ^^IMFStreamSink) -> HRESULT,
    GetStreamSinkById:    proc "system" (this: ^IMFMediaSink, dwStreamSinkIdentifier: u32, ppStreamSink: ^^IMFStreamSink) -> HRESULT,
    SetPresentationClock: proc "system" (this: ^IMFMediaSink, pPresentationClock: ^IMFPresentationClock) -> HRESULT,
    GetPresentationClock: proc "system" (this: ^IMFMediaSink, ppPresentationClock: ^^IMFPresentationClock) -> HRESULT,
    Shutdown:             proc "system" (this: ^IMFMediaSink) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFStreamSink
// -------------------------------------------------------------------------

STREAMSINK_MARKER_TYPE :: enum u32 {
    Default      = 0,
    EndOfSegment = 1,
    Tick         = 2,
    Event        = 3,
}

IMFStreamSink :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfstreamsink_vtable: ^IMFStreamSink_VTable,
}
IMFStreamSink_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    // IMFMediaEventGenerator methods
    GetEvent:           proc "system" (this: ^IMFStreamSink, dwFlags: u32, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    BeginGetEvent:      proc "system" (this: ^IMFStreamSink, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndGetEvent:        proc "system" (this: ^IMFStreamSink, pResult: ^IMFAsyncResult, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    QueueEvent:         proc "system" (this: ^IMFStreamSink, met: u32, guidExtendedType: ^GUID, hrStatus: HRESULT, pvValue: rawptr) -> HRESULT,
    // IMFStreamSink methods
    GetMediaSink:       proc "system" (this: ^IMFStreamSink, ppMediaSink: ^^IMFMediaSink) -> HRESULT,
    GetIdentifier:      proc "system" (this: ^IMFStreamSink, pdwIdentifier: ^u32) -> HRESULT,
    GetMediaTypeHandler: proc "system" (this: ^IMFStreamSink, ppHandler: ^^IMFMediaTypeHandler) -> HRESULT,
    ProcessSample:      proc "system" (this: ^IMFStreamSink, pSample: ^IMFSample) -> HRESULT,
    PlaceMarker:        proc "system" (this: ^IMFStreamSink, eMarkerType: STREAMSINK_MARKER_TYPE, pvarMarkerValue: rawptr, pvarContextValue: rawptr) -> HRESULT,
    Flush:              proc "system" (this: ^IMFStreamSink) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFMediaSession
// -------------------------------------------------------------------------

IMFMediaSession :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfmediasession_vtable: ^IMFMediaSession_VTable,
}
IMFMediaSession_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    // IMFMediaEventGenerator methods
    GetEvent:               proc "system" (this: ^IMFMediaSession, dwFlags: u32, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    BeginGetEvent:          proc "system" (this: ^IMFMediaSession, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndGetEvent:            proc "system" (this: ^IMFMediaSession, pResult: ^IMFAsyncResult, ppEvent: ^^IMFMediaEvent) -> HRESULT,
    QueueEvent:             proc "system" (this: ^IMFMediaSession, met: u32, guidExtendedType: ^GUID, hrStatus: HRESULT, pvValue: rawptr) -> HRESULT,
    // IMFMediaSession methods
    SetTopology:            proc "system" (this: ^IMFMediaSession, dwSetTopologyFlags: u32, pTopology: ^IMFTopology) -> HRESULT,
    ClearTopologies:        proc "system" (this: ^IMFMediaSession) -> HRESULT,
    Start:                  proc "system" (this: ^IMFMediaSession, pguidTimeFormat: ^GUID, pvarStartPosition: rawptr) -> HRESULT,
    Pause:                  proc "system" (this: ^IMFMediaSession) -> HRESULT,
    Stop:                   proc "system" (this: ^IMFMediaSession) -> HRESULT,
    Close:                  proc "system" (this: ^IMFMediaSession) -> HRESULT,
    Shutdown:               proc "system" (this: ^IMFMediaSession) -> HRESULT,
    GetClock:               proc "system" (this: ^IMFMediaSession, ppClock: ^^IMFClock) -> HRESULT,
    GetSessionCapabilities: proc "system" (this: ^IMFMediaSession, pdwCaps: ^u32) -> HRESULT,
    GetFullTopology:        proc "system" (this: ^IMFMediaSession, dwGetFullTopologyFlags: u32, TopoId: TOPOID, ppFullTopo: ^^IMFTopology) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFSourceResolver
// -------------------------------------------------------------------------

IMFSourceResolver :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfsourceresolver_vtable: ^IMFSourceResolver_VTable,
}
IMFSourceResolver_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    // Synchronous methods
    CreateObjectFromURL:            proc "system" (this: ^IMFSourceResolver, pwszURL: [^]u16, dwFlags: u32, pProps: rawptr, pObjectType: ^OBJECT_TYPE, ppObject: ^^IUnknown) -> HRESULT,
    CreateObjectFromByteStream:     proc "system" (this: ^IMFSourceResolver, pByteStream: rawptr, pwszURL: [^]u16, dwFlags: u32, pProps: rawptr, pObjectType: ^OBJECT_TYPE, ppObject: ^^IUnknown) -> HRESULT,
    // Asynchronous methods
    BeginCreateObjectFromURL:        proc "system" (this: ^IMFSourceResolver, pwszURL: [^]u16, dwFlags: u32, pProps: rawptr, ppIUnknownCancelCookie: ^^IUnknown, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndCreateObjectFromURL:          proc "system" (this: ^IMFSourceResolver, pResult: ^IMFAsyncResult, pObjectType: ^OBJECT_TYPE, ppObject: ^^IUnknown) -> HRESULT,
    BeginCreateObjectFromByteStream: proc "system" (this: ^IMFSourceResolver, pByteStream: rawptr, pwszURL: [^]u16, dwFlags: u32, pProps: rawptr, ppIUnknownCancelCookie: ^^IUnknown, pCallback: ^IMFAsyncCallback, punkState: ^IUnknown) -> HRESULT,
    EndCreateObjectFromByteStream:   proc "system" (this: ^IMFSourceResolver, pResult: ^IMFAsyncResult, pObjectType: ^OBJECT_TYPE, ppObject: ^^IUnknown) -> HRESULT,

    CancelObjectCreation:           proc "system" (this: ^IMFSourceResolver, pIUnknownCancelCookie: ^IUnknown) -> HRESULT,
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
    GetStreamSelection:       proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, pfSelected: ^BOOL) -> HRESULT,
    SetStreamSelection:       proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, fSelected: BOOL) -> HRESULT,
    GetNativeMediaType:       proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, dwMediaTypeIndex: u32, ppMediaType: ^^IMFMediaType) -> HRESULT,
    GetCurrentMediaType:      proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, ppMediaType: ^^IMFMediaType) -> HRESULT,
    SetCurrentMediaType:      proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, pdwReserved: ^u32, pMediaType: ^IMFMediaType) -> HRESULT,
    SetCurrentPosition:       proc "system" (this: ^IMFSourceReader, guidTimeFormat: ^GUID, varPosition: rawptr) -> HRESULT,
    ReadSample:               proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, dwControlFlags: u32, pdwActualStreamIndex: ^u32, pdwStreamFlags: ^u32, pllTimestamp: ^i64, ppSample: ^^IMFSample) -> HRESULT,
    Flush:                    proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32) -> HRESULT,
    GetServiceForStream:      proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, guidService: ^GUID, riid: ^GUID, ppvObject: ^rawptr) -> HRESULT,
    GetPresentationAttribute: proc "system" (this: ^IMFSourceReader, dwStreamIndex: u32, guidAttribute: ^GUID, pvarAttribute: rawptr) -> HRESULT,
}

// -------------------------------------------------------------------------
// IMFTopoLoader
// -------------------------------------------------------------------------

IMFTopoLoader :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imftopoloader_vtable: ^IMFTopoLoader_VTable,
}
IMFTopoLoader_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    Load: proc "system" (this: ^IMFTopoLoader, pInputTopo: ^IMFTopology, ppOutputTopo: ^^IMFTopology, pCurrentTopo: ^IMFTopology) -> HRESULT,
}

IID_IMFTopoLoader : GUID = {
    0xde9a6157, 0xf660, 0x4643,
    {0xb5, 0x6a, 0xdf, 0x9f, 0x79, 0x98, 0xc7, 0xcd},
}

// -------------------------------------------------------------------------
// IMFVideoDisplayControl
// -------------------------------------------------------------------------

IMFVideoDisplayControl :: struct #raw_union {
    #subtype iunknown: IUnknown,
    using imfvideodisplaycontrol_vtable: ^IMFVideoDisplayControl_VTable,
}
IMFVideoDisplayControl_VTable :: struct {
    using iunknown_vtable: IUnknown_VTable,
    GetNativeVideoSize: proc "system" (this: ^IMFVideoDisplayControl, pszVideo: rawptr, pszARVideo: rawptr) -> HRESULT,
    GetIdealVideoSize:  proc "system" (this: ^IMFVideoDisplayControl, pszMin: rawptr, pszMax: rawptr) -> HRESULT,
    SetVideoPosition:   proc "system" (this: ^IMFVideoDisplayControl, pnrcSource: rawptr, prcDest: ^win.RECT) -> HRESULT,
    GetVideoPosition:   proc "system" (this: ^IMFVideoDisplayControl, pnrcSource: rawptr, prcDest: ^win.RECT) -> HRESULT,
    SetAspectRatioMode: proc "system" (this: ^IMFVideoDisplayControl, dwAspectRatioMode: u32) -> HRESULT,
    GetAspectRatioMode: proc "system" (this: ^IMFVideoDisplayControl, pdwAspectRatioMode: ^u32) -> HRESULT,
    SetVideoWindow:     proc "system" (this: ^IMFVideoDisplayControl, hwndVideo: win.HWND) -> HRESULT,
    GetVideoWindow:     proc "system" (this: ^IMFVideoDisplayControl, phwndVideo: ^win.HWND) -> HRESULT,
    RepaintVideo:       proc "system" (this: ^IMFVideoDisplayControl) -> HRESULT,
    GetCurrentImage:    proc "system" (this: ^IMFVideoDisplayControl, pBitmapHeader: rawptr, pDib: ^[^]u8, pcbDib: ^u32, pTimeStamp: ^MFTIME) -> HRESULT,
    SetBorderColor:     proc "system" (this: ^IMFVideoDisplayControl, Clr: u32) -> HRESULT,
    GetBorderColor:     proc "system" (this: ^IMFVideoDisplayControl, pClr: ^u32) -> HRESULT,
    SetRenderingPrefs:  proc "system" (this: ^IMFVideoDisplayControl, dwRenderFlags: u32) -> HRESULT,
    GetRenderingPrefs:  proc "system" (this: ^IMFVideoDisplayControl, pdwRenderFlags: ^u32) -> HRESULT,
    SetFullscreen:      proc "system" (this: ^IMFVideoDisplayControl, fFullscreen: BOOL) -> HRESULT,
    GetFullscreen:      proc "system" (this: ^IMFVideoDisplayControl, pfFullscreen: ^BOOL) -> HRESULT,
}

// -------------------------------------------------------------------------
// Free functions
// -------------------------------------------------------------------------

@(default_calling_convention = "system")
foreign mfplat {
    MFStartup                 :: proc(Version: u32, dwFlags: u32) -> HRESULT ---
    MFShutdown                :: proc() -> HRESULT ---
    MFCreateAttributes        :: proc(ppMFAttributes: ^^IMFAttributes, cInitialSize: u32) -> HRESULT ---
    MFCreateMediaType         :: proc(ppMFType: ^^IMFMediaType) -> HRESULT ---
    MFCreatePresentationClock      :: proc(ppPresentationClock: ^^IMFPresentationClock) -> HRESULT ---
    MFCreatePresentationDescriptor :: proc(cStreamDescriptors: u32, apStreamDescriptors: [^]^IMFStreamDescriptor, ppPresentationDescriptor: ^^IMFPresentationDescriptor) -> HRESULT ---
}

@(default_calling_convention = "system")
foreign mf {
    MFEnumDeviceSources  :: proc(pAttributes: ^IMFAttributes, pppSourceActivate: ^^^IMFActivate, pcSourceActivate: ^u32) -> HRESULT ---
    MFCreateMediaSession :: proc(pConfiguration: ^IMFAttributes, ppMediaSession: ^^IMFMediaSession) -> HRESULT ---
    MFCreateTopology     :: proc(ppTopo: ^^IMFTopology) -> HRESULT ---
    MFCreateTopologyNode    :: proc(NodeType: TOPOLOGY_TYPE, ppNode: ^^IMFTopologyNode) -> HRESULT ---
    MFCreateSourceResolver  :: proc(ppISourceResolver: ^^IMFSourceResolver) -> HRESULT ---
    MFCreateAudioRendererActivate :: proc(ppActivate:^^IMFActivate) -> HRESULT ---
    MFCreateVideoRendererActivate :: proc(hwndVideo:win.HWND,ppActivate:^^IMFActivate) -> HRESULT ---
    MFGetService      :: proc(punkObject: rawptr, guidService: ^GUID, riid: ^GUID, ppvObject: ^rawptr) -> HRESULT ---
    MFCreateTopoLoader :: proc(ppObj: ^^IMFTopoLoader) -> HRESULT ---
}

@(default_calling_convention = "system")
foreign ole32 {
    PropVariantClear  :: proc(pvar: ^PROPVARIANT) -> HRESULT ---
    CoInitializeEx    :: proc(pvReserved: rawptr, dwCoInit: u32) -> HRESULT ---
    CoUninitialize    :: proc() ---
}

// IsEqualGUID is an SDK inline (memcmp); in Odin == on GUID structs is identical.
// IsEqualGUID :: #force_inline proc(a, b: GUID) -> bool { return a == b }

@(default_calling_convention = "system")
foreign mfreadwrite {
    MFCreateSourceReaderFromMediaSource :: proc(pMediaSource: ^IMFMediaSource, pAttributes: ^IMFAttributes, ppSourceReader: ^^IMFSourceReader) -> HRESULT ---
}

// -------------------------------------------------------------------------
// Utilities :
// -------------------------------------------------------------------------
IsEqualGuid :: proc(a, b: ^GUID) -> bool {
    return a.Data1 == b.Data1 &&
           a.Data2 == b.Data2 &&
           a.Data3 == b.Data3 &&
           a.Data4 == b.Data4
}

// -------------------------------------------------------------------------
// Aliases (MF prefix stripped)
// -------------------------------------------------------------------------

Startup                         :: MFStartup
Shutdown                        :: MFShutdown
CreateAttributes                :: MFCreateAttributes
CreateMediaType                 :: MFCreateMediaType
CreatePresentationClock         :: MFCreatePresentationClock
EnumDeviceSources               :: MFEnumDeviceSources
CreateMediaSession              :: MFCreateMediaSession
CreateTopology                  :: MFCreateTopology
CreateTopologyNode              :: MFCreateTopologyNode
CreateSourceReaderFromMediaSource :: MFCreateSourceReaderFromMediaSource
CreateSourceResolver              :: MFCreateSourceResolver
CreatePresentationDescriptor      :: MFCreatePresentationDescriptor
CreateAudioRendererActivate   :: MFCreateAudioRendererActivate
CreateVideoRendererActivate   :: MFCreateVideoRendererActivate
GetService                    :: MFGetService
CreateTopoLoader              :: MFCreateTopoLoader
