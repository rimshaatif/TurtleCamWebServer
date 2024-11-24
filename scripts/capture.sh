#!/bin/bash

# Function to create directory if it does not exist
create_dir_if_not_exists() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Function to generate a unique filename by adding a timestamp or counter
generate_unique_filename() {
  local base_name="$1"
  local extension="$2"
  local output_dir="$3"
  local filename="${base_name}${extension}"
  
  # Check if file already exists, if so, append a timestamp to the filename
  if [ -e "$output_dir/$filename" ]; then
    timestamp=$(date +%Y%m%d%H%M%S)
    filename="${base_name}_${timestamp}${extension}"
  fi

  echo "$filename"
}

# Function to take a picture using libcamera
take_picture() {
  # Ensure output directory exists
  create_dir_if_not_exists "$output_dir"

  # Generate unique filename for the picture
  picture_filename=$(generate_unique_filename "picture" ".jpg" "$output_dir")

  # Use libcamera-still to take a picture and save it with the generated filename
  libcamera-still -o "$output_dir/$picture_filename" --width 640 --height 480 --quality 80
  echo "Picture taken and saved to $output_dir/$picture_filename"
}

# Function to record a video using libcamera
record_video() {
  # Ensure output directory exists
  create_dir_if_not_exists "$output_dir"

  # Generate unique filename for the video
  video_filename=$(generate_unique_filename "video" ".h264" "$output_dir")
  mp4_filename="${video_filename%.h264}.mp4"

  # Use libcamera-vid to record a video and save it with the generated filename
  libcamera-vid -o "$output_dir/$video_filename" -t "$(( 1000 * video_length ))" 
  echo "Video recorded and saved to $output_dir/$video_filename"

  # Convert the raw .h264 video to .mp4 using ffmpeg
  ffmpeg -i "$output_dir/$video_filename" -c:v copy "$output_dir/$mp4_filename"
  if [ $? -eq 0 ]; then
    echo "Video successfully converted to $output_dir/$mp4_filename"
  else
    echo "Error during video conversion"
  fi
}

# Main script execution
if [ "$1" == "picture" ]; then
  output_dir="$2"
  take_picture
elif [ "$1" == "video" ]; then
  if [ -z "$2" ]; then
    echo "Error: Please provide the video length in seconds (e.g., 10 for 10 seconds)"
    exit 1
  fi
  video_length="$2"
  echo "$video_length"
  output_dir="$3"
  record_video
else
  echo "Invalid option. Use 'picture' to take a picture or 'video' to record a video."
  exit 1
fi

