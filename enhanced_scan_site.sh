#!/bin/bash

# List of initial URLs to scan
declare -a urls=("https://tumnet.com/en/")
# Array to keep track of visited URLs
declare -a visited_urls=()

# String pattern to search for
search_string="apidevst"

# User-agent header to use (optional)
user_agent="Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

# Maximum depth for recursive scanning
max_depth=2

# Delay between requests in seconds
delay_secs=2

# Function to normalize URLs
normalize_url() {
    local url="$1"
    local base_url="$2"

    # If the URL is relative, prepend the base URL
    if [[ $url == /* ]]; then
        echo "$(dirname "$base_url")${url}"
    else
        echo "$url"
    fi
}

# Function to scan a single URL
scan_url () {
    local url="$1"
    local depth="$2"

    echo "Scanning $url... (Depth: $depth)"

    # Fetch the page content and remove null bytes
    content=$(curl -A "$user_agent" -s "$url" | tr -d '\000')
    
    # Check if the pattern exists in the content
    if echo "$content" | grep -qi "$search_string"; then
        echo "Pattern found in $url"
    else
        echo "Pattern not found in $url"
    fi

    # Mark URL as visited
    visited_urls+=("$url")

    # If we've reached the maximum depth, return
    if [ "$depth" -ge "$max_depth" ]; then
        return
    fi

    # Extract all URLs from href and src attributes, including .css, .js, and image files
    sub_urls=$(echo "$content" | grep -oP '(?<=href=")[^"]*|(?<=src=")[^"]*|(?<=href=\x27)[^\x27]*|(?<=src=\x27)[^\x27]*' | grep -E '^https?://|^/[^/]|(\.css$|\.js$|\.png$|\.jpg$|\.jpeg$|\.gif$)')

    echo "Sub-URLs found on $url:"

    # Print each sub-URL for debugging and normalize relative URLs
    for raw_sub_url in $sub_urls; do
        sub_url=$(normalize_url "$raw_sub_url" "$url")
        echo "  $sub_url"
    done
    
    # Scan each sub-URL if they have not been visited
    for raw_sub_url in $sub_urls; do
        sub_url=$(normalize_url "$raw_sub_url" "$url")
        if [[ ! " ${visited_urls[@]} " =~ " ${sub_url} " ]]; then
            urls+=("$sub_url")
            visited_urls+=("$sub_url")

            # Delay before scanning the next URL
            sleep $delay_secs

            scan_url "$sub_url" $((depth + 1))
        fi
    done
}

# Start scanning from the initial URLs
for url in "${urls[@]}"; do
    scan_url "$url" 0
done