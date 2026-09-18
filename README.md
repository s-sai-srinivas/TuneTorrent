# TuneTorrent Manager

Sideloaded iPhone app: Music Player | Torrent Downloader | File Manager

## Build
Push to GitHub -> Actions `build-ipa` on `macos-14` -> download `TuneTorrent-ipa` artifact.

## Install via iloader (Windows)
1. Download artifact zip -> unzip `TuneTorrent.ipa`
2. Plug iPhone via USB -> open iloader -> Import IPA -> Install
3. Trust device if prompted

## Stack
Swift 5.10 + SwiftUI + SwiftData, iOS 17.4+, MVVM + Actor for torrent

## Phases
Phase 0 done: TabView shell + models + services stubs. Next: Phase 1 Music.
