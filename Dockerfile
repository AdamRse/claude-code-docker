# Dockerfile pour Claude Code
FROM node:20-alpine

# Installer les dépendances système nécessaires
RUN apk add --no-cache git bash

# Mettre à jour npm et installer Claude Code globalement
RUN npm install -g npm@latest
RUN npm install -g @anthropic-ai/claude-code

# Créer un utilisateur avec le même UID que votre utilisateur local
ARG USER_ID=1000
ARG GROUP_ID=1000

# Vérifier qui utilise l'UID et le remplacer si nécessaire
RUN existing_user=$(getent passwd ${USER_ID} | cut -d: -f1 || echo "none") && \
    if [ "$existing_user" != "none" ] && [ "$existing_user" != "adam" ]; then \
        deluser "$existing_user" 2>/dev/null || true; \
    fi && \
    if ! id adam >/dev/null 2>&1; then \
        adduser -D -u ${USER_ID} adam; \
    fi

# Créer les répertoires nécessaires avec les bonnes permissions
RUN mkdir -p /home/adam/.config/claude-code && \
    mkdir -p /home/adam/.anthropic && \
    mkdir -p /home/adam/.local/share/claude && \
    mkdir -p /home/adam/.cache/claude && \
    chown -R adam:adam /home/adam

# Définir les variables d'environnement pour Claude Code
ENV SHELL=/bin/bash
ENV HOME=/home/adam

# Définir l'utilisateur
USER adam

# Définir le répertoire de travail
WORKDIR /workspace

# Utiliser bash comme shell par défaut
SHELL ["/bin/bash", "-c"]

# Point d'entrée avec bash
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["claude"]