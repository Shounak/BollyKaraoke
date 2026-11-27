# BollyKaraoke

iOS app for singing Bollywood songs with custom pitch and tempo.

## Run the app

Install the pinned dependencies from the repository root.

```sh
bash scripts/bootstrap-python.sh
```

On an Apple Silicon Mac, open `BollyKaraoke.xcodeproj` and run the BollyKaraoke scheme on an iOS 27 simulator or device.

In **Library**, tap **Download & play** on [Mere Khwabon Mein](https://www.youtube.com/watch?v=s1LozokQjIg). The app keeps the audio in Application Support and lists it under **Downloads** for offline replay. The search field filters downloaded songs by title or subtitle.

In **Player**, drag the timeline to seek or tap a 10-second skip control. **Pitch** shifts the key from −6 to +6 semitones and **Tempo** adjusts speed from 75% to 125%. Both controls apply during playback, and each song remembers its settings. **Reset** restores the original key and tempo.

Xcode resolves PythonKit and embeds Python 3.14.10, yt-dlp, and the certifi certificate bundle. The bootstrap script verifies each download and stores the dependencies in the git-ignored `Dependencies/` directory.
