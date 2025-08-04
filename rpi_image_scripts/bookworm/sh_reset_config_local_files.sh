#!/bin/bash

# Set the target directory.  If no argument is given, use the current directory.
if [ -z "$1" ]; then
  target_dir="/home/pi/drone_engage/"
else
  target_dir="$1"
fi

# Check if the target directory exists.
if ! [ -d "$target_dir" ]; then
  echo "Error: Target directory '$target_dir' does not exist."
  exit 1
fi

# Find and delete files ending with .local
find "$target_dir" -type f -name "*.local" -print0 |
  while IFS= read -r -d $'\0' file; do
    echo "Deleting file: '$file'"  #  Added to show exactly what is being deleted.
    rm -f "$file"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to delete file: '$file'"
    fi
  done

echo "Finished deleting .local files in '$target_dir' and its subdirectories."
