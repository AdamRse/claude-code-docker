#!/bin/bash

# Utilitaire de gestion pour Claude Code Docker
# Usage: ./claude-code-manager.sh [commande]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

IMAGE_NAME="claude-code:latest"
VOLUME_NAME="claude-code-config-${USER}"

show_help() {
    echo -e "${BLUE}Claude Code Docker Manager${NC}"
    echo ""
    echo "Usage: $0 [commande]"
    echo ""
    echo "Commandes disponibles:"
    echo "  status     - Afficher l'état des containers et volumes"
    echo "  clean      - Nettoyer les containers arrêtés"
    echo "  reset      - Réinitialiser complètement (supprime la config)"
    echo "  rebuild    - Reconstruire l'image Docker"
    echo "  logs       - Afficher les logs du container actuel"
    echo "  shell      - Ouvrir un shell dans un nouveau container"
    echo "  help       - Afficher cette aide"
    echo ""
}

show_status() {
    echo -e "${BLUE}=== Status Claude Code Docker ===${NC}"
    echo ""
    
    # Image
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Image '$IMAGE_NAME' présente${NC}"
    else
        echo -e "${RED}✗ Image '$IMAGE_NAME' manquante${NC}"
    fi
    
    # Volume
    if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Volume de configuration '$VOLUME_NAME' présent${NC}"
    else
        echo -e "${YELLOW}! Volume de configuration '$VOLUME_NAME' manquant${NC}"
    fi
    
    # Containers actifs
    echo ""
    echo -e "${BLUE}Containers Claude Code actifs:${NC}"
    containers=$(docker ps --filter="ancestor=$IMAGE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
    if [ -n "$containers" ]; then
        echo "$containers"
    else
        echo "Aucun container actif"
    fi
    
    # Containers arrêtés
    echo ""
    echo -e "${BLUE}Containers Claude Code arrêtés:${NC}"
    stopped_containers=$(docker ps -a --filter="ancestor=$IMAGE_NAME" --filter="status=exited" --format "table {{.Names}}\t{{.Status}}" | tail -n +2)
    if [ -n "$stopped_containers" ]; then
        echo "$stopped_containers"
    else
        echo "Aucun container arrêté"
    fi
}

clean_containers() {
    echo -e "${YELLOW}Nettoyage des containers arrêtés...${NC}"
    stopped=$(docker ps -aq --filter="ancestor=$IMAGE_NAME" --filter="status=exited")
    if [ -n "$stopped" ]; then
        docker rm $stopped
        echo -e "${GREEN}Containers nettoyés${NC}"
    else
        echo "Aucun container à nettoyer"
    fi
}

reset_all() {
    echo -e "${RED}ATTENTION: Cette opération va supprimer TOUS les containers et la configuration${NC}"
    read -p "Êtes-vous sûr ? (oui/non): " confirm
    
    if [ "$confirm" = "oui" ]; then
        echo -e "${YELLOW}Arrêt de tous les containers...${NC}"
        docker ps -q --filter="ancestor=$IMAGE_NAME" | xargs -r docker stop
        
        echo -e "${YELLOW}Suppression de tous les containers...${NC}"
        docker ps -aq --filter="ancestor=$IMAGE_NAME" | xargs -r docker rm
        
        echo -e "${YELLOW}Suppression du volume de configuration...${NC}"
        docker volume rm "$VOLUME_NAME" 2>/dev/null || true
        
        echo -e "${GREEN}Réinitialisation terminée${NC}"
    else
        echo "Opération annulée"
    fi
}

rebuild_image() {
    echo -e "${YELLOW}Reconstruction de l'image Docker...${NC}"
    
    # Arrêter tous les containers utilisant l'image
    docker ps -q --filter="ancestor=$IMAGE_NAME" | xargs -r docker stop
    
    # Supprimer l'ancienne image
    docker rmi "$IMAGE_NAME" 2>/dev/null || true
    
    # Reconstruire
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    docker build \
        --build-arg USER_ID=$USER_ID \
        --build-arg GROUP_ID=$GROUP_ID \
        --no-cache \
        -t "$IMAGE_NAME" \
        "$DEV/dockerfiles-projects/claude-code/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Image reconstruite avec succès${NC}"
    else
        echo -e "${RED}Erreur lors de la reconstruction${NC}"
        exit 1
    fi
}

show_logs() {
    echo -e "${BLUE}Logs des containers Claude Code:${NC}"
    containers=$(docker ps -q --filter="ancestor=$IMAGE_NAME")
    if [ -n "$containers" ]; then
        docker logs --tail=50 -f $containers
    else
        echo "Aucun container actif"
    fi
}

open_shell() {
    CURRENT_DIR=$(pwd)
    CONTAINER_NAME="claude-code-shell-$(date +%s)"
    
    echo -e "${GREEN}Ouverture d'un shell dans le container...${NC}"
    docker run --rm -it \
        --name "$CONTAINER_NAME" \
        --user adam \
        -v "$CURRENT_DIR:/workspace" \
        -v "$VOLUME_NAME:/home/adam/.config/claude-code" \
        -v "$HOME/.config/claude-code/api.key:/home/adam/.config/claude-code/api.key:ro" \
        -e ANTHROPIC_API_KEY="$(cat $HOME/.config/claude-code/api.key 2>/dev/null || echo '')" \
        "$IMAGE_NAME" \
        "cd /workspace && exec /bin/bash"
}

# Traitement des commandes
case "${1:-help}" in
    "status")
        show_status
        ;;
    "clean")
        clean_containers
        ;;
    "reset")
        reset_all
        ;;
    "rebuild")
        rebuild_image
        ;;
    "logs")
        show_logs
        ;;
    "shell")
        open_shell
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Commande inconnue: $1${NC}"
        show_help
        exit 1
        ;;
esac