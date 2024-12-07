#!/bin/bash

# Show usage information if no arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory_path>"
    echo "Example: $0 ./scenes/player"
    exit 1
fi

# Get the directory path from the first argument
directory_path="$1"

# Validate that the directory exists and is accessible
if [ ! -d "$directory_path" ]; then
    echo "Error: Directory '$directory_path' does not exist or is not accessible"
    exit 1
fi

# Create output filename based on the directory name
# This creates a more meaningful output file name
output_file="$(basename "$directory_path")_files_combined.txt"

# Create a header with information about what we're processing
echo "Godot Project Files from: $directory_path" > "$output_file"
echo "Generated: $(date)" >> "$output_file"
echo "=======================================" >> "$output_file"

# Process GDScript files
echo -e "\nGDScript Files" >> "$output_file"
echo "-------------" >> "$output_file"

# Note how we now use $directory_path in our find command
find "$directory_path" -type f -name "*.gd" | sort | while read -r file; do
    echo -e "\n=== GDScript: $file ===" >> "$output_file"
    echo "Modified: $(stat -f "%Sm" "$file")" >> "$output_file"
    echo "Lines: $(wc -l < "$file")" >> "$output_file"
    echo "-----------------------------------" >> "$output_file"
    cat "$file" >> "$output_file"
    echo -e "\n-----------------------------------\n" >> "$output_file"
done

# Process Scene files
echo -e "\nScene Files" >> "$output_file"
echo "-----------" >> "$output_file"

find "$directory_path" -type f -name "*.tscn" | sort | while read -r file; do
    echo -e "\n=== Scene: $file ===" >> "$output_file"
    echo "Modified: $(stat -f "%Sm" "$file")" >> "$output_file"
    echo "Referenced Scripts:" >> "$output_file"
    grep 'script/source' "$file" | sed 's/.*script\/source *= *"\(.*\)".*/\1/' >> "$output_file"
    echo "-----------------------------------" >> "$output_file"
    cat "$file" >> "$output_file"
    echo -e "\n-----------------------------------\n" >> "$output_file"
done

# Provide feedback about the operation
echo "Processing complete! Output saved to: $output_file"
