#!/usr/bin/env bash
# 參數檢查
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Usage: $0 <audio-file> <format> <language>"
	echo "  format: txt | vtt | srt | lrc | csv | json | json-full"
	echo "  language: en or zh"
	exit 1
fi

file="$1"
fmt="$2"
lang="$3"

# 取得去除副檔名的基礎名稱
base="${file%.*}"

# 根據 fmt 決定 Whisper CLI 的輸出選項
case "$fmt" in
txt) opt="--output-txt" ;;
vtt) opt="--output-vtt" ;;
srt) opt="--output-srt" ;;
lrc) opt="--output-lrc" ;;
csv) opt="--output-csv" ;;
json) opt="--output-json" ;;
json-full) opt="--output-json-full" ;;
*)
	echo "Unsupported format: $fmt"
	echo "  format: txt | vtt | srt | lrc | csv | json | json-full"
	exit 1
	;;
esac

# 判斷是否為 mp3
ext="${file##*.}"
if [[ "$ext" =~ ^[Mm][Pp]3$ ]]; then
	mp3file="$file"
	echo "檔案已經是 mp3，跳過轉換。"
else
	mp3file="$base.mp3"
	# echo "ffmpeg $file to $mp3file"
	ffmpeg -i "$file" -vn -codec:a libmp3lame -qscale:a 2 "$mp3file"
fi

# echo "whisper $mp3file $opt"
./whisper.cpp/build/bin/whisper-cli -m ./models/ggml-large-v3-turbo-q8_0.bin -f "$mp3file" --split-on-word $opt --print-progress -l "$lang"

# Define output filenames
whisper_output_file="$mp3file.$fmt"
final_output_file="$base.$fmt"

if [ "$lang" = "zh" ]; then
	echo "Converting to Traditional Chinese..."
	opencc -c s2t.json -i "$whisper_output_file" -o "$final_output_file"
else
	# For other languages, just move the file
	echo "Moving output file..."
	mv "$whisper_output_file" "$final_output_file"
fi

echo "Output file: $final_output_file"
echo "Processing complete!"
