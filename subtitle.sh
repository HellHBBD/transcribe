#!/usr/bin/env bash

# Check for arguments
if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 <youtube-url> <language>"
	echo "  language: en or zh"
	exit 1
fi

url="$1"
lang="$2"
shift 2 # Remove the URL and lang from the arguments, the rest are options for whisper

# Create directories
temp_dir="temp"
texts_dir="texts"
video_dir="videos"
mkdir -p "$temp_dir" "$texts_dir" "$video_dir"

# Download best quality video
echo "Downloading best quality video..."
yt-dlp -f "bestvideo+bestaudio/best" -o "$video_dir/%(title)s.%(ext)s" "$url"

# Find the latest downloaded video file
videofile_name="$(ls -t "$video_dir" | head -n 1)"
if [ -z "$videofile_name" ]; then
	echo "Download failed, video file not found."
	exit 1
fi
videofile="$video_dir/$videofile_name"

# Prepare filenames
base_name="${videofile_name%.*}"
mp3file="$temp_dir/$base_name.mp3"
final_output_file="$texts_dir/$base_name.srt"
whisper_output_file="$temp_dir/$base_name.mp3.srt"

# Extract audio from video
echo "Extracting audio from video..."
ffmpeg -y -i "$videofile" -vn -codec:a libmp3lame -qscale:a 2 "$mp3file"

# Whisper transcription (output will be in the audio file's directory)
echo "Transcribing audio to srt..."
./whisper.cpp/build/bin/whisper-cli -m ./whisper.cpp/models/ggml-large-v3-turbo-q8_0.bin \
	-f "$mp3file" \
	--split-on-word \
	"$@" \
	--print-progress \
	-l "$lang" \
	-osrt

if [ "$lang" = "zh" ]; then
	# OpenCC Simplified to Traditional Chinese conversion
	echo "Converting to Traditional Chinese..."
	opencc -c s2t.json -i "$whisper_output_file" -o "$final_output_file"
else
	# For other languages, just move the file
	echo "Moving subtitle file..."
	mv "$whisper_output_file" "$final_output_file"
fi

echo "Output file: $final_output_file"

echo "Processing complete!"
