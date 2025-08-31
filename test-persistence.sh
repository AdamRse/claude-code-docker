#!/bin/bash

# Script pour tester la persistance de la configuration Claude Code
# Usage: ./test-persistence.sh

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

echo -e "${BLUE}=== Test de Persistance Claude Code ===${NC}"
echo ""

# Fonction pour créer un fichier de test dans un volume
create_test_file() {
    local volume=$1
    local path=$2
    local filename=$3
    local content=$4
    
    echo -e "${YELLOW}Création d'un fichier test dans $volume:$path/$filename${NC}"
    docker run --rm \
        --user adam \
        -v "$volume:$path" \
        -e HOME=/home/adam \
        alpine sh -c "echo '$content' > $path/$filename && echo 'Fichier créé: $(cat $path/$filename)'"
}

# Fonction pour vérifier si un fichier existe dans un volume
check_test_file() {
    local volume=$1
    local path=$2
    local filename=$3
    
    echo -e "${YELLOW}Vérification du fichier $volume:$path/$filename${NC}"
    result=$(docker run --rm \
        --user adam \
        -v "$volume:$path" \
        alpine sh -c "if [ -f $path/$filename ]; then echo 'EXISTS:' && cat $path/$filename; else echo 'NOT_FOUND'; fi")
    
    if [[ $result == "NOT_FOUND" ]]; then
        echo -e "${RED}✗ Fichier non trouvé${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Fichier trouvé: ${result#EXISTS:}${NC}"
        return 0
    fi
}

# Créer les volumes s'ils n'existent pas
for volume in "$CONFIG_VOLUME" "$CACHE_VOLUME" "$DATA_VOLUME"; do
    if ! docker volume inspect "$volume" >/dev/null 2>&1; then
        echo -e "${YELLOW}Création du volume $volume...${NC}"
        docker volume create "$volume"
    fi
done

echo ""
echo -e "${BLUE}Phase 1: Création de fichiers de test${NC}"

# Créer des fichiers de test dans chaque volume
create_test_file "$CONFIG_VOLUME" "/home/adam/.config" "test-config.txt" "Configuration test - $(date)"
create_test_file "$CACHE_VOLUME" "/home/adam/.cache" "test-cache.txt" "Cache test - $(date)"  
create_test_file "$DATA_VOLUME" "/home/adam/.local/share" "test-data.txt" "Data test - $(date)"

echo ""
echo -e "${BLUE}Phase 2: Vérification immédiate${NC}"

# Vérifier que les fichiers ont été créés
check_test_file "$CONFIG_VOLUME" "/home/adam/.config" "test-config.txt"
check_test_file "$CACHE_VOLUME" "/home/adam/.cache" "test-cache.txt"
check_test_file "$DATA_VOLUME" "/home/adam/.local/share" "test-data.txt"

echo ""
echo -e "${BLUE}Phase 3: Simulation d'un lancement Claude Code${NC}"

# Simuler ce que fait claude-code au lancement
echo -e "${YELLOW}Test avec les mêmes volumes que claude-code...${NC}"
docker run --rm -it \
    --user adam \
    -v "$(pwd):/workspace" \
    -v "$CONFIG_VOLUME:/home/adam/.config" \
    -v "$CACHE_VOLUME:/home/adam/.cache" \
    -v "$DATA_VOLUME:/home/adam/.local/share" \
    -e SHELL=/bin/bash \
    -e HOME=/home/adam \
    "$IMAGE_NAME" \
    'echo "=== Vérification de la persistance ===" && 
     echo "Config:" && ls -la /home/adam/.config/ && 
     echo "Cache:" && ls -la /home/adam/.cache/ && 
     echo "Data:" && ls -la /home/adam/.local/share/ &&
     echo "=== Contenu des fichiers test ===" &&
     cat /home/adam/.config/test-config.txt 2>/dev/null || echo "Config test file missing" &&
     cat /home/adam/.cache/test-cache.txt 2>/dev/null || echo "Cache test file missing" &&
     cat /home/adam/.local/share/test-data.txt 2>/dev/null || echo "Data test file missing" &&
     echo "=== Test terminé ==="'

echo ""
echo -e "${BLUE}Phase 4: Test final de persistance${NC}"

# Vérifier une dernière fois que les fichiers sont toujours là
all_good=true
check_test_file "$CONFIG_VOLUME" "/home/adam/.config" "test-config.txt" || all_good=false
check_test_file "$CACHE_VOLUME" "/home/adam/.cache" "test-cache.txt" || all_good=false  
check_test_file "$DATA_VOLUME" "/home/adam/.local/share" "test-data.txt" || all_good=false

echo ""
if $all_good; then
    echo -e "${GREEN}🎉 Test de persistance RÉUSSI ! Les volumes fonctionnent correctement.${NC}"
    echo -e "${GREEN}La configuration Claude Code devrait persister entre les sessions.${NC}"
else
    echo -e "${RED}❌ Test de persistance ÉCHOUÉ ! Problème avec les volumes Docker.${NC}"
    echo -e "${RED}La configuration Claude Code ne persistera pas.${NC}"
fi

echo ""
echo -e "${BLUE}Nettoyage des fichiers de test...${NC}"
docker run --rm -v "$CONFIG_VOLUME:/config" alpine rm -f /config/test-config.txt 2>/dev/null || true
docker run --rm -v "$CACHE_VOLUME:/cache" alpine rm -f /cache/test-cache.txt 2>/dev/null || true  
docker run --rm -v "$DATA_VOLUME:/data" alpine rm -f /data/test-data.txt 2>/dev/null || true
echo -e "${GREEN}Nettoyage terminé.${NC}"