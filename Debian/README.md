# Configuración Debian 12

> [!note]
> Recordar, estamos iniciando el sistema, por ende todo se realiza con `su`

## Superusuario

```bash
su
```

## GRUB

- Evitar problemas horarios entre sistemas operativos

```bash
sudo timedatectl set-local-rtc 1
```

- DualBooT: Seleccionar el último sistema

```bash
nano /etc/default/grub
```

- Agregar/actualizar las siguientes líneas

```bash
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
```

**Salir y actualizar** el grub

```bash
sudo update-grub
```

---

## Uso de terminal

### Ejecución sudo con mi usuario

Entrar con `su` al modo [superusuario](#superusuario)

```bash
root@debian: 
```

Modificar le archivo /etc/sudoers

```bash
nano /etc/sudoers
```

Agregar `MI_USER`. Ver `*` cuando ingreso mi contraseña

```bash
Defaults    env_reset,pwfeedback
...

# User privilege specification
root    ALL=(ALL:ALL) ALL
MI_USER    ALL=(ALL:ALL) ALL
```

### Autocompletado en terminal

Instalar bash-completion

```bash
sudo apt update
sudo apt install bash-completion
```

Entrar al archivo ~/.bashrc

```bash
sudo nano ~/.bashrc
```

Verificar líneas en el archivo ~/.bashrc del root

```bash
# Activar bash-completion
if [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
fi
```

Si modifico/agrego, asegurar cambios

```bash
source ~/.bashrc
```

---

## Comandos, ventanas, experiencia

> **Activar el clic del touchpad**
> 
> Ratón y panel táctil > Panel Táctil > Tocar para pulsar

> **Terminal con teclado**
> 
> Teclado > Ver y personalizar Atajos > Atajo personalizado
> Comando: `gnome-terminal`

### Navegación y ventanas

> Teclado > Ver y personalizar Atajos > Navegación
> - Cambiar entre ventanas: `alt+tab`
> - Ocultar todas las ventanas normales: `super+d`
> - Cerrar ventana con `super+q`

> Teclado > Ver y personalizar Atajos > Ventanas
> - Cerrar ventana: `ctrl+q`

> Teclado > Ver y personalizar Atajos > Lanzadores
> - Carpeta personal: `super+e`
> - Configuracion: `super+i`

### Cierre inesperado de la calculadora

```bash
dconf write /org/gnome/calculator/refresh-interval 0
```

---

## Eliminar app/juegos en Debian 12 GNOME

```bash
sudo apt -y purge gnome-2048 gnome-contacts gnome-weather gnome-maps gnome-calendar gnome-clocks gnome-chess five-or-more simple-scan four-in-a-row cheese gnome-sound-recorder hitori gnome-klotski lightsoff gnome-mines gnome-nibbles gnome-mahjongg quadrapassel rhythmbox gnome-robots iagno gnome-music gnome-sudoku gnome-taquin gnome-tetravex thunderbird transmission-common transmission-gtk aisleriot swell-foop tali libreoffice* evolution debian-reference-common yelp && sudo apt -y autopurge 
```

## LMDE6

```bash
sudo apt -y purge gnote gedit libreoffice* hexchat hypnotix redshift onboard celluloid transmission gnome-calendar  gnome-2048 gnome-chess gnome-games gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sound-recorder gnome-sudoku gnome-taquin gnome-tetravex gnome-video-effects thunderbird pidgin remmina shotwell sound-juicer transmission-common transmission-gtk rhythmbox xterm drawing pix sticky thingy warpinator && sudo apt -y autopurge
```
