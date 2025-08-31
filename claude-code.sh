#!/bin/bash

# Script d'appel pour Claude Code via Docker
# Usage: ./claude-code.sh [arguments claude-code]

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérification que la clé API existe
if [ ! -f "$HOME/.config/claude-code/api.key" ]; then
    echo -e "${RED}Erreur: Fichier de clé API non trouvé dans $HOME/.config/claude-code/api.key${NC}"
    exit 1
fi

# Obtenir l'UID et GID de l'utilisateur actuel
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Nom de l'image et du container Docker
IMAGE_NAME="claude-code:latest"
CONTAINER_NAME="claude-code-${USER}-$(basename "$PWD")"

# Répertoire courant (doit être dans $PJ)
CURRENT_DIR=$(pwd)

# Vérifier que nous sommes dans un sous-répertoire de $PJ
if [[ ! "$CURRENT_DIR" == "$PJ/"* ]]; then
    echo -e "${RED}Erreur: Ce script doit être exécuté depuis un répertoire dans $PJ/<répertoire_projet>${NC}"
    echo "Répertoire actuel: $CURRENT_DIR"
    echo "Répertoire attendu: $PJ/*"
    exit 1
fi

# Construire l'image si elle n'existe pas
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}Construction de l'image Docker Claude Code...${NC}"
    docker build \
        --build-arg USER_ID=$USER_ID \
        --build-arg GROUP_ID=$GROUP_ID \
        -t "$IMAGE_NAME" \
        "$DEV/dockerfiles-projects/claude-code/"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la construction de l'image Docker${NC}"
        exit 1
    fi
    echo -e "${GREEN}Image construite avec succès${NC}"
fi

# Créer un volume persistant pour la configuration Claude Code
VOLUME_NAME="claude-code-config-${USER}"
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}Création du volume persistant pour la configuration...${NC}"
    docker volume create "$VOLUME_NAME"
fi

# Fonction pour arrêter proprement le container existant
cleanup_container() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        echo -e "${YELLOW}Arrêt du container existant...${NC}"
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
}

# Nettoyer les containers existants
cleanup_container

# Si aucun argument n'est fourni, lancer en mode interactif
if [ $# -eq 0 ]; then
    echo -e "${GREEN}Lancement de Claude Code en mode interactif...${NC}"
    echo -e "${YELLOW}Tapez 'exit' pour quitter le container${NC}"
    
    docker run -it \
        --name "$CONTAINER_NAME" \
        --user adam \
        -v "$CURRENT_DIR:/workspace" \
        -v "$VOLUME_NAME:/home/adam/.config/claude-code" \
        -v "$HOME/.config/claude-code/api.key:/home/adam/.config/claude-code/api.key:ro" \
        -e ANTHROPIC_API_KEY="$(cat $HOME/.config/claude-code/api.key)" \
        "$IMAGE_NAME" \
        "cd /workspace && exec /bin/bash"
else
    # Exécuter une commande spécifique
    echo -e "${GREEN}Exécution de: claude $*${NC}"
    
    docker run --rm \
        --user adam \
        -v "$CURRENT_DIR:/workspace" \
        -v "$VOLUME_NAME:/home/adam/.config/claude-code" \
        -v "$HOME/.config/claude-code/api.key:/home/adam/.config/claude-code/api.key:ro" \
        -e ANTHROPIC_API_KEY="$(cat $HOME/.config/claude-code/api.key)" \
        "$IMAGE_NAME" \
        "cd /workspace && claude $*"
fi

# Nettoyage en cas d'interruption
trap cleanup_container EXIT