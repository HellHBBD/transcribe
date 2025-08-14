#!/usr/bin/env bash

# Check for URL argument
if [ -z "$1" ]; then
  echo "Usage: $0 <youtube-url>"
  exit 1
fi

URL="$1"

# Create directories if they don't exist
mkdir -p videos
mkdir -p texts

# Base options for yt-dlp, using an array for safety and clarity
# This will attempt to download author-uploaded subtitles first,
# and fall back to auto-generated subtitles if none are available.
ytdlp_args=(
    --write-subs
    --write-auto-subs
    --sub-lang "en.*"
    --convert-subs srt
    -o "videos/%(title)s.%(ext)s"
)

# Execute the download
echo "Downloading video and subtitles..."
yt-dlp "${ytdlp_args[@]}" "$URL"

# Move any downloaded .srt files to the texts directory
for srt_file in videos/*.srt; do
    if [ -e "$srt_file" ]; then
        echo "Moving subtitle file: $srt_file"
        mv "$srt_file" texts/
    fi
done

echo "Process complete."
