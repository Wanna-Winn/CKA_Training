#!/bin/bash
# CKA Training System - Complete Installer
# This script creates all files and directories needed for CKA training

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="cka-training"
EXERCISES_DIR="./exercises"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}CKA Training System Installer${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Create main directory
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p "$INSTALL_DIR/exercises"
cd "$INSTALL_DIR"

# ============================================
# Create main training script
# ============================================
cat > cka-training.sh << 'MAINSCRIPT'
#!/bin/bash
# CKA Training System
# Usage: ./cka-training.sh <exercise_number>

set -e

EXERCISES_DIR="./exercises"
CURRENT_EXERCISE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

setup_exercise() {
    local exercise_num=$1
    CURRENT_EXERCISE="${EXERCISES_DIR}/exercise-${exercise_num}"
    
    if [ ! -d "$CURRENT_EXERCISE" ]; then
        log_error "Exercise $exercise_num not found!"
        exit 1
    fi
    
    log_info "Setting up Exercise $exercise_num..."
    echo ""
    
    if [ -f "${CURRENT_EXERCISE}/setup.sh" ]; then
        bash "${CURRENT_EXERCISE}/setup.sh"
    fi
    
    if [ -d "${CURRENT_EXERCISE}/manifests" ]; then
        kubectl apply -f "${CURRENT_EXERCISE}/manifests/"
    fi
    
    echo ""
    log_info "Environment ready! Here are your tasks:"
    echo ""
    cat "${CURRENT_EXERCISE}/instructions.txt"
    echo ""
}

check_exercise() {
    local exercise_num=$1
    CURRENT_EXERCISE="${EXERCISES_DIR}/exercise-${exercise_num}"
    
    if [ ! -f "${CURRENT_EXERCISE}/check.sh" ]; then
        log_error "No check script found for exercise $exercise_num"
        exit 1
    fi
    
    echo ""
    log_info "Checking your solution..."
    echo ""
    
    bash "${CURRENT_EXERCISE}/check.sh"
}

reset_exercise() {
    local exercise_num=$1
    CURRENT_EXERCISE="${EXERCISES_DIR}/exercise-${exercise_num}"
    
    log_warn "Resetting exercise $exercise_num..."
    
    if [ -f "${CURRENT_EXERCISE}/cleanup.sh" ]; then
        bash "${CURRENT_EXERCISE}/cleanup.sh"
    fi
    
    if [ -d "${CURRENT_EXERCISE}/manifests" ]; then
        kubectl delete -f "${CURRENT_EXERCISE}/manifests/" --ignore-not-found=true
    fi
    
    log_info "Environment reset complete!"
}

list_exercises() {
    echo -e "${BLUE}Available CKA Training Exercises:${NC}"
    echo "=================================="
    for dir in ${EXERCISES_DIR}/exercise-*/; do
        if [ -d "$dir" ]; then
            exercise_num=$(basename "$dir" | sed 's/exercise-//')
            title=$(head -n 1 "${dir}instructions.txt" 2>/dev/null | sed 's/EXERCISE [0-9]*: //')
            difficulty=$(grep "DIFFICULTY:" "${dir}instructions.txt" 2>/dev/null | head -n 1 | awk '{print $2}')
            time=$(grep "TIME:" "${dir}instructions.txt" 2>/dev/null | head -n 1 | awk '{print $4, $5}')
            printf "  %2s. %-40s [%-6s] %s\n" "$exercise_num" "$title" "$difficulty" "$time"
        fi
    done
    echo ""
}

show_menu() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  CKA Training System${NC}"
    echo -e "${BLUE}================================${NC}"
    echo "1. List exercises"
    echo "2. Start exercise"
    echo "3. Check solution"
    echo "4. Reset exercise"
    echo "5. Show solution (use sparingly!)"
    echo "6. Exit"
    echo ""
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            list_exercises
            show_menu
            ;;
        2)
            read -p "Enter exercise number (1-20): " ex_num
            setup_exercise "$ex_num"
            show_menu
            ;;
        3)
            read -p "Enter exercise number (1-20): " ex_num
            check_exercise "$ex_num"
            show_menu
            ;;
        4)
            read -p "Enter exercise number (1-20): " ex_num
            reset_exercise "$ex_num"
            show_menu
            ;;
        5)
            read -p "Enter exercise number (1-20): " ex_num
            if [ -f "${EXERCISES_DIR}/exercise-${ex_num}/solution.sh" ]; then
                echo ""
                log_warn "Showing solution (try to solve it yourself first!):"
                cat "${EXERCISES_DIR}/exercise-${ex_num}/solution.sh"
                echo ""
            else
                log_error "No solution available"
            fi
            show_menu
            ;;
        6)
            log_info "Good luck with your CKA exam on 23/01!"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            show_menu
            ;;
    esac
}

mkdir -p "$EXERCISES_DIR"

if [ $# -eq 0 ]; then
    show_menu
else
    case $1 in
        setup)
            setup_exercise "$2"
            ;;
        check)
            check_exercise "$2"
            ;;
        reset)
            reset_exercise "$2"
            ;;
        list)
            list_exercises
            ;;
        solution)
            if [ -f "${EXERCISES_DIR}/exercise-$2/solution.sh" ]; then
                cat "${EXERCISES_DIR}/exercise-$2/solution.sh"
            fi
            ;;
        *)
            echo "Usage: $0 [setup|check|reset|list|solution] [exercise_number]"
            exit 1
            ;;
    esac
fi
MAINSCRIPT

chmod +x cka-training.sh

echo -e "${GREEN}✓ Main script created${NC}"

# ============================================
# Now create all 20 exercises using a loop
# ============================================

create_exercise() {
    local num=$1
    local dir="exercises/exercise-$num"
    mkdir -p "$dir"
}

# Create directory structure for all exercises with 2-digit padding
for i in {1..20}; do
    create_exercise $(printf "%02d" $i)
done

echo -e "${GREEN}✓ Exercise directories created${NC}"

# ============================================
# Create alias setup script
# ============================================
echo -e "${GREEN}Creating alias configuration...${NC}"

cat > setup-aliases.sh << 'ALIASES_SCRIPT'
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Kubernetes aliases for Git Bash...${NC}"

HOME_DIR="$HOME"
BASHRC="$HOME_DIR/.bashrc"
BASH_ALIASES="$HOME_DIR/.bash_aliases"

cat > "$BASH_ALIASES" << 'ALIASES_EOF'
#!/bin/bash
# Kubernetes aliases for CKA Training with Minikube

alias kubectl='minikube kubectl --'
alias k='minikube kubectl --'
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"

alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kgpn='kubectl get pods -n'

alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe service'

alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'
alias kex='kubectl exec -it'

alias krun='kubectl run'
alias kcreate='kubectl create'
alias kexpose='kubectl expose'
alias kscale='kubectl scale'

krundr() { kubectl run "$1" --image="$2" $do; }
kdeploydr() { kubectl create deployment "$1" --image="$2" $do; }

export KUBE_EDITOR="nano"
echo "✓ K8s aliases loaded"
ALIASES_EOF

if [ ! -f "$BASHRC" ]; then
    touch "$BASHRC"
fi

if ! grep -q "\.bash_aliases" "$BASHRC"; then
    cat >> "$BASHRC" << 'BASHRC_EOF'

# Load kubernetes aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
BASHRC_EOF
fi

echo -e "${GREEN}✓ Aliases installed!${NC}"
echo -e "${YELLOW}Run: source ~/.bashrc${NC}"
ALIASES_SCRIPT

chmod +x setup-aliases.sh

echo -e "${GREEN}✓ Alias setup script created${NC}"

# ============================================
# EXERCISE 01
# ============================================
cat > exercises/exercise-01/instructions.txt << 'EOF'
EXERCISE 1: Pod Creation and Configuration
===========================================
DIFFICULTY: Easy | TIME: 8 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a namespace called 'dev-team'
2. Create a pod named 'nginx-app' in the 'dev-team' namespace:
   - Image: nginx:1.25
   - Labels: app=web, tier=frontend
   - Memory limits: 128Mi, CPU limits: 200m
   - Memory requests: 64Mi, CPU requests: 100m
   - Container port: 80
