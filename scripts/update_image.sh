#!/bin/bash

# Usage: ./update_image.sh <filepath> <image_tag>
# Example: ./update_image.sh k8s/deployment.yaml v1.0.2

# Exit immediately if a command exits with a non-zero status
set -e

# Check arguments
if [ "$#" -ne 2 ]; then
  echo "❌ Usage: $0 <filepath> <image_tag>"
  exit 1
fi

FILEPATH="$1"
IMAGE_TAG="$2"

# Check if file exists
if [ ! -f "$FILEPATH" ]; then
  echo "❌ File not found: $FILEPATH"
  exit 1
fi

# Extract current image name (without tag)
IMAGE_NAME=$(grep 'image:' "$FILEPATH" | head -n 1 | awk '{print $2}' | cut -d':' -f1)

if [ -z "$IMAGE_NAME" ]; then
  echo "❌ Could not find image name in $FILEPATH"
  exit 1
fi

# Replace old image tag with the new one
sed -i "s|$IMAGE_NAME:[^[:space:]]*|$IMAGE_NAME:$IMAGE_TAG|g" "$FILEPATH"

echo "✅ Updated image tag in $FILEPATH"
echo "➡️  New image: $IMAGE_NAME:$IMAGE_TAG"
