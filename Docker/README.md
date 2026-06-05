# Docker Engine en Ubuntu 24.04 sin sudo

> [!NOTE]
> Exclusivo para Ubuntu LTS 24.04 y explicado en la [documentación de Docker](https://docs.docker.com/desktop/setup/install/linux/ubuntu/#prerequisites)

## Descargar prerequisitos

```bash
sudo apt install gnome-terminal
```

Eliminar todos los residuos de instalaciones anteriores:

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

## Instalar el repositorio

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Add the repository to Apt sources:

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

Instalar la última versión

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Probar funcionamiento con la imagen `hello-world`

```bash
sudo docker run hello-world
```

## Ejecutar sin superusuario (sudo)

Crear/añadir el grupo de `docker`:

```bash
sudo groupadd docker
```

Agrega tu `usuario` al grupo de `docker`:

```bash
sudo usermod -aG docker $USER
```

> [!CAUTION]
> Sustituir `$USER` por tu usuario, ejemplo, si tu usuario es `tux` ejecuta `sudo usermod -aG docker tux`

Reinicia, cierra sesión o abre un nuevo terminal para que haga efecto. Teclea el sig comando para aplicar los cambios en los grupo.

```bash
newgrp docker
```

## Desinstalar

**Eliminar** Docker Engine

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
```

**Eliminar** images, contenedores, volumenes, etc.

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

**Eliminar** el repositorio y claves

```bash
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.asc
```