EOF

cat > exercises/exercise-01/setup.sh << 'EOF'
#!/bin/bash
echo "Exercise 1: No pre-setup required. Create everything from scratch."
EOF

cat > exercises/exercise-01/check.sh << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=7

echo "Checking Exercise 1..."
kubectl get namespace dev-team &>/dev/null && { echo -e "${GREEN}✓${NC} Namespace exists"; ((SCORE++)); } || echo -e "${RED}✗${NC} Namespace missing"
kubectl get pod nginx-app -n dev-team &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

IMG=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.spec.containers[0].image}')
[[ "$IMG" == "nginx:1.25" ]] && { echo -e "${GREEN}✓${NC} Image correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Image: $IMG"

LABEL_APP=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.metadata.labels.app}')
LABEL_TIER=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.metadata.labels.tier}')
[[ "$LABEL_APP" == "web" ]] && [[ "$LABEL_TIER" == "frontend" ]] && { echo -e "${GREEN}✓${NC} Labels correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Labels wrong"

MEM_LIMIT=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.spec.containers[0].resources.limits.memory}')
[[ "$MEM_LIMIT" == "128Mi" ]] && { echo -e "${GREEN}✓${NC} Memory limit correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Memory: $MEM_LIMIT"

CPU_LIMIT=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
[[ "$CPU_LIMIT" == "200m" ]] && { echo -e "${GREEN}✓${NC} CPU limit correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} CPU: $CPU_LIMIT"

STATUS=$(kubectl get pod nginx-app -n dev-team -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > exercises/exercise-01/cleanup.sh << 'EOF'
#!/bin/bash
kubectl delete namespace dev-team --ignore-not-found=true
echo "Exercise 1 cleaned up"
EOF

cat > exercises/exercise-01/solution.sh << 'EOF'
#!/bin/bash
kubectl create namespace dev-team
kubectl run nginx-app --image=nginx:1.25 --namespace=dev-team \
  --labels=app=web,tier=frontend \
  --requests='memory=64Mi,cpu=100m' \
  --limits='memory=128Mi,cpu=200m' \
  --port=80
EOF

chmod +x exercises/exercise-01/*.sh

# ============================================
# EXERCISE 2: Deployment and Scaling
# ============================================

cat > "${EXERCISES_DIR}/exercise-02/instructions.txt" << 'EOF'
EXERCISE 2: Deployment Creation and Scaling
============================================
DIFFICULTY: Easy | TIME: 10 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a deployment named 'webapp' in namespace 'production':
   - Image: nginx:1.24
   - Replicas: 3
   - Labels: app=webapp, env=prod
2. Scale the deployment to 5 replicas
3. Perform a rolling update to nginx:1.25
4. Verify the rollout status
EOF

cat > "${EXERCISES_DIR}/exercise-02/setup.sh" << 'EOF'
#!/bin/bash
kubectl create namespace production
echo "Exercise 2: Namespace 'production' created"
EOF

cat > "${EXERCISES_DIR}/exercise-02/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 2..."
kubectl get deployment webapp -n production &>/dev/null && { echo -e "${GREEN}✓${NC} Deployment exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Deployment missing"; exit 1; }

REPLICAS=$(kubectl get deployment webapp -n production -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "5" ]] && { echo -e "${GREEN}✓${NC} Scaled to 5 replicas"; ((SCORE++)); } || echo -e "${RED}✗${NC} Replicas: $REPLICAS"

IMG=$(kubectl get deployment webapp -n production -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "nginx:1.25" ]] && { echo -e "${GREEN}✓${NC} Image updated to 1.25"; ((SCORE++)); } || echo -e "${RED}✗${NC} Image: $IMG"

READY=$(kubectl get deployment webapp -n production -o jsonpath='{.status.readyReplicas}')
[[ "$READY" == "5" ]] && { echo -e "${GREEN}✓${NC} All replicas ready"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ready replicas: $READY"

LABEL=$(kubectl get deployment webapp -n production -o jsonpath='{.metadata.labels.app}')
[[ "$LABEL" == "webapp" ]] && { echo -e "${GREEN}✓${NC} Labels correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Labels wrong"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-02/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete namespace production --ignore-not-found=true
echo "Exercise 2 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-02/solution.sh" << 'EOF'
#!/bin/bash
kubectl create deployment webapp --image=nginx:1.24 --replicas=3 -n production
kubectl label deployment webapp env=prod -n production
kubectl scale deployment webapp --replicas=5 -n production
kubectl set image deployment/webapp nginx=nginx:1.25 -n production
kubectl rollout status deployment/webapp -n production
EOF

chmod +x "${EXERCISES_DIR}/exercise-02"/*.sh

# ============================================
# EXERCISE 3: ConfigMap and Environment Variables
# ============================================

cat > "${EXERCISES_DIR}/exercise-03/instructions.txt" << 'EOF'
EXERCISE 3: ConfigMap and Environment Variables
================================================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a ConfigMap named 'app-config' in namespace 'default':
   - Key 'DB_HOST' with value 'mysql.database.svc.cluster.local'
   - Key 'DB_PORT' with value '3306'
   - Key 'APP_MODE' with value 'production'
2. Create a pod named 'config-consumer':
   - Image: busybox
   - Command: sleep 3600
   - Inject all ConfigMap values as environment variables
3. Verify the environment variables are set correctly
EOF

cat > "${EXERCISES_DIR}/exercise-03/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 3: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-03/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 3..."
kubectl get configmap app-config &>/dev/null && { echo -e "${GREEN}✓${NC} ConfigMap exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} ConfigMap missing"; exit 1; }

DB_HOST=$(kubectl get configmap app-config -o jsonpath='{.data.DB_HOST}')
[[ "$DB_HOST" == "mysql.database.svc.cluster.local" ]] && { echo -e "${GREEN}✓${NC} DB_HOST correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} DB_HOST: $DB_HOST"

kubectl get pod config-consumer &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

STATUS=$(kubectl get pod config-consumer -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

# Check if env vars are loaded from configmap
ENV_REF=$(kubectl get pod config-consumer -o jsonpath='{.spec.containers[0].envFrom[0].configMapRef.name}')
[[ "$ENV_REF" == "app-config" ]] && { echo -e "${GREEN}✓${NC} ConfigMap referenced"; ((SCORE++)); } || echo -e "${RED}✗${NC} ConfigMap not referenced"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-03/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod config-consumer --ignore-not-found=true
kubectl delete configmap app-config --ignore-not-found=true
echo "Exercise 3 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-03/solution.sh" << 'EOF'
#!/bin/bash
kubectl create configmap app-config \
  --from-literal=DB_HOST=mysql.database.svc.cluster.local \
  --from-literal=DB_PORT=3306 \
  --from-literal=APP_MODE=production

kubectl run config-consumer --image=busybox --command -- sleep 3600
kubectl set env pod/config-consumer --from=configmap/app-config
EOF

chmod +x "${EXERCISES_DIR}/exercise-03"/*.sh

# ============================================
# EXERCISE 4: Secrets
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-04"

cat > "${EXERCISES_DIR}/exercise-04/instructions.txt" << 'EOF'
EXERCISE 4: Secrets Management
===============================
DIFFICULTY: Medium | TIME: 10 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a secret named 'db-secret' in namespace 'default':
   - Type: generic
   - Key 'username' with value 'admin'
   - Key 'password' with value 'SuperSecret123'
2. Create a pod named 'secret-consumer':
   - Image: nginx:1.25
   - Mount the secret as environment variables:
     * DB_USERNAME from secret key 'username'
     * DB_PASSWORD from secret key 'password'
3. Verify the pod is running
EOF

cat > "${EXERCISES_DIR}/exercise-04/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 4: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-04/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 4..."
kubectl get secret db-secret &>/dev/null && { echo -e "${GREEN}✓${NC} Secret exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Secret missing"; exit 1; }

USERNAME=$(kubectl get secret db-secret -o jsonpath='{.data.username}' | base64 -d)
[[ "$USERNAME" == "admin" ]] && { echo -e "${GREEN}✓${NC} Username correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Username: $USERNAME"

PASSWORD=$(kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d)
[[ "$PASSWORD" == "SuperSecret123" ]] && { echo -e "${GREEN}✓${NC} Password correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Password wrong"

kubectl get pod secret-consumer &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

STATUS=$(kubectl get pod secret-consumer -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-04/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod secret-consumer --ignore-not-found=true
kubectl delete secret db-secret --ignore-not-found=true
echo "Exercise 4 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-04/solution.sh" << 'EOF'
#!/bin/bash
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123

kubectl run secret-consumer --image=nginx:1.25 --dry-run=client -o yaml > /tmp/secret-pod.yaml
cat >> /tmp/secret-pod.yaml << 'YAML'
  env:
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
YAML
kubectl apply -f /tmp/secret-pod.yaml
EOF

chmod +x "${EXERCISES_DIR}/exercise-04"/*.sh

# ============================================
# EXERCISE 5: Multi-Container Pod
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-05"

cat > "${EXERCISES_DIR}/exercise-05/instructions.txt" << 'EOF'
EXERCISE 5: Multi-Container Pod (Sidecar Pattern)
==================================================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a pod named 'logging-pod' in namespace 'default':
   - Main container 'app':
     * Image: busybox
     * Command: sh -c "while true; do echo $(date) >> /var/log/app.log; sleep 5; done"
     * Volume mount: /var/log (emptyDir)
   - Sidecar container 'log-shipper':
     * Image: busybox
     * Command: sh -c "tail -f /var/log/app.log"
     * Volume mount: /var/log (emptyDir, same volume)
2. Verify both containers are running
EOF

cat > "${EXERCISES_DIR}/exercise-05/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 5: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-05/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 5..."
kubectl get pod logging-pod &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

CONTAINERS=$(kubectl get pod logging-pod -o jsonpath='{.spec.containers[*].name}' | wc -w)
[[ "$CONTAINERS" == "2" ]] && { echo -e "${GREEN}✓${NC} Two containers"; ((SCORE++)); } || echo -e "${RED}✗${NC} Container count: $CONTAINERS"

READY=$(kubectl get pod logging-pod -o jsonpath='{.status.containerStatuses[*].ready}' | grep -o true | wc -l)
[[ "$READY" == "2" ]] && { echo -e "${GREEN}✓${NC} Both containers ready"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ready containers: $READY"

# Check volume
VOL_COUNT=$(kubectl get pod logging-pod -o jsonpath='{.spec.volumes[*].emptyDir}' | grep -o '{}' | wc -l)
[[ "$VOL_COUNT" -ge "1" ]] && { echo -e "${GREEN}✓${NC} EmptyDir volume exists"; ((SCORE++)); } || echo -e "${RED}✗${NC} Volume missing"

STATUS=$(kubectl get pod logging-pod -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-05/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod logging-pod --ignore-not-found=true
echo "Exercise 5 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-05/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: logging-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo $(date) >> /var/log/app.log; sleep 5; done"]
    volumeMounts:
    - name: logs
      mountPath: /var/log
  - name: log-shipper
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/app.log"]
    volumeMounts:
    - name: logs
      mountPath: /var/log
  volumes:
  - name: logs
    emptyDir: {}
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-05"/*.sh

# ============================================
# EXERCISE 6: DaemonSet
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-06"

cat > "${EXERCISES_DIR}/exercise-06/instructions.txt" << 'EOF'
EXERCISE 6: DaemonSet
=====================
DIFFICULTY: Medium | TIME: 10 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a DaemonSet named 'node-monitor' in namespace 'kube-system':
   - Image: busybox
   - Command: sh -c "while true; do echo Monitoring node $(hostname); sleep 30; done"
   - Labels: app=monitor, type=daemonset
2. Verify the DaemonSet is running on all nodes
EOF

cat > "${EXERCISES_DIR}/exercise-06/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 6: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-06/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=4

echo "Checking Exercise 6..."
kubectl get daemonset node-monitor -n kube-system &>/dev/null && { echo -e "${GREEN}✓${NC} DaemonSet exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} DaemonSet missing"; exit 1; }

DESIRED=$(kubectl get daemonset node-monitor -n kube-system -o jsonpath='{.status.desiredNumberScheduled}')
READY=$(kubectl get daemonset node-monitor -n kube-system -o jsonpath='{.status.numberReady}')
[[ "$DESIRED" == "$READY" ]] && [[ "$READY" -gt "0" ]] && { echo -e "${GREEN}✓${NC} Running on all nodes ($READY/$DESIRED)"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ready: $READY/$DESIRED"

LABEL_APP=$(kubectl get daemonset node-monitor -n kube-system -o jsonpath='{.metadata.labels.app}')
[[ "$LABEL_APP" == "monitor" ]] && { echo -e "${GREEN}✓${NC} Labels correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Label app: $LABEL_APP"

IMG=$(kubectl get daemonset node-monitor -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "busybox" ]] && { echo -e "${GREEN}✓${NC} Image correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Image: $IMG"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-06/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete daemonset node-monitor -n kube-system --ignore-not-found=true
echo "Exercise 6 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-06/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  namespace: kube-system
  labels:
    app: monitor
    type: daemonset
spec:
  selector:
    matchLabels:
      app: monitor
  template:
    metadata:
      labels:
        app: monitor
    spec:
      containers:
      - name: monitor
        image: busybox
        command: ["sh", "-c", "while true; do echo Monitoring node $(hostname); sleep 30; done"]
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-06"/*.sh

# ============================================
# EXERCISE 7: Service - ClusterIP
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-07"

cat > "${EXERCISES_DIR}/exercise-07/instructions.txt" << 'EOF'
EXERCISE 7: Service - ClusterIP
================================
DIFFICULTY: Easy | TIME: 10 minutes | DOMAIN: Services & Networking (20%)

TASKS:
1. Create a deployment named 'web-app' in namespace 'default':
   - Image: nginx:1.25
   - Replicas: 3
   - Labels: app=web, tier=backend
   - Container port: 80
2. Create a ClusterIP service named 'web-service':
   - Selector: app=web
   - Port: 8080
   - Target port: 80
3. Verify the service endpoints match the pod IPs
EOF

cat > "${EXERCISES_DIR}/exercise-07/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 7: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-07/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=6

echo "Checking Exercise 7..."
kubectl get deployment web-app &>/dev/null && { echo -e "${GREEN}✓${NC} Deployment exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Deployment missing"; exit 1; }

REPLICAS=$(kubectl get deployment web-app -o jsonpath='{.status.readyReplicas}')
[[ "$REPLICAS" == "3" ]] && { echo -e "${GREEN}✓${NC} 3 replicas ready"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ready replicas: $REPLICAS"

kubectl get service web-service &>/dev/null && { echo -e "${GREEN}✓${NC} Service exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Service missing"; exit 1; }

SVC_TYPE=$(kubectl get service web-service -o jsonpath='{.spec.type}')
[[ "$SVC_TYPE" == "ClusterIP" ]] && { echo -e "${GREEN}✓${NC} Service type ClusterIP"; ((SCORE++)); } || echo -e "${RED}✗${NC} Type: $SVC_TYPE"

PORT=$(kubectl get service web-service -o jsonpath='{.spec.ports[0].port}')
[[ "$PORT" == "8080" ]] && { echo -e "${GREEN}✓${NC} Port 8080"; ((SCORE++)); } || echo -e "${RED}✗${NC} Port: $PORT"

ENDPOINTS=$(kubectl get endpoints web-service -o jsonpath='{.subsets[0].addresses}' | grep -o "ip" | wc -l)
[[ "$ENDPOINTS" == "3" ]] && { echo -e "${GREEN}✓${NC} 3 endpoints"; ((SCORE++)); } || echo -e "${RED}✗${NC} Endpoints: $ENDPOINTS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-07/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete deployment web-app --ignore-not-found=true
kubectl delete service web-service --ignore-not-found=true
echo "Exercise 7 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-07/solution.sh" << 'EOF'
#!/bin/bash
kubectl create deployment web-app --image=nginx:1.25 --replicas=3
kubectl label deployment web-app tier=backend
kubectl expose deployment web-app --name=web-service --port=8080 --target-port=80 --type=ClusterIP
EOF

chmod +x "${EXERCISES_DIR}/exercise-07"/*.sh

# ============================================
# EXERCISE 8: NodePort Service
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-08"

cat > "${EXERCISES_DIR}/exercise-08/instructions.txt" << 'EOF'
EXERCISE 8: NodePort Service
=============================
DIFFICULTY: Easy | TIME: 8 minutes | DOMAIN: Services & Networking (20%)

TASKS:
1. Create a pod named 'nodeport-app':
   - Image: nginx:1.25
   - Labels: app=nodeport
2. Create a NodePort service named 'nodeport-service':
   - Selector: app=nodeport
   - Port: 80
   - NodePort: 30080 (specific port)
3. Verify the service is accessible
EOF

cat > "${EXERCISES_DIR}/exercise-08/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 8: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-08/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 8..."
kubectl get pod nodeport-app &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

kubectl get service nodeport-service &>/dev/null && { echo -e "${GREEN}✓${NC} Service exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Service missing"; exit 1; }

SVC_TYPE=$(kubectl get service nodeport-service -o jsonpath='{.spec.type}')
[[ "$SVC_TYPE" == "NodePort" ]] && { echo -e "${GREEN}✓${NC} Service type NodePort"; ((SCORE++)); } || echo -e "${RED}✗${NC} Type: $SVC_TYPE"

NODEPORT=$(kubectl get service nodeport-service -o jsonpath='{.spec.ports[0].nodePort}')
[[ "$NODEPORT" == "30080" ]] && { echo -e "${GREEN}✓${NC} NodePort 30080"; ((SCORE++)); } || echo -e "${RED}✗${NC} NodePort: $NODEPORT"

STATUS=$(kubectl get pod nodeport-app -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL
EOF

# ============================================
# EXERCISE 9: Persistent Volume and Claim
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-09"

cat > "${EXERCISES_DIR}/exercise-09/instructions.txt" << 'EOF'
EXERCISE 9: Persistent Volume and Claim
========================================
DIFFICULTY: Medium | TIME: 15 minutes | DOMAIN: Storage (10%)

TASKS:
1. Create a PersistentVolume named 'pv-data':
   - Capacity: 1Gi
   - Access mode: ReadWriteOnce
   - Host path: /mnt/data
   - Storage class: manual
2. Create a PersistentVolumeClaim named 'pvc-data':
   - Request: 500Mi
   - Access mode: ReadWriteOnce
   - Storage class: manual
3. Create a pod named 'pv-pod':
   - Image: nginx:1.25
   - Mount the PVC at /usr/share/nginx/html
4. Verify the PVC is bound
EOF

cat > "${EXERCISES_DIR}/exercise-09/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 9: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-09/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=6

echo "Checking Exercise 9..."
kubectl get pv pv-data &>/dev/null && { echo -e "${GREEN}✓${NC} PV exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} PV missing"; exit 1; }

PV_CAP=$(kubectl get pv pv-data -o jsonpath='{.spec.capacity.storage}')
[[ "$PV_CAP" == "1Gi" ]] && { echo -e "${GREEN}✓${NC} PV capacity 1Gi"; ((SCORE++)); } || echo -e "${RED}✗${NC} PV capacity: $PV_CAP"

kubectl get pvc pvc-data &>/dev/null && { echo -e "${GREEN}✓${NC} PVC exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} PVC missing"; exit 1; }

PVC_STATUS=$(kubectl get pvc pvc-data -o jsonpath='{.status.phase}')
[[ "$PVC_STATUS" == "Bound" ]] && { echo -e "${GREEN}✓${NC} PVC bound"; ((SCORE++)); } || echo -e "${RED}✗${NC} PVC status: $PVC_STATUS"

kubectl get pod pv-pod &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

MOUNT=$(kubectl get pod pv-pod -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}')
[[ "$MOUNT" == "pvc-data" ]] && { echo -e "${GREEN}✓${NC} PVC mounted"; ((SCORE++)); } || echo -e "${RED}✗${NC} Mount: $MOUNT"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-09/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod pv-pod --ignore-not-found=true
kubectl delete pvc pvc-data --ignore-not-found=true
kubectl delete pv pv-data --ignore-not-found=true
echo "Exercise 9 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-09/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: pv-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-09"/*.sh

# ============================================
# EXERCISE 10: Node Selector
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-10"

cat > "${EXERCISES_DIR}/exercise-10/instructions.txt" << 'EOF'
EXERCISE 10: Node Selector
===========================
DIFFICULTY: Easy | TIME: 8 minutes | DOMAIN: Scheduling (5%)

TASKS:
1. Label one of your nodes with 'disktype=ssd'
2. Create a pod named 'fast-storage':
   - Image: nginx:1.25
   - Node selector: disktype=ssd
3. Verify the pod is scheduled on the labeled node
EOF

cat > "${EXERCISES_DIR}/exercise-10/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 10: No pre-setup required"
echo "Remember to label a node with 'disktype=ssd'"
EOF

cat > "${EXERCISES_DIR}/exercise-10/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=4

echo "Checking Exercise 10..."

# Check if any node has the label
NODE_LABELED=$(kubectl get nodes -l disktype=ssd --no-headers 2>/dev/null | wc -l)
[[ "$NODE_LABELED" -gt "0" ]] && { echo -e "${GREEN}✓${NC} Node labeled with disktype=ssd"; ((SCORE++)); } || echo -e "${RED}✗${NC} No node labeled"

kubectl get pod fast-storage &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

SELECTOR=$(kubectl get pod fast-storage -o jsonpath='{.spec.nodeSelector.disktype}')
[[ "$SELECTOR" == "ssd" ]] && { echo -e "${GREEN}✓${NC} NodeSelector set"; ((SCORE++)); } || echo -e "${RED}✗${NC} NodeSelector: $SELECTOR"

STATUS=$(kubectl get pod fast-storage -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-10/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod fast-storage --ignore-not-found=true
# Remove label from all nodes
kubectl label nodes --all disktype- 2>/dev/null || true
echo "Exercise 10 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-10/solution.sh" << 'EOF'
#!/bin/bash
# Label the first available node
NODE=$(kubectl get nodes -o name | head -n 1)
kubectl label $NODE disktype=ssd

# Create pod with nodeSelector
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: fast-storage
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx:1.25
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-10"/*.sh

# ============================================
# EXERCISE 11: Taints and Tolerations
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-11"

cat > "${EXERCISES_DIR}/exercise-11/instructions.txt" << 'EOF'
EXERCISE 11: Taints and Tolerations
====================================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Scheduling (5%)

TASKS:
1. Taint one node with 'dedicated=backend:NoSchedule'
2. Create a pod named 'backend-pod':
   - Image: nginx:1.25
   - Toleration for the taint 'dedicated=backend:NoSchedule'
3. Create another pod named 'frontend-pod' without toleration
4. Verify backend-pod is scheduled and frontend-pod might be pending/scheduled elsewhere
EOF

cat > "${EXERCISES_DIR}/exercise-11/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 11: No pre-setup required"
echo "You will taint a node as part of the exercise"
EOF

cat > "${EXERCISES_DIR}/exercise-11/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=4

echo "Checking Exercise 11..."

# Check if any node has the taint
NODE_TAINTED=$(kubectl get nodes -o json | jq -r '.items[].spec.taints[]? | select(.key=="dedicated" and .value=="backend" and .effect=="NoSchedule")' 2>/dev/null | wc -l)
[[ "$NODE_TAINTED" -gt "0" ]] && { echo -e "${GREEN}✓${NC} Node tainted"; ((SCORE++)); } || echo -e "${RED}✗${NC} No node tainted"

kubectl get pod backend-pod &>/dev/null && { echo -e "${GREEN}✓${NC} Backend pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Backend pod missing"; exit 1; }

# Check toleration
TOLERATION=$(kubectl get pod backend-pod -o json | jq -r '.spec.tolerations[]? | select(.key=="dedicated")' 2>/dev/null)
[[ -n "$TOLERATION" ]] && { echo -e "${GREEN}✓${NC} Toleration configured"; ((SCORE++)); } || echo -e "${RED}✗${NC} No toleration"

kubectl get pod frontend-pod &>/dev/null && { echo -e "${GREEN}✓${NC} Frontend pod exists"; ((SCORE++)); } || echo -e "${RED}✗${NC} Frontend pod missing"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-11/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod backend-pod frontend-pod --ignore-not-found=true
# Remove taint from all nodes
kubectl taint nodes --all dedicated- 2>/dev/null || true
echo "Exercise 11 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-11/solution.sh" << 'EOF'
#!/bin/bash
# Taint the first node
NODE=$(kubectl get nodes -o name | head -n 1)
kubectl taint $NODE dedicated=backend:NoSchedule

# Create backend pod with toleration
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "backend"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:1.25
YAML

# Create frontend pod without toleration
kubectl run frontend-pod --image=nginx:1.25
EOF

chmod +x "${EXERCISES_DIR}/exercise-11"/*.sh

# ============================================
# EXERCISE 12: Resource Limits and Requests
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-12"

cat > "${EXERCISES_DIR}/exercise-12/instructions.txt" << 'EOF'
EXERCISE 12: Resource Limits and Requests
==========================================
DIFFICULTY: Medium | TIME: 10 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a namespace 'limited'
2. Create a LimitRange in namespace 'limited':
   - Default CPU limit: 500m
   - Default memory limit: 256Mi
   - Default CPU request: 100m
   - Default memory request: 128Mi
3. Create a pod 'constrained-pod' in namespace 'limited':
   - Image: nginx:1.25
   - Do NOT specify resources (should inherit from LimitRange)
4. Verify the pod has the default limits/requests applied
EOF

cat > "${EXERCISES_DIR}/exercise-12/setup.sh" << 'EOF'
#!/bin/bash
kubectl create namespace limited
echo "Exercise 12: Namespace 'limited' created"
EOF

cat > "${EXERCISES_DIR}/exercise-12/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 12..."
kubectl get limitrange -n limited &>/dev/null && { echo -e "${GREEN}✓${NC} LimitRange exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} LimitRange missing"; exit 1; }

kubectl get pod constrained-pod -n limited &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

CPU_LIMIT=$(kubectl get pod constrained-pod -n limited -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
[[ "$CPU_LIMIT" == "500m" ]] && { echo -e "${GREEN}✓${NC} CPU limit from LimitRange"; ((SCORE++)); } || echo -e "${RED}✗${NC} CPU limit: $CPU_LIMIT"

MEM_LIMIT=$(kubectl get pod constrained-pod -n limited -o jsonpath='{.spec.containers[0].resources.limits.memory}')
[[ "$MEM_LIMIT" == "256Mi" ]] && { echo -e "${GREEN}✓${NC} Memory limit from LimitRange"; ((SCORE++)); } || echo -e "${RED}✗${NC} Memory limit: $MEM_LIMIT"

STATUS=$(kubectl get pod constrained-pod -n limited -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-12/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete namespace limited --ignore-not-found=true
echo "Exercise 12 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-12/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: limited
spec:
  limits:
  - default:
      cpu: 500m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
YAML

kubectl run constrained-pod --image=nginx:1.25 -n limited
EOF

chmod +x "${EXERCISES_DIR}/exercise-12"/*.sh

# ============================================
# EXERCISE 13: RBAC - ServiceAccount and Role
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-13"

cat > "${EXERCISES_DIR}/exercise-13/instructions.txt" << 'EOF'
EXERCISE 13: RBAC - ServiceAccount and Role
============================================
DIFFICULTY: Medium | TIME: 15 minutes | DOMAIN: Security (15%)

TASKS:
1. Create a ServiceAccount named 'pod-reader' in namespace 'default'
2. Create a Role named 'pod-read-role' in namespace 'default':
   - Resources: pods
   - Verbs: get, list, watch
3. Create a RoleBinding named 'pod-read-binding':
   - Bind the role to the ServiceAccount
4. Create a pod 'rbac-test' that uses the ServiceAccount
EOF

cat > "${EXERCISES_DIR}/exercise-13/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 13: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-13/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 13..."
kubectl get serviceaccount pod-reader &>/dev/null && { echo -e "${GREEN}✓${NC} ServiceAccount exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} ServiceAccount missing"; exit 1; }

kubectl get role pod-read-role &>/dev/null && { echo -e "${GREEN}✓${NC} Role exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Role missing"; exit 1; }

kubectl get rolebinding pod-read-binding &>/dev/null && { echo -e "${GREEN}✓${NC} RoleBinding exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} RoleBinding missing"; exit 1; }

kubectl get pod rbac-test &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

SA=$(kubectl get pod rbac-test -o jsonpath='{.spec.serviceAccountName}')
[[ "$SA" == "pod-reader" ]] && { echo -e "${GREEN}✓${NC} ServiceAccount assigned"; ((SCORE++)); } || echo -e "${RED}✗${NC} ServiceAccount: $SA"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-13/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod rbac-test --ignore-not-found=true
kubectl delete rolebinding pod-read-binding --ignore-not-found=true
kubectl delete role pod-read-role --ignore-not-found=true
kubectl delete serviceaccount pod-reader --ignore-not-found=true
echo "Exercise 13 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-13/solution.sh" << 'EOF'
#!/bin/bash
kubectl create serviceaccount pod-reader

kubectl create role pod-read-role \
  --verb=get,list,watch \
  --resource=pods

kubectl create rolebinding pod-read-binding \
  --role=pod-read-role \
  --serviceaccount=default:pod-reader

kubectl run rbac-test --image=nginx:1.25 --serviceaccount=pod-reader
EOF

chmod +x "${EXERCISES_DIR}/exercise-13"/*.sh

# ============================================
# EXERCISE 14: Network Policy
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-14"

cat > "${EXERCISES_DIR}/exercise-14/instructions.txt" << 'EOF'
EXERCISE 14: Network Policy
============================
DIFFICULTY: Hard | TIME: 15 minutes | DOMAIN: Services & Networking (20%)

TASKS:
1. Create namespace 'secure-app'
2. Create a pod 'backend' in 'secure-app':
   - Image: nginx:1.25
   - Labels: app=backend, role=db
3. Create a pod 'frontend' in 'secure-app':
   - Image: nginx:1.25
   - Labels: app=frontend, role=web
4. Create a NetworkPolicy 'backend-policy':
   - Apply to pods with label app=backend
   - Allow ingress only from pods with label app=frontend
   - Deny all other ingress
EOF

cat > "${EXERCISES_DIR}/exercise-14/setup.sh" << 'EOF'
#!/bin/bash
kubectl create namespace secure-app
echo "Exercise 14: Namespace 'secure-app' created"
echo "Note: NetworkPolicy requires a CNI that supports it (Calico, Cilium, etc.)"
EOF

cat > "${EXERCISES_DIR}/exercise-14/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 14..."
kubectl get pod backend -n secure-app &>/dev/null && { echo -e "${GREEN}✓${NC} Backend pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Backend pod missing"; exit 1; }

kubectl get pod frontend -n secure-app &>/dev/null && { echo -e "${GREEN}✓${NC} Frontend pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Frontend pod missing"; exit 1; }

kubectl get networkpolicy backend-policy -n secure-app &>/dev/null && { echo -e "${GREEN}✓${NC} NetworkPolicy exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} NetworkPolicy missing"; exit 1; }

POD_SELECTOR=$(kubectl get networkpolicy backend-policy -n secure-app -o jsonpath='{.spec.podSelector.matchLabels.app}')
[[ "$POD_SELECTOR" == "backend" ]] && { echo -e "${GREEN}✓${NC} Policy selector correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Selector: $POD_SELECTOR"

INGRESS=$(kubectl get networkpolicy backend-policy -n secure-app -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')
[[ "$INGRESS" == "frontend" ]] && { echo -e "${GREEN}✓${NC} Ingress rule correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ingress from: $INGRESS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-14/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete namespace secure-app --ignore-not-found=true
echo "Exercise 14 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-14/solution.sh" << 'EOF'
#!/bin/bash
kubectl run backend --image=nginx:1.25 --labels=app=backend,role=db -n secure-app
kubectl run frontend --image=nginx:1.25 --labels=app=frontend,role=web -n secure-app

cat << 'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-14"/*.sh

# ============================================
# EXERCISE 15: StatefulSet
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-15"

cat > "${EXERCISES_DIR}/exercise-15/instructions.txt" << 'EOF'
EXERCISE 15: StatefulSet
========================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a StatefulSet named 'web-stateful':
   - Replicas: 3
   - Image: nginx:1.25
   - Service name: nginx-headless
   - Container port: 80
2. Create a headless service 'nginx-headless':
   - Selector: app=nginx-stateful
   - Port: 80
3. Verify all pods are running with stable network identities
EOF

cat > "${EXERCISES_DIR}/exercise-15/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 15: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-15/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 15..."
kubectl get statefulset web-stateful &>/dev/null && { echo -e "${GREEN}✓${NC} StatefulSet exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} StatefulSet missing"; exit 1; }

REPLICAS=$(kubectl get statefulset web-stateful -o jsonpath='{.status.readyReplicas}')
[[ "$REPLICAS" == "3" ]] && { echo -e "${GREEN}✓${NC} 3 replicas ready"; ((SCORE++)); } || echo -e "${RED}✗${NC} Ready replicas: $REPLICAS"

kubectl get service nginx-headless &>/dev/null && { echo -e "${GREEN}✓${NC} Headless service exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Service missing"; exit 1; }

CLUSTER_IP=$(kubectl get service nginx-headless -o jsonpath='{.spec.clusterIP}')
[[ "$CLUSTER_IP" == "None" ]] && { echo -e "${GREEN}✓${NC} Service is headless"; ((SCORE++)); } || echo -e "${RED}✗${NC} ClusterIP: $CLUSTER_IP"

# Check for ordered pod names
kubectl get pod web-stateful-0 &>/dev/null && { echo -e "${GREEN}✓${NC} Ordered pod names"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod naming wrong"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-15/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete statefulset web-stateful --ignore-not-found=true
kubectl delete service nginx-headless --ignore-not-found=true
echo "Exercise 15 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-15/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-stateful
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-stateful
  template:
    metadata:
      labels:
        app: nginx-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-15"/*.sh

# ============================================
# EXERCISE 16: Init Containers
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-16"

cat > "${EXERCISES_DIR}/exercise-16/instructions.txt" << 'EOF'
EXERCISE 16: Init Containers
=============================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a pod named 'init-demo':
   - Init container 'init-setup':
     * Image: busybox
     * Command: sh -c "echo 'Initialization complete' > /work-dir/ready.txt"
     * Volume mount: /work-dir (emptyDir)
   - Main container 'app':
     * Image: busybox
     * Command: sh -c "cat /work-dir/ready.txt && sleep 3600"
     * Volume mount: /work-dir (same emptyDir)
2. Verify init container completed successfully
3. Verify main container is running
EOF

cat > "${EXERCISES_DIR}/exercise-16/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 16: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-16/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=4

echo "Checking Exercise 16..."
kubectl get pod init-demo &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

# Check init container
INIT_STATUS=$(kubectl get pod init-demo -o jsonpath='{.status.initContainerStatuses[0].state.terminated.reason}')
[[ "$INIT_STATUS" == "Completed" ]] && { echo -e "${GREEN}✓${NC} Init container completed"; ((SCORE++)); } || echo -e "${RED}✗${NC} Init status: $INIT_STATUS"

STATUS=$(kubectl get pod init-demo -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Main container running"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

# Check volume
VOL_COUNT=$(kubectl get pod init-demo -o jsonpath='{.spec.volumes[*].emptyDir}' | grep -o '{}' | wc -l)
[[ "$VOL_COUNT" -ge "1" ]] && { echo -e "${GREEN}✓${NC} EmptyDir volume configured"; ((SCORE++)); } || echo -e "${RED}✗${NC} Volume missing"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-16/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod init-demo --ignore-not-found=true
echo "Exercise 16 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-16/solution.sh" << 'EOF'
#!/bin/bash
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: init-setup
    image: busybox
    command: ['sh', '-c', "echo 'Initialization complete' > /work-dir/ready.txt"]
    volumeMounts:
    - name: workdir
      mountPath: /work-dir
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'cat /work-dir/ready.txt && sleep 3600']
    volumeMounts:
    - name: workdir
      mountPath: /work-dir
  volumes:
  - name: workdir
    emptyDir: {}
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-16"/*.sh

# ============================================
# EXERCISE 17: Jobs and CronJobs
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-17"

cat > "${EXERCISES_DIR}/exercise-17/instructions.txt" << 'EOF'
EXERCISE 17: Jobs and CronJobs
===============================
DIFFICULTY: Medium | TIME: 12 minutes | DOMAIN: Workloads (15%)

TASKS:
1. Create a Job named 'batch-job':
   - Image: busybox
   - Command: sh -c "echo Processing batch job && sleep 10"
   - Completions: 3
   - Parallelism: 2
2. Create a CronJob named 'scheduled-job':
   - Schedule: "*/2 * * * *" (every 2 minutes)
   - Image: busybox
   - Command: sh -c "echo Scheduled task executed"
3. Verify the job completes successfully
EOF

cat > "${EXERCISES_DIR}/exercise-17/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 17: No pre-setup required"
EOF

cat > "${EXERCISES_DIR}/exercise-17/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 17..."
kubectl get job batch-job &>/dev/null && { echo -e "${GREEN}✓${NC} Job exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Job missing"; exit 1; }

COMPLETIONS=$(kubectl get job batch-job -o jsonpath='{.spec.completions}')
[[ "$COMPLETIONS" == "3" ]] && { echo -e "${GREEN}✓${NC} Completions=3"; ((SCORE++)); } || echo -e "${RED}✗${NC} Completions: $COMPLETIONS"

PARALLELISM=$(kubectl get job batch-job -o jsonpath='{.spec.parallelism}')
[[ "$PARALLELISM" == "2" ]] && { echo -e "${GREEN}✓${NC} Parallelism=2"; ((SCORE++)); } || echo -e "${RED}✗${NC} Parallelism: $PARALLELISM"

kubectl get cronjob scheduled-job &>/dev/null && { echo -e "${GREEN}✓${NC} CronJob exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} CronJob missing"; exit 1; }

SCHEDULE=$(kubectl get cronjob scheduled-job -o jsonpath='{.spec.schedule}')
[[ "$SCHEDULE" == "*/2 * * * *" ]] && { echo -e "${GREEN}✓${NC} Schedule correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Schedule: $SCHEDULE"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-17/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete job batch-job --ignore-not-found=true
kubectl delete cronjob scheduled-job --ignore-not-found=true
echo "Exercise 17 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-17/solution.sh" << 'EOF'
#!/bin/bash
kubectl create job batch-job --image=busybox -- sh -c "echo Processing batch job && sleep 10"
kubectl patch job batch-job -p '{"spec":{"completions":3,"parallelism":2}}'

kubectl create cronjob scheduled-job --image=busybox --schedule="*/2 * * * *" -- sh -c "echo Scheduled task executed"
EOF

chmod +x "${EXERCISES_DIR}/exercise-17"/*.sh

# ============================================
# EXERCISE 18: Ingress
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-18"

cat > "${EXERCISES_DIR}/exercise-18/instructions.txt" << 'EOF'
EXERCISE 18: Ingress Configuration
===================================
DIFFICULTY: Medium | TIME: 15 minutes | DOMAIN: Services & Networking (20%)

TASKS:
1. Create a deployment 'web-app':
   - Image: nginx:1.25
   - Replicas: 2
2. Expose it with a ClusterIP service 'web-service' on port 80
3. Create an Ingress resource 'web-ingress':
   - Host: myapp.example.com
   - Path: /
   - Backend: web-service:80
4. Verify the ingress is configured

Note: Requires an ingress controller (nginx-ingress, traefik, etc.)
EOF

cat > "${EXERCISES_DIR}/exercise-18/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 18: No pre-setup required"
echo "Note: This exercise requires an Ingress controller to be installed"
EOF

cat > "${EXERCISES_DIR}/exercise-18/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=5

echo "Checking Exercise 18..."
kubectl get deployment web-app &>/dev/null && { echo -e "${GREEN}✓${NC} Deployment exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Deployment missing"; exit 1; }

kubectl get service web-service &>/dev/null && { echo -e "${GREEN}✓${NC} Service exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Service missing"; exit 1; }

kubectl get ingress web-ingress &>/dev/null && { echo -e "${GREEN}✓${NC} Ingress exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Ingress missing"; exit 1; }

HOST=$(kubectl get ingress web-ingress -o jsonpath='{.spec.rules[0].host}')
[[ "$HOST" == "myapp.example.com" ]] && { echo -e "${GREEN}✓${NC} Host configured"; ((SCORE++)); } || echo -e "${RED}✗${NC} Host: $HOST"

BACKEND=$(kubectl get ingress web-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
[[ "$BACKEND" == "web-service" ]] && { echo -e "${GREEN}✓${NC} Backend service correct"; ((SCORE++)); } || echo -e "${RED}✗${NC} Backend: $BACKEND"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED${NC}" || echo -e "${RED}✗ FAILED${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-18/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete ingress web-ingress --ignore-not-found=true
kubectl delete service web-service --ignore-not-found=true
kubectl delete deployment web-app --ignore-not-found=true
echo "Exercise 18 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-18/solution.sh" << 'EOF'
#!/bin/bash
kubectl create deployment web-app --image=nginx:1.25 --replicas=2
kubectl expose deployment web-app --name=web-service --port=80

cat << 'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
YAML
EOF

chmod +x "${EXERCISES_DIR}/exercise-18"/*.sh

# ============================================
# EXERCISE 19: Troubleshooting - Broken Pod
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-19"

cat > "${EXERCISES_DIR}/exercise-19/instructions.txt" << 'EOF'
EXERCISE 19: Troubleshooting - Fix Broken Pod
==============================================
DIFFICULTY: Hard | TIME: 15 minutes | DOMAIN: Troubleshooting (30%)

SCENARIO:
A pod named 'broken-app' has been created but is not running.
Your task is to identify and fix ALL issues.

TASKS:
1. Investigate why the pod 'broken-app' is not running
2. Fix all configuration issues
3. Ensure the pod reaches Running status
4. Document what was wrong (optional)

HINTS:
- Check pod status and events
- Look at resource requests/limits
- Verify image name
- Check container command
EOF

cat > "${EXERCISES_DIR}/exercise-19/setup.sh" << 'EOF'
#!/bin/bash
echo "Setting up broken pod..."

# Create a pod with multiple issues
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
spec:
  containers:
  - name: app
    image: nginx:wrongtag
    resources:
      requests:
        memory: "10Gi"
        cpu: "8"
    command: ["/bin/sh"]
    args: ["-c", "nonexistent-command"]
YAML

echo "Pod 'broken-app' created with issues. Fix it!"
EOF

cat > "${EXERCISES_DIR}/exercise-19/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SCORE=0; TOTAL=3

echo "Checking Exercise 19..."
kubectl get pod broken-app &>/dev/null && { echo -e "${GREEN}✓${NC} Pod exists"; ((SCORE++)); } || { echo -e "${RED}✗${NC} Pod missing"; exit 1; }

IMG=$(kubectl get pod broken-app -o jsonpath='{.spec.containers[0].image}')
if [[ "$IMG" =~ ^nginx:[0-9]+\.[0-9]+ ]]; then
    echo -e "${GREEN}✓${NC} Image fixed ($IMG)"
    ((SCORE++))
else
    echo -e "${RED}✗${NC} Image still wrong: $IMG"
fi

STATUS=$(kubectl get pod broken-app -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Running" ]] && { echo -e "${GREEN}✓${NC} Pod is Running!"; ((SCORE++)); } || echo -e "${RED}✗${NC} Pod status: $STATUS"

echo ""; echo "Score: $SCORE/$TOTAL"
[ $SCORE -eq $TOTAL ] && echo -e "${GREEN}✓ PASSED - Great troubleshooting!${NC}" || echo -e "${RED}✗ Keep investigating...${NC}"
EOF

cat > "${EXERCISES_DIR}/exercise-19/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete pod broken-app --ignore-not-found=true
echo "Exercise 19 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-19/solution.sh" << 'EOF'
#!/bin/bash
echo "Solution for Exercise 19:"
echo "Issues found:"
echo "1. Wrong image tag: nginx:wrongtag -> should be nginx:1.25 or similar"
echo "2. Excessive resource requests (10Gi memory, 8 CPU)"
echo "3. Invalid command: nonexistent-command"
echo ""
echo "Fixing..."

kubectl delete pod broken-app
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
YAML

echo "Pod fixed!"
EOF

chmod +x "${EXERCISES_DIR}/exercise-19"/*.sh

# ============================================
# EXERCISE 20: Backup and Restore ETCD
# ============================================
mkdir -p "${EXERCISES_DIR}/exercise-20"

cat > "${EXERCISES_DIR}/exercise-20/instructions.txt" << 'EOF'
EXERCISE 20: ETCD Backup and Restore (ADVANCED)
================================================
DIFFICULTY: Hard | TIME: 20 minutes | DOMAIN: Cluster Architecture (25%)

TASKS:
1. Create a backup of the etcd database:
   - Save to: /tmp/etcd-backup.db
   - Use etcdctl snapshot save
2. Create a test deployment 'backup-test' with 2 replicas
3. Simulate data loss by deleting the deployment
4. Restore from the backup
5. Verify the deployment is restored

IMPORTANT:
- This requires access to etcd
- On minikube: minikube ssh, then use etcdctl
- ETCD certificates usually in /etc/kubernetes/pki/etcd/
- This is a SIMULATION - actual restore is cluster-dependent

Note: This exercise demonstrates the concept but may not work
perfectly on all cluster types (minikube, kubeadm, managed clusters)
EOF

cat > "${EXERCISES_DIR}/exercise-20/setup.sh" << 'EOF'
#!/bin/bash
echo "Exercise 20: ETCD Backup/Restore"
echo "================================="
echo ""
echo "This exercise demonstrates etcd backup concepts."
echo "Actual commands vary by cluster setup."
echo ""
echo "For minikube, you'll need to:"
echo "1. minikube ssh"
echo "2. Find etcd pod: kubectl get po -n kube-system | grep etcd"
echo "3. Use etcdctl inside the etcd container"
echo ""
echo "Common etcdctl command structure:"
echo "  ETCDCTL_API=3 etcdctl snapshot save /tmp/backup.db \\"
echo "    --endpoints=https://127.0.0.1:2379 \\"
echo "    --cacert=/etc/kubernetes/pki/etcd/ca.crt \\"
echo "    --cert=/etc/kubernetes/pki/etcd/server.crt \\"
echo "    --key=/etc/kubernetes/pki/etcd/server.key"
EOF

cat > "${EXERCISES_DIR}/exercise-20/check.sh" << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}Exercise 20: Conceptual Check${NC}"
echo "================================"
echo ""
echo "This exercise tests your understanding of etcd backup/restore."
echo ""
echo "Key concepts you should understand:"
echo "  ✓ How to use etcdctl snapshot save"
echo "  ✓ Required certificates for etcd access"
echo "  ✓ How to restore from snapshot"
echo "  ✓ Difference between backup and restore"
echo ""
echo -e "${GREEN}If you can explain these concepts, you've passed!${NC}"
echo ""
echo "For the exam, remember:"
echo "1. ETCDCTL_API=3 etcdctl snapshot save <path>"
echo "2. Provide --endpoints, --cacert, --cert, --key"
echo "3. Restore: etcdctl snapshot restore <path> --data-dir=<new-dir>"
echo "4. Update etcd manifest to use new data-dir"
EOF

cat > "${EXERCISES_DIR}/exercise-20/cleanup.sh" << 'EOF'
#!/bin/bash
kubectl delete deployment backup-test --ignore-not-found=true 2>/dev/null || true
rm -f /tmp/etcd-backup.db 2>/dev/null || true
echo "Exercise 20 cleaned up"
EOF

cat > "${EXERCISES_DIR}/exercise-20/solution.sh" << 'EOF'
#!/bin/bash
echo "ETCD Backup/Restore Solution (Conceptual)"
echo "=========================================="
echo ""
echo "1. BACKUP:"
cat << 'CMD'
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
CMD

echo ""
echo "2. CREATE TEST DATA:"
echo "kubectl create deployment backup-test --image=nginx --replicas=2"
echo ""
echo "3. VERIFY BACKUP:"
echo "ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db"
echo ""
echo "4. RESTORE (if needed):"
cat << 'CMD'
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
CMD

echo ""
echo "5. UPDATE ETCD MANIFEST:"
echo "Edit /etc/kubernetes/manifests/etcd.yaml"
echo "Change --data-dir to /var/lib/etcd-restore"
EOF

chmod +x "${EXERCISES_DIR}/exercise-20"/*.sh

# Create README
cat > README.md << 'EOF'
# CKA Training System

Système complet d'entraînement pour la certification CKA (Certified Kubernetes Administrator).
**Optimisé pour Minikube sur Git Bash Windows 11**

## Installation

```bash
# 1. Rendre le script principal exécutable
chmod +x cka-training.sh setup-aliases.sh

# 2. Configurer les alias Kubernetes (IMPORTANT !)
./setup-aliases.sh
source ~/.bashrc

# 3. Vérifier que tout fonctionne
k version
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

**J-5 (18/01)**: Exercices 01-07 (Bases)
**J-4 (19/01)**: Exercices 08-14 (Intermédiaire)
**J-3 (20/01)**: Exercices 15-20 (Avancé)
**J-2 (21/01)**: Révision des exercices ratés
**J-1 (22/01)**: Simulation d'examen complet

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

Bon courage pour le 23/01! 🚀
EOF

# Create quick start guide
cat > QUICKSTART.txt << 'EOF'
=================================
CKA TRAINING - DÉMARRAGE RAPIDE
=================================

📋 INSTALLATION (une seule fois)
   
   chmod +x setup-aliases.sh cka-training.sh
   ./setup-aliases.sh
   source ~/.bashrc

✅ VÉRIFIER L'INSTALLATION

   k version              # Doit afficher la version K8s
   echo $do               # Doit afficher: --dry-run=client -o yaml

🎯 PREMIER EXERCICE

   ./cka-training.sh setup 01
   
   (travaillez avec kubectl / k)
   
   ./cka-training.sh check 01
   
   ./cka-training.sh reset 01

⚡ ALIAS DISPONIBLES

   k = minikube kubectl --
   
   kgp    → get pods
   kgd    → get deployments  
   kgs    → get services
   kdp    → describe pod
   kl     → logs
   ka     → apply -f
   kex    → exec -it
   
   $do    → --dry-run=client -o yaml
   $now   → --force --grace-period=0

📝 EXEMPLES PRATIQUES

   # Lister les pods
   kgp
   
   # Créer un manifest
   k run nginx --image=nginx $do > pod.yaml
   
   # Créer un deployment
   k create deploy web --image=nginx $do
   
   # Exposer un service
   k expose deploy web --port=80
   
   # Scaler
   k scale deploy web --replicas=5
   
   # Update image
   k set image deploy/web nginx=nginx:1.25
   
   # Logs en temps réel
   klf mon-pod

🔍 COMMANDES FRÉQUENTES CKA

   # Get avec output
   k get pods -o wide
   k get pods -o yaml
   k get pods -o jsonpath='{.items[0].metadata.name}'
   
   # Describe pour debug
   kdp mon-pod
   k get events --sort-by=.metadata.creationTimestamp
   
   # Labels et selectors
   k get pods -l app=web
   k label pod mon-pod env=prod
   
   # Namespaces
   k get pods -n kube-system
   k config set-context --current --namespace=dev

📚 DOCUMENTATION

   kubernetes.io uniquement pendant l'exam !
   
   k explain pod.spec
   k explain deployment.spec.template

⏱️ GESTION DU TEMPS (EXAMEN)

   17 questions en 2h = 7 min/question
   
   Questions faciles (2-4%): 3-4 min
   Questions moyennes (5-7%): 6-8 min
   Questions difficiles (8-13%): 10-15 min
   
   Marquez et revenez sur les difficiles !

💡 TIPS EXAMEN

   ✓ Toujours vérifier avec k get / k describe
   ✓ Utiliser $do pour générer des YAMLs
   ✓ Copier-coller peut bugger, taper court
   ✓ Les alias vous font gagner 30% de temps
   ✓ Lire TOUTES les questions d'abord

BON COURAGE POUR LE 23/01! 🎯🚀
EOF

# Create test script
cat > test-setup.sh << 'EOF'
#!/bin/bash
# Script de vérification de l'installation

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================"
echo "Test de l'installation CKA"
echo "================================"
echo ""

# Test 1: Minikube
echo -n "Test 1: Minikube... "
if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Minikube non trouvé${NC}"
fi

# Test 2: Minikube status
echo -n "Test 2: Minikube running... "
if minikube status &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Minikube non démarré (run: minikube start)${NC}"
fi

# Test 3: Alias kubectl
echo -n "Test 3: Alias kubectl... "
if alias kubectl &> /dev/null 2>&1 || type kubectl &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Alias non chargé (run: source ~/.bashrc)${NC}"
fi

# Test 4: Alias k
echo -n "Test 4: Alias k... "
if alias k &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Alias k non chargé (run: source ~/.bashrc)${NC}"
fi

# Test 5: Variable $do
echo -n "Test 5: Variable \$do... "
if [ ! -z "$do" ]; then
    echo -e "${GREEN}✓${NC} ($do)"
else
    echo -e "${YELLOW}⚠ Variable non définie (run: source ~/.bashrc)${NC}"
fi

# Test 6: Exercices
echo -n "Test 6: Exercices créés... "
if [ -d "exercises/exercise-01" ]; then
    count=$(ls -d exercises/exercise-* 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} ($count exercices)"
else
    echo -e "${RED}✗ Dossier exercises manquant${NC}"
fi

# Test 7: Scripts exécutables
echo -n "Test 7: Scripts exécutables... "
if [ -x "cka-training.sh" ] && [ -x "setup-aliases.sh" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Run: chmod +x *.sh${NC}"
fi

echo ""
echo "================================"
echo "Commandes de test suggérées:"
echo "================================"
echo "k version"
echo "k get nodes"
echo "k get pods -A"
echo "./cka-training.sh list"
echo ""
EOF

chmod +x test-setup.sh

echo -e "${GREEN}✓ Test script created${NC}"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Created:"
echo "  📁 cka-training/"
echo "     ├── cka-training.sh          (main training script)"
echo "     ├── setup-aliases.sh         (configure Git Bash aliases)"
echo "     ├── test-setup.sh            (verify installation)"
echo "     ├── README.md                (full documentation)"
echo "     ├── QUICKSTART.txt           (quick reference)"
echo "     └── exercises/               (20 exercises: 01-20)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. cd cka-training"
echo "  2. ./setup-aliases.sh           # Configure aliases for minikube"
echo "  3. source ~/.bashrc             # Load aliases"
echo "  4. ./test-setup.sh              # Verify everything works"
echo "  5. ./cka-training.sh            # Start training!"
echo ""
echo -e "${BLUE}==================================${NC}"
echo -e "${GREEN}Aliases configured:${NC}"
echo -e "${BLUE}==================================${NC}"
echo "  k         → minikube kubectl --"
echo "  kgp       → get pods"
echo "  kgd       → get deployments"
echo "  kdp       → describe pod"
echo "  \$do       → --dry-run=client -o yaml"
echo "  \$now      → --force --grace-period=0"
echo "  + 20 more aliases (see README.md)"
echo ""
echo -e "${BLUE}Good luck with your CKA exam on 23/01!${NC}"
echo ""
