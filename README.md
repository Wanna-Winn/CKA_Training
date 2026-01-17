# CKA Training System

Système complet d'entraînement pour la certification CKA (Certified Kubernetes Administrator).
**Optimisé pour Minikube sur Git Bash Windows 11**

## 📋 Description du Projet

Ce projet fournit un système complet d'entraînement pour préparer la certification CKA (Certified Kubernetes Administrator). Il inclut :

- **20 exercices pratiques** couvrant tous les domaines de l'examen CKA
- **Système de vérification automatique** pour valider vos solutions
- **Aliases Kubernetes optimisés** pour gagner du temps pendant l'examen
- **Interface interactive** pour naviguer facilement entre les exercices
- **Solutions détaillées** pour chaque exercice

## 🔧 Prérequis

Pour utiliser ce système d'entraînement, vous avez besoin de :

### 1. Système d'exploitation
- **Windows 11** (recommandé)
- **Git Bash** installé (pour les commandes Unix)
- **Hyper-V** activé

### 2. Activation d'Hyper-V

Pour activer Hyper-V sur Windows 11 :

#### Méthode 1: Via PowerShell (en tant qu'administrateur)
```powershell
# Activer Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# Redémarrer l'ordinateur
Restart-Computer
```

#### Méthode 2: Via l'interface graphique
1. Ouvrir "Panneau de configuration" → "Programmes" → "Activer ou désactiver des fonctionnalités Windows"
2. Cocher "Hyper-V" et toutes ses sous-options
3. Cliquer sur "OK" et redémarrer

#### Méthode 3: Via CMD (en tant qu'administrateur)
```cmd
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart
shutdown /r /t 0
```

### 3. Outils Kubernetes
- **Minikube** (version 1.30+ recommandée)
- **kubectl** (version compatible avec votre cluster)
- **Docker** ou autre runtime de conteneurs

### 4. Configuration minimale
- **4 CPU cores**
- **8GB RAM** (16GB recommandé pour Minikube)
- **20GB espace disque**
- **Accès internet** pour télécharger les images

### 5. Configuration recommandée pour Minikube
```bash
minikube start --driver=hyperv --cpus=4 --memory=8192 --disk-size=20g
```

## 🚀 Installation et Configuration

### 1. Installer les prérequis

```bash
# Installer Minikube (si ce n'est pas déjà fait)
choco install minikube -y

# Installer kubectl
choco install kubernetes-cli -y

# Démarrer Minikube avec Hyper-V
minikube start --driver=hyperv --cpus=4 --memory=8192
```

### 2. Installer le CKA Trainer

```bash
# Cloner le dépôt (si ce n'est pas déjà fait)
git clone https://github.com/Wanna-Winn/CKA_Training.git
cd cka-trainer

# Rendre les scripts exécutables
chmod +x cka-training.sh setup-aliases.sh

# Configurer les alias Kubernetes (IMPORTANT !)
./setup-aliases.sh
source ~/.bashrc

# Vérifier que tout fonctionne
k version
```

### 3. Démarrer l'entraînement

```bash
# Lancer le système d'entraînement
./cka-training.sh

# Ou utiliser les commandes directes
./cka-training.sh list          # Liste tous les exercices
./cka-training.sh setup 01      # Démarrer l'exercice 01
./cka-training.sh check 01      # Vérifier votre solution
./cka-training.sh reset 01      # Réinitialiser l'exercice
./cka-training.sh solution 01   # Voir la solution (dernier recours!)
```

### 4. Vérification de l'installation

```bash
# Exécuter le script de test
./test-setup.sh

# Vérifier que Minikube est prêt
minikube status

# Vérifier que kubectl fonctionne
k get nodes
```

## Configuration des Alias

Le script `setup-aliases.sh` configure automatiquement :
- `kubectl` → `minikube kubectl --`
- `k` → `minikube kubectl --` (raccourci ultra-rapide)
- Variables : `$do` et `$now` pour gagner du temps

### Alias disponibles après installation

**Get commands:**
- `k` ou `kubectl` → commande kubectl via minikube
- `kgp` → get pods
- `kgpa` → get pods --all-namespaces
- `kgd` → get deployments
- `kgs` → get services
- `kgn` → get nodes
- `kgpn <namespace>` → get pods -n

