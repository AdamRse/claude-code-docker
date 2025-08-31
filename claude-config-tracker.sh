#!/bin/bash

# Script pour tracer où Claude Code stocke sa configuration
# Usage: ./claude-config-tracker.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_VOLUME="claude-code-config-${USER}"
CACHE_VOLUME="claude-code-cache-${USER}"
DATA_VOLUME="claude-code-data-${USER}"
IMAGE_NAME="claude-code:latest"

echo -e "${BLUE}=== Tracing Configuration Claude Code ===${NC}"
echo ""

# Fonction pour examiner le contenu complet d'un volume
examine_volume() {
    local volume=$1
    local mount_path=$2
    local volume_name=$3
    
    echo -e "${BLUE}=== Examen détaillé du volume $volume_name ($volume) ===${NC}"
    docker run --rm \
        --user adam \
        -v "$volume:$mount_path" \
        -e HOME=/home/adam \
        "$IMAGE_NAME" \
        "echo 'Contenu de $mount_path:' && find $mount_path -type f 2>/dev/null | head -20 && echo '--- Répertoires ---' && find $mount_path -type d 2>/dev/null | head -20"
    echo ""
}

# Examiner tous les volumes
examine_volume "$CONFIG_VOLUME" "/home/adam/.config" "CONFIG"
examine_volume "$CACHE_VOLUME" "/home/adam/.cache" "CACHE"  
examine_volume "$DATA_VOLUME" "/home/adam/.local/share" "DATA"

# Chercher spécifiquement les fichiers liés à Claude
echo -e "${BLUE}=== Recherche spécifique des fichiers Claude ===${NC}"
docker run --rm \
    --user adam \
    -v "$CONFIG_VOLUME:/home/adam/.config" \
    -v "$CACHE_VOLUME:/home/adam/.cache" \
    -v "$DATA_VOLUME:/home/adam/.local/share" \
    -e HOME=/home/adam \
    "$IMAGE_NAME" \
    'echo "=== Fichiers contenant claude dans le nom ===" &&
     find /home/adam -name "*claude*" -type f 2>/dev/null &&
     echo "=== Fichiers contenant anthropic dans le nom ===" &&
     find /home/adam -name "*anthropic*" -type f 2>/dev/null &&
     echo "=== Fichiers de configuration potentiels ===" &&
     find /home/adam -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "config*" -o -name "settings*" 2>/dev/null | head -10 &&
     echo "=== Répertoires claude ===" &&
     find /home/adam -name "*claude*" -type d 2>/dev/null &&
     echo "=== Répertoires anthropic ===" &&
     find /home/adam -name "*anthropic*" -type d 2>/dev/null'

echo ""
echo -e "${BLUE}=== Test de lancement Claude pour identifier la config ===${NC}"
echo -e "${YELLOW}Vérification de l'état initial...${NC}"

# Prendre un snapshot de l'état avant
docker run --rm \
    --user adam \
    -v "$CONFIG_VOLUME:/home/adam/.config" \
    -v "$CACHE_VOLUME:/home/adam/.cache" \
    -v "$DATA_VOLUME:/home/adam/.local/share" \
    -e HOME=/home/adam \
    "$IMAGE_NAME" \
    'echo "AVANT - Nombre de fichiers:" &&
     find /home/adam -type f 2>/dev/null | wc -l &&
     echo "AVANT - Fichiers récents:" &&
     find /home/adam -type f -newermt "1 minute ago" 2>/dev/null | head -5' > /tmp/claude_before.txt

echo ""
echo -e "${YELLOW}Maintenant, lancez Claude Code dans votre projet pour vous authentifier,${NC}"
echo -e "${YELLOW}puis fermez-le et relancez ce script avec l'option 'after' :${NC}"
echo ""
echo -e "${GREEN}Commandes à exécuter :${NC}"
echo "1. cd $PJ/votre-projet"
echo "2. claude-code"
echo "3. Suivez la configuration complète"  
echo "4. Fermez Claude Code"
echo "5. ./claude-config-tracker.sh after"