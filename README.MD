# Installation de Claude Code via Docker

## Étapes d'installation

### 1. Créer la structure de répertoires
```bash
mkdir -p $DEV/dockerfiles-projects/claude-code
```

### 2. Créer les fichiers
Placez le `Dockerfile` dans `$DEV/dockerfiles-projects/claude-code/Dockerfile`

Placez le script `claude-code.sh` dans `$DEV/dockerfiles-projects/claude-code/claude-code.sh`

### 3. Rendre le script exécutable
```bash
chmod +x $DEV/dockerfiles-projects/claude-code/claude-code.sh
```

### 4. Créer un lien symbolique (optionnel mais pratique)
Pour pouvoir utiliser `claude-code` depuis n'importe quel projet :
```bash
# Créer un répertoire bin personnel s'il n'existe pas
mkdir -p $HOME/.local/bin

# Créer le lien symbolique
ln -sf $DEV/dockerfiles-projects/claude-code/claude-code.sh $HOME/.local/bin/claude-code

# S'assurer que ~/.local/bin est dans votre PATH (ajoutez à ~/.bashrc si nécessaire)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Utilisation

### Depuis un projet
```bash
# Aller dans votre projet
cd $DEV/projets/whatsapp_bookmarks

# Utiliser Claude Code (première fois = construction de l'image)
claude-code --help

# Exemple d'utilisation
claude-code "Aide-moi à refactoriser ce code Python"
```

### Avantages de cette solution

1. **Pas besoin de Node.js/npm sur votre système**
2. **Réutilisable pour tous vos projets** dans `$DEV/projets`
3. **Isolation complète** dans le container
4. **Même utilisateur** (adam) avec les bons droits
5. **Clé API sécurisée** montée en lecture seule
6. **Mise à jour facile** en reconstruisant l'image

### Mise à jour de Claude Code
Pour mettre à jour Claude Code vers une nouvelle version :
```bash
# Supprimer l'ancienne image
docker rmi claude-code:latest

# La prochaine utilisation reconstruira l'image avec la dernière version
```

### Dépannage

- **Erreur de permissions** : Vérifiez que votre utilisateur local a les bons droits sur les répertoires
- **Clé API non trouvée** : Vérifiez que le fichier `$HOME/.config/claude-code/api.key` existe et contient votre clé
- **Docker non accessible** : Vérifiez que votre utilisateur fait partie du groupe `docker`

La solution est maintenant prête à être utilisée pour tous vos projets dans `$DEV/projets` !