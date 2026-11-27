# BollyKaraoke

iOS app for singing Bollywood songs with custom pitch and tempo.

## Run the app

Install the pinned dependencies from the repository root.

```sh
bash scripts/bootstrap-python.sh
```

On an Apple Silicon Mac, open `BollyKaraoke.xcodeproj` and run the BollyKaraoke scheme on an iOS 27 simulator or device.

In **Search**, enter a song, film, or artist and tap **Search**. Tap **Load more results** for the next page, or choose a video to download and play its audio. The app keeps the audio in Application Support and lists it under **Downloads** in **Library** for offline replay. The Library search field filters downloads by title or subtitle.

In **Player**, drag the timeline to seek or tap a 10-second skip control. **Pitch** shifts the key from −6 to +6 semitones and **Tempo** adjusts speed from 75% to 125%. Both controls apply during playback, and each song remembers its settings. **Reset** restores the original key and tempo.

Xcode resolves PythonKit and YouTubeKit and embeds Python 3.14.10, yt-dlp, and the certifi certificate bundle. The bootstrap script verifies each download and stores the dependencies in the git-ignored `Dependencies/` directory. Search runs on device without a Google Cloud API key and uses YouTubeKit’s undocumented YouTube endpoint.
