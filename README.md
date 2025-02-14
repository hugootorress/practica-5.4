# Práctica 5.4: Publicación de una Imagen Docker a DockerHub con GitHub Actions

## Crear la Imagen Docker
Usamos la última versión de Ubuntu como imagen base
```bash
FROM ubuntu:latest
```


Actualizamos los paquetes e instalamos Nginx y Git
```bash
RUN apt-get update \
    && apt-get install -y nginx git
```

Clonamos el repositorio de GitHub en el directorio de Nginx
```bash
RUN git clone https://github.com/josejuansanchez/2048 /usr/share/nginx/html/
```

Exponemos el puerto 80 (por donde Nginx escuchará) y establecemos el comando para ejecutar Nginx en primer plano:
```bash
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"] 
```
## Construir la Imagen Docker
Construimos la imagen
```
docker build -t 2048:1.0 .
```

## Subir la imagen a DockerHub
Para subir nuestra imagen a DockerHub, primero debemos iniciar sesión con nuestras credenciales:
```bash
docker login
```

Etiquetamos la imagen con nuestro nombre de usuario en DockerHub:
```bash
docker tag 2048:1.0 hugootorress/2048:1.0
```

Finalmente subimos la imagen a dockerhub.
```bash
docker push hugootorress/2048:1.0
```
## Configuración de GitHub Actions
En GitHub, nos dirigimos a la pestaña Actions de nuestro repositorio y seleccionamos la opción de New workflow. Elegimos Push Docker Container.

Esto nos abrirá un archivo llamado docker-image.yml, que debemos dejar de la siguiente manera:
```bash
name: Publish image to Docker Hub

# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.

on:
  push:
    branches: [ "main" ]
    # Publish semver tags as releases.
    tags: [ 'v*.*.*' ]
  workflow_dispatch:

env:
  # Use docker.io for Docker Hub if empty
  REGISTRY: docker.io
  # github.repository as <account>/<repo>
  #IMAGE_NAME: ${{ github.repository }}
  IMAGE_NAME: 2048
  IMAGE_TAG: latest

jobs:
  build:

    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      # Set up BuildKit Docker container builder to be able to build
      # multi-platform images and export cache
      # https://github.com/docker/setup-buildx-action
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@f95db51fddba0c2d1ec667646a06c2ce06100226 # v3.0.0

      # Login against a Docker registry except on PR
      # https://github.com/docker/login-action
      - name: Log into registry ${{ env.REGISTRY }}
        uses: docker/login-action@343f7c4344506bcbf9b4de18042ae17996df046d # v3.0.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # This action can be used to check the content of the variables
      - name: Debug
        run: |
          echo "github.repository: ${{ github.repository }}"
          echo "env.REGISTRY: ${{ env.REGISTRY }}"
          echo "github.sha: ${{ github.sha }}"
          echo "env.IMAGE_NAME: ${{ env.IMAGE_NAME }}"

      # Build and push Docker image with Buildx (don't push on PR)
      # https://github.com/docker/build-push-action
      - name: Build and push Docker image
        id: build-and-push
        uses: docker/build-push-action@0565240e2d4ab88bba5387d719585280857ece09 # v5.0.0
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ env.REGISTRY }}/${{ secrets.DOCKERHUB_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }}
          cache-from: type=gha
          cache-to: type=gha,mode=max      
```

### Creación de un Personal Access Token en DockerHub
Accede a DockerHub y genera un Personal Access Token con permisos de Read, Write y Delete (RWD).
Guárdalo en GitHub dentro de Settings > Secrets and Variables > Actions:
- DOCKER_HUB_USERNAME: Tu nombre de usuario en DockerHub.
- DOCKER_HUB_TOKEN: El token generado.

## Verificación de la Imagen en GitHub
Una vez configurado el flujo de trabajo, cada vez que hagas un push al repositorio, GitHub Actions construirá y subirá la imagen automáticamente a DockerHub.

Para verificar si la imagen se ha publicado correctamente, podemos ir a la pestaña Actions de GitHub y comprobar que los pasos se ejecutan correctamente. Si todo funciona bien, debería verse algo como esto:
[!Captura de como debe funcionar](img/imagendocker.png)
