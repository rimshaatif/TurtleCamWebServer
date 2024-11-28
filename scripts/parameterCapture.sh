#!/bin/bash

CONFIG_FILE="config.json"

# Validate configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found!"
    exit 1
fi

# Read parameters from JSON
timeDelay=$(jq -r '.timeDelay' "$CONFIG_FILE")
videoLength=$(jq -r '.vidLength' "$CONFIG_FILE")
outputDir=$(jq -r '.outputDir' "$CONFIG_FILE")

# Validate parameters
if [ "$timeDelay" -lt 0 ]; then
    echo "Error: Time delay cannot be negative."
    exit 1
fi

if [ "$videoLength" -lt 0 ]; then
    echo "Error: Video length cannot be negative."
    exit 1
fi

if [ -z "$outputDir" ] || [ "$outputDir" == "null" ]; then
    echo "Error: Output directory cannot be empty."
    exit 1
fi

# Function to create directory if it does not exist
create_dir_if_not_exists() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Function to generate a unique filename
generate_unique_filename() {
  local base_name="$1"
  local extension="$2"
  local output_dir="$3"
  local filename="${base_name}${extension}"
  
  if [ -e "$output_dir/$filename" ]; then
    timestamp=$(date +%Y%m%d%H%M%S)
    filename="${base_name}_${timestamp}${extension}"
  fi

  echo "$filename"
}

# Function to take a picture using libcamera
take_picture() {
  create_dir_if_not_exists "$outputDir"
  local picture_filename=$(generate_unique_filename "picture" ".jpg" "$outputDir")
  libcamera-still -o "$outputDir/$picture_filename" --width 640 --height 480 --quality 80
  echo "Picture taken and saved to $outputDir/$picture_filename"
}

# Function to record a video using libcamera
record_video() {
  create_dir_if_not_exists "$outputDir"
  local video_filename=$(generate_unique_filename "video" ".h264" "$outputDir")
  local mp4_filename="${video_filename%.h264}.mp4"

  libcamera-vid -o "$outputDir/$video_filename" -t "$(( 1000 * videoLength ))"
  echo "Video recorded and saved to $outputDir/$video_filename"

  ffmpeg -i "$outputDir/$video_filename" -c:v copy "$outputDir/$mp4_filename"
  if [ $? -eq 0 ]; then
    echo "Video successfully converted to $outputDir/$mp4_filename"
  else
    echo "Error during video conversion"
  fi
}

# Main script execution
if [ "$1" == "picture" ]; then
  sleep $timeDelay
  take_picture
elif [ "$1" == "video" ]; then
  sleep $timeDelay
  record_video
else
  echo "Invalid. Use 'picture' to take a picture or 'video' to record a video."
  exit 1
fi
