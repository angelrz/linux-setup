# Powerline

Configura Powerline en el terminal de Ubuntu usando un script automático.

## Requisitos

- Acceso con permisos de administrador.

## Uso

1. Dar permisos de ejecución al script.

```bash
chmod +x setup.sh
```

2. Ejecutarlo con permisos de administrador.

```bash
sudo ./setup.sh
```

## Qué hace el script

- Instala `fonts-powerline`.
- Agrega el alias de fuente para `PowerlineSymbols` si no existe.
- Actualiza la caché de fuentes con `fc-cache -vf`.

## Notas

- El script crea un respaldo de `/etc/fonts/conf.d/10-powerline-symbols.conf` antes de modificarlo.
