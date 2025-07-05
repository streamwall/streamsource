#!/bin/bash

# DigitalOcean API script to power on the droplet
# Run this from another server or local machine via cron

# Configuration
DO_API_TOKEN="your-digitalocean-api-token"
DROPLET_ID="your-droplet-id"

# Power on the droplet
echo "Powering on droplet..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" \
  -d '{"type":"power_on"}'

echo "Power on command sent. Droplet should be starting..."

# Optional: Wait and check status
sleep 30
curl -X GET \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID" \
  | jq '.droplet.status'

# To find your droplet ID:
# curl -X GET -H "Authorization: Bearer $DO_API_TOKEN" "https://api.digitalocean.com/v2/droplets" | jq '.droplets[] | {id, name}'