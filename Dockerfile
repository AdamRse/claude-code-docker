# Dockerfile pour Claude Code
FROM node:20-alpine

# Mettre à jour npm et installer Claude Code globalement
RUN npm install -g npm@latest
RUN npm install -g @anthropic-ai/claude-code
RUN echo "Checking installation..." && \
    npm list -g --depth=0 && \
    echo "PATH: $PATH" && \
    ls -la /usr/local/bin/ && \
    find /usr/local -name "*claude*" 2>/dev/null

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

# Créer les répertoires nécessaires
RUN mkdir -p /home/adam/.config/claude-code && \
    chown -R adam:adam /home/adam/.config

# Définir l'utilisateur
USER adam

# Définir le répertoire de travail
WORKDIR /workspace

# Point d'entrée
ENTRYPOINT ["claude"]