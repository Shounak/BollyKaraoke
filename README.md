# BollyKaraoke

iOS app for singing Bollywood songs with custom pitch and tempo.

## Run the version check

From the repository root, download the pinned Python runtime and yt-dlp package:

```sh
bash scripts/bootstrap-python.sh
```

On an Apple Silicon Mac, open `BollyKaraoke.xcodeproj` and run the BollyKaraoke scheme in Xcode on an iOS 27 simulator or device. Tap **Check yt-dlp version**. The app runs `yt-dlp --version` through PythonKit and displays `2026.11.23` on screen and in the Xcode console.

The bootstrap script verifies both downloads and puts them in the git-ignored `Dependencies/` directory. Xcode resolves PythonKit and embeds Python 3.14.10 and yt-dlp in the app bundle. The version check runs offline.
