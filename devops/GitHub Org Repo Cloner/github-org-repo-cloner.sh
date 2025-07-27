#!/bin/bash

# Your GitHub organization name
ORG=""
# Your GitHub personal access token (leave blank for public repos)
GITHUB_TOKEN="ghp_sG[...]vtTj"
# Local directory where the repos will be cloned
DEST_DIR="$HOME/Documents/github/"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR" || exit 1

# API pagination
PAGE=1
PER_PAGE=100

while :; do
  echo "🔄 Fetching repos page $PAGE..."

  if [[ -z "$GITHUB_TOKEN" ]]; then
    RESPONSE=$(curl -s "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")
  else
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")
  fi

  COUNT=$(echo "$RESPONSE" | jq length)
  [[ "$COUNT" -eq 0 ]] && break

  echo "$RESPONSE" | jq -r '.[] | .ssh_url' | while read -r REPO_SSH_URL; do
    # Replace github.com with github-alias-account (your SSH alias) if you need.
    CUSTOM_SSH_URL=$(echo "$REPO_SSH_URL" | sed 's/git@github\.com:/git@github-alias-account:/')

    REPO_NAME=$(basename -s .git "$REPO_SSH_URL")
    if [[ -d "$REPO_NAME" ]]; then
      echo "✅ Repository $REPO_NAME already exists, skipping..."
    else
      echo "📥 Cloning $REPO_NAME..."
      git clone "$CUSTOM_SSH_URL"
    fi
  done

  ((PAGE++))
done

echo "🎉 All repositories from $ORG have been processed."
