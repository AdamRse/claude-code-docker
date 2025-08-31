#!/bin/bash

# Script d'appel pour Claude Code via Docker
# Usage: ./claude-code.sh [arguments claude-code]

# Vérification que la clé API existe
if [ ! -f "$HOME/.config/claude-code/api.key" ]; then
    echo "Erreur: Fichier de clé API non trouvé dans $HOME/.config/claude-code/api.key"
    exit 1
fi

# Obtenir l'UID et GID de l'utilisateur actuel
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Nom de l'image Docker
IMAGE_NAME="claude-code:latest"

# Répertoire courant (doit être dans $PJ)
CURRENT_DIR=$(pwd)

# Vérifier que nous sommes dans un sous-répertoire de $PJ
if [[ ! "$CURRENT_DIR" == "$PJ/"* ]]; then
    echo "Erreur: Ce script doit être exécuté depuis un répertoire dans $PJ/<répertoire_projet>"
    echo "Répertoire actuel: $CURRENT_DIR"
    echo "Répertoire attendu: $PJ/*"
    exit 1
fi

# Construire l'image si elle n'existe pas
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Construction de l'image Docker Claude Code..."
    docker build \
        --build-arg USER_ID=$USER_ID \
        --build-arg GROUP_ID=$GROUP_ID \
        -t "$IMAGE_NAME" \
        "$DEV/dockerfiles-projects/claude-code/"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la construction de l'image Docker"
        exit 1
    fi
fi

# Exécuter Claude Code dans le container
docker run --rm -it \
    --user adam \
    -v "$CURRENT_DIR:/workspace" \
    -v "$HOME/.config/claude-code:/home/adam/.config/claude-code" \
    -e ANTHROPIC_API_KEY="$(cat $HOME/.config/claude-code/api.key)" \
    "$IMAGE_NAME" "$@"