# Powerline

Configurar powerline en terminal de ubuntu

## instalar 


```bash 
sudo apt install fonts-powerline
```

## ajustar fuente

```bash
sudo nano /etc/fonts/conf.d/10-powerline-symbols.conf
```

Agregar los siguiente

```
    <fontconfig>
    ...
            <alias>
                    <family>Ubuntu Sans Mono</family>
                    <prefer><family>PowerlineSymbols</family></prefer>
            </alias>
```

Asegurar cambio

```
sudo fc-cache -vf
```
