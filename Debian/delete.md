## Eliminar Linux (debian, ubuntu, fedora, etc.) desde Windows (GRUB persistente)

1. Abrir CMD como administrador y ejecutar `diskpart`

```bash
C:\WINDOWS\system32>diskpart 
Microsoft DiskPart version 10.0.19041.3636
Copyright (C) Microsoft Corporation.
On computer: TuPC

DISKPART>     
```

2. Listar discos y particiones para identificar la partición EFI

```cmd
list disk
list partition
```

3. Seleccionar la partición de arranque EFI y asignarle una letra

```cmd
sel disk X
sel part Y
assign letter Z
```

4. Abrir un `nuevo CMD` como `administrador` y acceder a la unidad Z

```cmd
Z:
```

5. Navegar al directorio EFI

```cmd
cd EFI
```

6. Eliminar la carpeta Linux (por ejemplo, ubuntu)

```cmd
rd /s ubuntu
```

7. Cerrar ese CMD y regresar al `diskpart` anterior para remover la letra asignada

```cmd
remove letter Z
```

8. Salir de `diskpart`

```cmd
exit
```

9. Ver la lista de arranque

```cmd
bcdedit /enum firmware
```

10. Localizar la entrada que corresponda a Linux, copiar el identificador y ejecutar

```cmd
bcdedit /delete {identificador}
```

Reiniciar el equipo para verificar que el GRUB ha sido eliminado.