# Whats Up Docker

Container que monitora as imagens de todos os container em uso.

## Modo de publicar o container

- Informações necessárias para publicar o container  

  - DNS registro tipo A, seguindo o padrão de nomenclatura do seu ambiente.
  - Hostname do servidor onde será publicado o container.


- Criar pasta no servidor
```shell
mkdir -p /opt/wud
```
- Copiar o conteúdo deste diretório para a pasta acima criada, junto com um `.env`
  baseado em `.env.example`.


- Alterar o conteúdo da variável VARURL e executar os comandos abaixo, um por vez, para \
alterar as configurações do arquivo ".env".
```shell
VARHOST=`hostname -s`
VARURL=<nome-do-host>
sed -i "s/ChangeHostName/$VARHOST/g" .env
sed -i "s/DnsName/$VARURL/g" .env
```

- Iniciar o container
```shell
docker compose up -d
```

- No navegador web vá para o dns criado, exemplo host.example.com