#!/usr/bin/env bash

# Change to the directory where the script is located
cd "$(dirname "$(realpath "$0")")"

# Ads.
ads=(
    "https://raw.githubusercontent.com/lassekongo83/Frellwits-filter-lists/master/Frellwits-Swedish-Hosts-File.txt"
    "https://v.firebog.net/hosts/AdguardDNS.txt"
)

# Trackers.
trackers=(
    "https://v.firebog.net/hosts/Easyprivacy.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.amazon.txt"
    #"https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.apple.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.huawei.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.winoffice.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.tiktok.extended.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.lgwebos.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.vivo.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.oppo-realme.txt"
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/native.xiaomi.txt"
    "https://raw.githubusercontent.com/mullvad/dns-blocklists/refs/heads/main/files/tracker"
)

# Social.
social=(
    "https://raw.githubusercontent.com/mullvad/dns-blocklists/refs/heads/main/files/social"
)

# Gambling.
gambling=(
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/gambling-onlydomains.txt"
)

# Malware.
malware=(
    "https://urlhaus.abuse.ch/downloads/hostfile"
)

# Process each list and generate a corresponding .conf file.
process_url_list() {
    # URL list as array and output file.
    local urls=("${!1}")
    local output_file="$2"

    # Temporary file for storing all domains.
    local temp_file
    temp_file=$(mktemp)

    # Fetch and process each URL.
    for url in "${urls[@]}"; do
        # Fetch and sanitize the content.
        curl -s "$url" \
            | sed -E 's/\r//g; /^#/d; /^$/d; s/^(0\.0\.0\.0|127\.0\.0\.1)[[:space:]]+//g' \
            >> "$temp_file"
    done

    # Sort, remove duplicates in one step using sort -u, then format for unbound with always_null.
    echo "server:" > "$output_file"
    sort -u "$temp_file" | awk '{print "local-zone: \""$1"\" always_null"}' >> "$output_file"

    # Clean up.
    rm "$temp_file"
}

# Process each category and generate the corresponding .conf file.
process_url_list ads[@] "ads.conf"
process_url_list trackers[@] "trackers.conf"
process_url_list social[@] "social.conf"
process_url_list gambling[@] "gambling.conf"
process_url_list malware[@] "malware.conf"

# Check if config is invalid, then exit.
if ! unbound-checkconf ./_unbound.conf 2> >(grep -v 'warning: duplicate local-zone'); then
    exit 1
fi
