## Quick Start¶
With watchtower you can update the running version of your containerized app simply by pushing a new image to the 
Docker Hub or your own image registry. 

Watchtower will pull down your new image, gracefully shut down your existing container and restart it with the same 
options that were used when it was deployed initially. Run the watchtower container with the following command:

```
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```
## Containrs que no devem ser atualizados automaticamente
Por padrão, os argumentos terão precedência sobre os rótulos.

Isso significa que se você definir `WATCHTOWER_MONITOR_ONLY` como true ou 
usar `--monitor-only`, um contêiner com `com.centurylinklabs.watchtower.monitor-only`
definido como false não será atualizado. 

Se você definir `WATCHTOWER_LABEL_TAKE_PRECEDENCE` como true ou usar 
`--label-take-precedence`, o contêiner também será atualizado. 
Isso também se aplica à opção no pull. 

Se você definir `WATCHTOWER_NO_PULL` como true ou usar `--no-pull`, um contêiner 
com `com.centurylinklabs.watchtower.no-pull` definido como false não puxará a 
nova imagem. 

Se você definir `WATCHTOWER_LABEL_TAKE_PRECEDENCE` como true ou usar 
`--label-take-precedence`, o contêiner puxará a imagem



## REFERENCE
- [Site](https://containrrr.dev/watchtower/)
- [Github](https://github.com/containrrr/watchtower/)
- [Argumentos](https://containrrr.dev/watchtower/arguments/)