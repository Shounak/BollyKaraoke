# BollyKaraoke

iOS app for singing Bollywood songs with custom pitch and tempo.

## Run the app

Install the pinned dependencies from the repository root.

```sh
bash scripts/bootstrap-python.sh
```

On an Apple Silicon Mac, open `BollyKaraoke.xcodeproj` and run the BollyKaraoke scheme on an iOS 27 simulator or device.

Tap **Download and Play** to fetch the audio for [Mere Khwabon Mein](https://www.youtube.com/watch?v=s1LozokQjIg). The app plays the M4A file and keeps it in Application Support for offline replay. The first download needs an internet connection.

Use **Pitch** to shift the key from −6 to +6 semitones and **Tempo** to adjust playback speed from 75% to 125%. Both sliders apply during playback. Set them to 0 semitones and 100% for the original key and tempo.

Xcode resolves PythonKit and embeds Python 3.14.10, yt-dlp, and the certifi certificate bundle. The bootstrap script verifies each download and stores the dependencies in the git-ignored `Dependencies/` directory.
