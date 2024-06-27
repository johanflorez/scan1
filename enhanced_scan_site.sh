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
max_depth=8

# Delay between requests in seconds
delay_secs=2

# Function to scan a single URL
scan_url () {
    local url="$1"
    local depth="$2"

    echo "Scanning $url... (Depth: $depth)"

    # Fetch the page content
    content=$(curl -A "$user_agent" -s "$url")

    # Check if the pattern exists in the content
    if echo "$content" | grep -qi "$search_string"; then
        echo "Pattern found in $url"
    #else
        #echo "Pattern not found in $url"
    fi

    # Mark URL as visited
    visited_urls+=("$url")

    # If we've reached the maximum depth, return
    if [ "$depth" -ge "$max_depth" ]; then
        return
    fi

    # Extract sub-page URLs and scan them if they have not been visited
    sub_urls=$(echo "$content" | grep -oP '(?<=href=")[^"]*' | grep -E "^https?://tumnet.com")

    for sub_url in $sub_urls; do
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