# Radio

Internet radio for the iPod touch 4. Forty-odd stations that still serve plain MP3 or AAC streams: Bay Area public radio and jazz, two dozen college stations from Berkeley to Princeton, SomaFM, KEXP, KCRW, WFMU. Background playback, lock screen and headphone clicker control, the song title from the stream, a sleep timer, and your own stations by URL.

## How internet radio works

A station runs an Icecast or Shoutcast server that pushes one endless MP3 or AAC stream over HTTP. The player opens that URL like a song that never ends. If the client asks with `Icy-MetaData: 1`, the server interleaves a small "StreamTitle" block every `icy-metaint` bytes, which is where the song title comes from.

## Layout

- `src/RDStations` is the preset list plus the user's own stations (NSUserDefaults).
- `src/RDPlayer` wraps one AVPlayer: audio session, state, interruptions, sleep timer, the lock screen info on iOS 5.
- `src/RDMeta` fetches the Icecast title with a short second request every 30 seconds, because AVPlayer on iOS 4 and 5 does not surface it.
- `src/RDViewControllers` is the station list with the tuner-style now-playing panel, the sleep action sheet and the add-station form.
- `res/mkicon.swift` draws the icon.

Stream addresses were checked on Oct 14 2026 with `curl`; the radio-browser.info directory is the place to find replacements when one goes dark.

## Building

Targets iOS 4.3 on armv7 from a modern Mac with only the Command Line Tools installed. No Xcode.

1. Put an iPhoneOS 4.3 SDK at `/Users/mshukla/ios4sdk/iPhoneOS4.3.sdk`.
2. The modern linker refuses the old dylibs, so convert them to text stubs once: run `tapi stubify` from the Command Line Tools over the SDK's frameworks and retarget the `-darwin` platform strings to `-ios`.
3. `./build.sh` compiles with `clang -target armv7-apple-ios4.3`, signs with `ldid -S`, and zips `build/Radio.ipa`.
4. Install with `ideviceinstaller install build/Radio.ipa` on a jailbroken device with AppSync.

Everything is hand-written Foundation and UIKit from 2011.

## License

MIT for the code. Station names and streams belong to the stations.
