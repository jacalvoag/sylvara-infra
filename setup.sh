set -euo pipefail

# ─── Variables que debes editar antes de correr el script ────────────────────
GITHUB_REPO="https://github.com/jacalvoag/sylvara-infra.git"  # reemplaza <ORG>
DEPLOY_DIR="/opt/sylvara-infra"

# ─── Colores para output ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── 1. Verificar que se corre como root ─────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "Este script debe ejecutarse como root. Usa: sudo bash setup.sh"
fi

info "Iniciando configuración del Droplet de infra..."

# ─── 2. Actualizar el sistema ─────────────────────────────────────────────────
info "Actualizando paquetes del sistema..."
apt-get update -qq
apt-get upgrade -y -qq

# ─── 3. Instalar dependencias base ────────────────────────────────────────────
info "Instalando dependencias base..."
apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  git \
  ufw

# ─── 4. Instalar Docker ───────────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  warning "Docker ya está instalado, omitiendo instalación."
else
  info "Instalando Docker..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -qq
  apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  systemctl enable docker
  systemctl start docker
  info "Docker instalado correctamente."
fi

# ─── 5. Verificar versiones ───────────────────────────────────────────────────
info "Docker versión: $(docker --version)"
info "Docker Compose versión: $(docker compose version)"

# ─── 6. Clonar el repositorio ─────────────────────────────────────────────────
if [[ -d "$DEPLOY_DIR" ]]; then
  warning "El directorio $DEPLOY_DIR ya existe. Haciendo git pull..."
  git -C "$DEPLOY_DIR" pull
else
  info "Clonando repositorio en $DEPLOY_DIR..."
  git clone "$GITHUB_REPO" "$DEPLOY_DIR"
fi

# ─── 7. Crear el .env si no existe ───────────────────────────────────────────
if [[ -f "$DEPLOY_DIR/.env" ]]; then
  warning ".env ya existe, no se sobreescribe."
else
  info "Creando .env desde .env.example..."
  cp "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"
  echo ""
  echo "================================================================"
  echo "  ACCIÓN REQUERIDA: edita el archivo .env antes de continuar"
  echo "  nano $DEPLOY_DIR/.env"
  echo ""
  echo "  Valores que DEBES cambiar:"
  echo "    BIND_HOST      → IP privada de este Droplet"
  echo "    POSTGRES_PASSWORD"
  echo "    MONGO_ROOT_PASSWORD"
  echo "    MONGO_APP_PASSWORD"
  echo "================================================================"
  echo ""
fi

# ─── 8. Configurar firewall (UFW) ─────────────────────────────────────────────
info "Configurando firewall UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH — abierto para poder conectarte
ufw allow 22/tcp comment "SSH"

# PostgreSQL y MongoDB — SOLO desde la red privada de DigitalOcean (10.0.0.0/8)
# Cuando conozcas la IP privada del Droplet del backend, puedes restringirlo más:
#   ufw allow from <IP_PRIVADA_BACKEND> to any port 5432
#   ufw allow from <IP_PRIVADA_BACKEND> to any port 27017
ufw allow from 10.0.0.0/8 to any port 5432 comment "PostgreSQL - VPC privada"
ufw allow from 10.0.0.0/8 to any port 27017 comment "MongoDB - VPC privada"

ufw --force enable
info "Firewall configurado."
ufw status verbose

# ─── 9. Instrucciones finales ─────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "  Setup completado."
echo ""
echo "  Próximos pasos:"
echo "  1. Editar el .env:"
echo "     nano $DEPLOY_DIR/.env"
echo ""
echo "  2. Levantar los contenedores:"
echo "     cd $DEPLOY_DIR && docker compose up -d"
echo ""
echo "  3. Verificar que estén healthy:"
echo "     docker compose ps"
echo ""
echo "  4. (Opcional) Una vez que tengas la IP privada del Droplet"
echo "     del backend, restringir el firewall a esa IP exacta:"
echo "     ufw delete allow from 10.0.0.0/8 to any port 5432"
echo "     ufw allow from <IP_PRIVADA_BACKEND> to any port 5432"
echo "     ufw delete allow from 10.0.0.0/8 to any port 27017"
echo "     ufw allow from <IP_PRIVADA_BACKEND> to any port 27017"
echo "================================================================"