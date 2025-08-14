# Transcribe

This project uses `whisper.cpp` to transcribe audio files or YouTube videos.

## Prerequisites

Before you begin, ensure you have the following dependencies installed.

**Required:**
- `cmake`: For compiling `whisper.cpp`.
- `ffmpeg`: For audio conversion and extraction.
- `yt-dlp`: For downloading YouTube videos.

**Optional:**
- `opencc`: Required only if you need to convert between Simplified and Traditional Chinese (`zh` language option).
- `cpulimit`: Used by `build.sh` to limit CPU usage during compilation.

## 1. Installation

### 1.1. Clone Repository

This repository uses `git submodule` to include `whisper.cpp`.

To clone this repository and the submodule, run:
```bash
git clone --recursive https://github.com/hellhbbd/transcribe.git
cd transcribe
```

If you have already cloned the repository without the `--recursive` flag, run this from the repository's root directory:
```bash
git submodule update --init --recursive
```

### 1.2. Build `whisper.cpp`

The project needs to be compiled. The `build.sh` script is configured for NVIDIA GPUs (CUDA).
```bash
./build.sh
```
This will start the compilation in the background. You can monitor the progress in `whisper.cpp/build-logs/`.

### 1.3. Download Model

You need to download a pre-trained model. The scripts are configured to use `large-v3-turbo-q8_0`, which offers a good balance of performance and quality.
```bash
./whisper.cpp/models/download-ggml-model.sh large-v3-turbo-q8_0
```
The model will be saved in the `whisper.cpp/models/` directory.

## 2. Usage

### 2.1. Transcribe Local Audio File

To transcribe an audio or video file. The script will automatically convert it to the required audio format.
```bash
./transcribe.sh [audio-file] [format] [language]
```
- `[audio-file]`: Path to your audio or video file.
- `[format]`: `txt`, `vtt`, `srt`, `lrc`, `csv`, `json`.
- `[language]`: `en` for English, `zh` for Traditional Chinese.

**Example:**
```bash
./transcribe.sh my_talk.mp4 srt en
```
The output file `my_talk.srt` will be created in the same directory.

### 2.2. Generate Subtitles from YouTube

To download a YouTube video and generate its subtitles:
```bash
./subtitle.sh [youtube-url] [language]
```
- `[youtube-url]`: The URL of the YouTube video.
- `[language]`: `en` for English, `zh` for Traditional Chinese.

The script will download the video to the `videos/` directory and save the generated `.srt` file in the `texts/` directory.

**Example:**
```bash
./subtitle.sh "https://www.youtube.com/watch?v=dQw4w9WgXcQ" en
```