**Describe:**
- `kdp` → describe pod
- `kdd` → describe deployment
- `kds` → describe service

**Logs:**
- `kl` → logs
- `klf` → logs -f (follow)

**Actions:**
- `ka` → apply -f
- `kdel` → delete
- `kex` → exec -it

**Variables:**
- `$do` = `--dry-run=client -o yaml`
- `$now` = `--force --grace-period=0`

### Exemples d'utilisation

```bash
# Au lieu de : minikube kubectl -- get pods
kgp

# Au lieu de : minikube kubectl -- run nginx --image=nginx --dry-run=client -o yaml
k run nginx --image=nginx $do

# Créer et sauvegarder un manifest
k run test --image=nginx $do > pod.yaml
```

## Utilisation du système d'entraînement

### Mode interactif
```bash
./cka-training.sh
```

### Mode commande
```bash
./cka-training.sh list          # Liste tous les exercices
./cka-training.sh setup 01      # Démarrer l'exercice 01
./cka-training.sh check 01      # Vérifier votre solution
./cka-training.sh reset 01      # Réinitialiser l'exercice
./cka-training.sh solution 01   # Voir la solution (dernier recours!)
```

## Exercices (20 total)

Les exercices sont numérotés **01 à 20** pour un tri correct.

### Workloads & Pods (15%)
- 01-06, 15-17: Pods, Deployments, DaemonSets, StatefulSets, Jobs

### Services & Networking (20%)
- 07-08, 14, 18: Services, NetworkPolicy, Ingress

### Storage (10%)
- 09: PV et PVC

### Scheduling (5%)
- 10-12: NodeSelector, Taints, LimitRange

### Security (15%)
- 13: RBAC

### Troubleshooting (30%)
- 19: Réparer un pod cassé

### Cluster Architecture (25%)
- 20: ETCD Backup/Restore

## Stratégie d'entraînement

Voici une stratégie recommandée pour préparer efficacement l'examen CKA :

### Semaine 1: Fondamentaux
- **Jour 1-2**: Exercices 01-07 (Bases - Pods, Deployments, Services)
- **Jour 3-4**: Exercices 08-14 (Intermédiaire - Networking, Storage, Scheduling)
- **Jour 5**: Exercices 15-20 (Avancé - StatefulSets, Troubleshooting, ETCD)

### Semaine 2: Révision et Simulation
- **Jour 6**: Révision des exercices difficiles
- **Jour 7**: Simulation d'examen complet (chronométré)
- **Jour 8**: Correction et amélioration

### Conseils pour la réussite
- **Pratique quotidienne**: 2-3 heures par jour
- **Focus sur les domaines lourds**: Troubleshooting (30%) et Cluster Architecture (25%)
- **Maîtrise des alias**: Ils vous feront gagner 30% de temps

## Conseils pour l'examen CKA

### 1. Alias et raccourcis (déjà configurés !)
```bash
k run nginx --image=nginx $do > pod.yaml
k create deploy web --image=nginx $do
```

### 2. Commandes essentielles à maîtriser
- `kubectl run` avec --dry-run
- `kubectl create` pour les resources
- `kubectl explain` pour la documentation

### 3. Gestion du temps
- 17 questions en 2h = ~7 min/question
- Marquez les difficiles et revenez-y
- Les questions valent entre 2% et 13%

### 4. Documentation autorisée
- **kubernetes.io** UNIQUEMENT
- Apprenez à naviguer rapidement
- Utilisez Ctrl+F pour chercher

### 5. Environnement d'examen
- Copier-coller peut ne pas fonctionner partaitement
- Tapez les commandes courtes manuellement
- Utilisez les alias pour gagner du temps

### 6. Debugging rapide
```bash
k get events --sort-by=.metadata.creationTimestamp
k describe pod <pod-name>
k logs <pod-name>
```

## Troubleshooting

**Problème : "minikube kubectl -- command not found"**
```bash
minikube status  # Vérifier que minikube est démarré
minikube start   # Si nécessaire
```

**Problème : Les alias ne fonctionnent pas**
```bash
source ~/.bashrc
# OU fermer et réouvrir Git Bash
```

**Problème : Permission denied sur les scripts**
```bash
chmod +x cka-training.sh setup-aliases.sh
chmod +x exercises/exercise-*/*.sh
```

Bon courage pour votre examen CKA! 🚀
