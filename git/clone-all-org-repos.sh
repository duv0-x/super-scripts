#!/bin/bash

# Configura esto con tu organización
ORG=""
# Token personal de GitHub con permiso de "repo" (solo si los repos son privados)
GITHUB_TOKEN="ghp_sG[...]vtTj"  # ← si son públicos, puedes dejar esto vacío
# Directorio donde se clonarán los repos
DEST_DIR="$HOME/Documents/github/"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR" || exit 1

# Paginación de la API
PAGE=1
PER_PAGE=100

while :; do
  echo "🔄 Obteniendo repos página $PAGE..."

  if [[ -z "$GITHUB_TOKEN" ]]; then
    RESPONSE=$(curl -s "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")
  else
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")
  fi

  COUNT=$(echo "$RESPONSE" | jq length)
  [[ "$COUNT" -eq 0 ]] && break

  echo "$RESPONSE" | jq -r '.[] | .ssh_url' | while read -r REPO_SSH_URL; do
    # Reemplaza github.com por github-alias-account (tu alias SSH)
    CUSTOM_SSH_URL=$(echo "$REPO_SSH_URL" | sed 's/git@github\.com:/git@github-alias-account:/')

    REPO_NAME=$(basename -s .git "$REPO_SSH_URL")
    if [[ -d "$REPO_NAME" ]]; then
      echo "✅ Repositorio $REPO_NAME ya existe, omitiendo..."
    else
      echo "📥 Clonando $REPO_NAME..."
      git clone "$CUSTOM_SSH_URL"
    fi
  done

  ((PAGE++))
done

echo "🎉 Todos los repositorios de $ORG han sido procesados."
