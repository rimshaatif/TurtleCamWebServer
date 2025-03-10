#!/bin/bash

# Download dependency, in case they don't have it
sudo apt install jq

# Function to take a picture
take_picture() {
  local filename="picture_$(date +%Y-%m-%d__%H-%M-%S).jpg"
  libcamera-still -o "$output_dir/$filename" --width 640 --height 480 --quality 80
  echo "Picture saved as $output_dir/$filename"
}

# Function to record a video
record_video() {
  local duration_ms=$(( $1 * 1000 ))  # Convert seconds to milliseconds
  local filename="video_$(date +%Y-%m-%d__%H-%M-%S).h264"
  
  # Suppress libcamera-vid output
  libcamera-vid -o "$output_dir/$filename" -t "$duration_ms" --framerate $2 > /dev/null 2>&1
  echo "Video recorded as $output_dir/$filename"

  # Convert to MP4 (Suppress ffmpeg output)
  local mp4_filename="${filename%.h264}.mp4"
  ffmpeg -i "$output_dir/$filename" -c:v copy "$output_dir/$mp4_filename" > /dev/null 2>&1
  echo "Video converted to $output_dir/$mp4_filename"
}

# Function to process the schedule
process_schedule() {
  local schedule_file="$1"

  #output file
  output_dir=$(jq -r .output_dir "$schedule_file")
  mkdir $output_dir

  #start delay
  start_delay=$(jq .start_delay "$schedule_file")
  sleep "$start_delay"

  # Read the task list into an array
  mapfile -t tasks < <(jq -c '.task_list[]' "$schedule_file")
  
  # Read and process the JSON schedule using jq
  #jq -c '.task_list[]' "$schedule_file" | while IFS= read -r task; do
  for task in "${tasks[@]}"; do
    type=$(echo "$task" | jq -r '.type')
    duration=$(echo "$task" | jq -r '.duration // empty')
    pause=$(echo "$task" | jq -r '.pause // empty')
    framerate=$(echo "$task" | jq -r '.framerate // empty')
    
    echo "Processing task: $type"

    if [ "$type" = "picture" ]; then
        echo "Taking a picture..."
        take_picture
    elif [ "$type" = "video" ]; then
        if [ -n "$duration" ]; then
            echo "Recording a video for $duration seconds..."
            record_video "$duration" "$framerate"
        else
            echo "Error: Video task requires a duration."
            continue
        fi
    else
        echo "Unknown task type: $type"
        continue
    fi

    # Pause after the task if specified
    if [ -n "$pause" ]; then
        echo "Pausing for $pause seconds..."
        sleep "$pause"
    fi
    done
}

# Main script execution
if [ $# -ne 1 ]; then
  echo "Usage: $0 <schedule_file>"
  exit 1
fi

schedule_file="$1"
if [ ! -f "$schedule_file" ]; then
  echo "Error: Schedule file not found!"
  exit 1
fi

process_schedule "$schedule_file"
