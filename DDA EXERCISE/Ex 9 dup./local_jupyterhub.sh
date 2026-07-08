#!/bin/bash

CMD=$1 # setup, start_jupyterhub, stop_jupyterhub

WORKING_DIR=${2:-"$PWD"} # Working directory in local machine

DOCKER_IMAGE_NAME="dda-jupyterhub"
DOCKER_CONTAINER_NAME="${DOCKER_IMAGE_NAME}_container"
DOCKER_USER="dda"

if [[ "$1" == "help" ]] || [[ "$#" -lt "1" ]]; then
    echo "About:"
    echo "This script starts jupyterhub session on local machine using docker."
    echo ""
    echo "Usage"
    echo "$0 < help | setup | start [/path/to/directory/on/local_machine] | stop >"
    echo ""
    echo -e "  help\t: Print this message"
    echo -e "  setup\t: Setup docker image"
    echo -e "  start [/path/to/directory/on/local_machine]"
    echo -e "       \t: Start JupyterHub Instance at provided directory."
    echo -e "       \t  Default is current working directory"
    echo -e "  stop\t: Stop JupyterHub Instance"
    echo ""
fi

# Check if Docker is already installed
if ! command -v docker &> /dev/null; then
    echo "[ERROR]: Docker is not installed. Please visit following website for more information:"
    echo "[ERROR]: https://docs.docker.com/get-docker/"
    echo "[ERROR]: Exiting..."
    exit 1
fi

if [[ "$CMD" == "setup" ]]; then
    echo "Creating requirements.txt"
    cat << EOF > ./requirements.txt
jupyterhub
jupyter_server
jupyterlab
beautifulsoup4==4.12.3
bqplot==0.12.43
certifi==2024.6.2
findspark==2.0.1
folium==0.16.0
fonttools==4.53.0
geopandas==1.0.0
gdown==5.2.0
grpcio==1.64.1
ipyevents==2.0.2
ipyfilechooser==0.6.0
ipykernel==6.29.5
ipython==8.25.0
ipytree==0.2.2
jsonschema-specifications==2023.12.1
jsonschema==4.22.0
jupyter_client==8.6.2
leafmap==0.32.1
prompt_toolkit==3.0.45
pystac-client==0.8.2
pystac==1.10.1
requests==2.32.3
wget==3.2
whiteboxgui==2.3.0
pyspark==3.5.1
EOF

    echo "Creating Dockerfile"
    cat << EOF > ./Dockerfile
# Use the official JupyterHub image from Docker Hub
FROM jupyterhub/jupyterhub:latest

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y npm openjdk-17-jdk wget build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install configurable-http-proxy
RUN pip install configurable-http-proxy

# Install PySpark
ENV SPARK_VERSION=3.5.1
ENV HADOOP_VERSION=3
RUN wget -qO- "https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz" | \
    tar xvz -C /opt/ && \
    ln -s "/opt/spark-\${SPARK_VERSION}-bin-hadoop\${HADOOP_VERSION}" /opt/spark

# Set environment variables for Spark
ENV SPARK_HOME=/opt/spark
ENV PATH=\$SPARK_HOME/bin:\$PATH

# Install Python packages from requirements.txt
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt

# Create application user
RUN useradd -ms /bin/bash $DOCKER_USER

# Copy the entrypoint script into the container
COPY --chown=$DOCKER_USER:users entrypoint.sh /home/$DOCKER_USER/.entrypoint.sh
RUN chmod +x /home/$DOCKER_USER/.entrypoint.sh

# Switch back to application user
USER $DOCKER_USER

# Expose the JupyterHub port
EXPOSE 8000

# Set the entrypoint to the script
ENTRYPOINT ["/home/$DOCKER_USER/.entrypoint.sh"]

EOF

    echo "Creating entrypoint script"
    cat << EOF > ./entrypoint.sh
#!/bin/bash

# Match container user to host user so file permissions work on the mounted volume
if [ -n "\${HOST_UID}" ] && [ -n "\${HOST_GID}" ]; then
    groupmod -o -g "\${HOST_GID}" "$DOCKER_USER" 2>/dev/null || true
    usermod -o -u "\${HOST_UID}" "$DOCKER_USER" 2>/dev/null || true
fi

# Ensure the mounted notebooks directory is writable by the application user
chown -R "$DOCKER_USER:$DOCKER_USER" "/home/$DOCKER_USER/notebooks"

cat > /srv/jupyterhub/jupyterhub_config.py << PYEOF
c = get_config()
c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.JupyterHub.base_url = '/'
c.JupyterHub.authenticator_class = 'dummy'
c.DummyAuthenticator.password = ''
c.JupyterHub.allow_named_servers = True
c.Authenticator.allow_all = True
c.Spawner.notebook_dir = '/home/$DOCKER_USER/notebooks'
PYEOF

# Start JupyterHub
exec jupyterhub --config=/srv/jupyterhub/jupyterhub_config.py

EOF

    echo "Building docker image"
    # Use classic builder to avoid BuildKit cache issues
    if DOCKER_BUILDKIT=0 docker build --no-cache -t $DOCKER_IMAGE_NAME .; then
        echo "Build successful. Cleaning up temporary files."
        rm -f ./Dockerfile ./entrypoint.sh ./requirements.txt
    else
        echo "[ERROR]: Docker build failed. Temporary files are kept for debugging:"
        echo "  - Dockerfile"
        echo "  - entrypoint.sh"
        echo "  - requirements.txt"
        exit 1
    fi

elif [[ "$CMD" == "start" ]]; then

    # Stop and remove any existing containers using the image
    running_containers="$(docker ps -a --filter "ancestor=$DOCKER_IMAGE_NAME" --format "{{.ID}}")"
    for container_i in $running_containers; do
        echo $container_i
        docker stop $container_i 2>&1 > /dev/null
        docker container remove $container_i 2>&1 > /dev/null
    done

    echo "Starting JupyterHub session"

    docker run -d \
        -v "$WORKING_DIR:/home/$DOCKER_USER/notebooks" \
        -p 8000:8000 \
        --user root \
        -e HOST_UID=$(id -u) \
        -e HOST_GID=$(id -g) \
        --name $DOCKER_CONTAINER_NAME \
        $DOCKER_IMAGE_NAME

    echo "In your browser, go to following web address to start working"
    echo "  http://0.0.0.0:8000"
    echo ""
    echo "Use following information at the login screen:"
    echo "  Username: $DOCKER_USER"
    echo "  No password. Keep it blank."

elif [[ "$CMD" == "stop" ]]; then

    echo "Stopping JupyterHub session"

    # Stop and remove all containers using the image
    running_containers="$(docker ps -a --filter "ancestor=$DOCKER_IMAGE_NAME" --format "{{.ID}}")"
    for container_i in $running_containers; do
        docker stop $container_i 2>&1 > /dev/null
        docker rm $container_i 2>&1 > /dev/null
        docker container remove $container_i 2>&1 > /dev/null
    done

fi
