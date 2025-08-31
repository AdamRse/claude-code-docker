#!/bin/bash

# Script de débogage pour vérifier la configuration Claude Code
# Usage: ./claude-debug-config.sh

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

echo -e "${BLUE}=== Débogage Configuration Claude Code ===${NC}"
echo ""

# Créer les volumes manquants
echo -e "${YELLOW}Création des volumes manquants...${NC}"
for volume in "$CONFIG_VOLUME" "$CACHE_VOLUME" "$DATA_VOLUME"; do
    if ! docker volume inspect "$volume" >/dev/null 2>&1; then
        echo "Création du volume $volume..."
        docker volume create "$volume"
    fi
done
echo ""

# Vérifier les volumes et leur contenu
for volume in "$CONFIG_VOLUME" "$CACHE_VOLUME" "$DATA_VOLUME"; do
    echo -e "${BLUE}Volume: $volume${NC}"
    if docker volume inspect "$volume" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Volume présent${NC}"
        
        # Lister le contenu du volume
        echo "Contenu du volume:"
        docker run --rm -v "$volume:/check" alpine sh -c "find /check -type f -name '*claude*' -o -name '*config*' -o -name '*auth*' 2>/dev/null | head -20" || echo "  Aucun fichier trouvé"
        
        # Vérifier les permissions
        echo "Permissions:"
        docker run --rm -v "$volume:/check" alpine sh -c "ls -la /check 2>/dev/null | head -10" || echo "  Volume vide"
    else
        echo -e "${RED}✗ Volume manquant${NC}"
    fi
    echo ""
done

# Test rapide de création d'un container pour vérifier l'environnement
echo -e "${BLUE}Test de l'environnement container:${NC}"
docker run --rm \
    --user adam \
    -v "$CONFIG_VOLUME:/home/adam/.config" \
    -v "$CACHE_VOLUME:/home/adam/.cache" \
    -v "$DATA_VOLUME:/home/adam/.local/share" \
    -e SHELL=/bin/bash \
    -e HOME=/home/adam \
    "$IMAGE_NAME" \
    'echo "HOME: $HOME"; echo "SHELL: $SHELL"; echo "USER: $(whoami)"; ls -la /home/adam/ 2>/dev/null || echo "Répertoire home inaccessible"; which claude || echo "claude non trouvé"; echo "Version node: $(node --version)"; echo "Version claude: $(claude --version 2>/dev/null || echo 'claude --version failed')"'

echo ""
echo -e "${BLUE}Vérification des fichiers de configuration potentiels:${NC}"

# Chercher les fichiers de configuration dans les volumes
for volume in "$CONFIG_VOLUME" "$CACHE_VOLUME" "$DATA_VOLUME"; do
    echo -e "${YELLOW}Recherche dans $volume:${NC}"
    docker run --rm -v "$volume:/check" alpine sh -c "
        find /check -name '*.json' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' -o -name 'config*' -o -name '*token*' -o -name '*auth*' 2>/dev/null | while read file; do
            echo \"  \$file\"
            head -3 \"\$file\" 2>/dev/null | sed 's/^/    /'
        done
    " 2>/dev/null || echo "  Aucun fichier de configuration trouvé"
    echo ""
done