def download_audio(url, output_path):
    from yt_dlp import YoutubeDL

    options = {
        "format": "bestaudio[ext=m4a][protocol^=http]",
        "outtmpl": output_path,
        "noplaylist": True,
        "noprogress": True,
        "cachedir": False,
        "js_runtimes": {},
        "socket_timeout": 15,
        "retries": 1,
        "extractor_retries": 1,
    }
    with YoutubeDL(options) as downloader:
        if downloader.download([url]) != 0:
            raise RuntimeError("yt-dlp could not download the audio track")

    return output_path
