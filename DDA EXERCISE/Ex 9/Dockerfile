# Use the official JupyterHub image from Docker Hub
FROM jupyterhub/jupyterhub:latest

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y npm openjdk-17-jdk wget build-essential     && rm -rf /var/lib/apt/lists/*

# Install configurable-http-proxy
RUN pip install configurable-http-proxy

# Install PySpark
ENV SPARK_VERSION=3.5.1
ENV HADOOP_VERSION=3
RUN wget -qO- "https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz" |     tar xvz -C /opt/ &&     ln -s "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" /opt/spark

# Set environment variables for Spark
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$PATH

# Install Python packages from requirements.txt
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip &&     python3 -m pip install --no-cache-dir -r /tmp/requirements.txt

# Create application user
RUN useradd -ms /bin/bash dda

# Copy the entrypoint script into the container
COPY --chown=dda:users entrypoint.sh /home/dda/.entrypoint.sh
RUN chmod +x /home/dda/.entrypoint.sh

# Switch back to application user
USER dda

# Expose the JupyterHub port
EXPOSE 8000

# Set the entrypoint to the script
ENTRYPOINT ["/home/dda/.entrypoint.sh"]

