# docker/jupyter-hadoop-spark/Dockerfile
# Base: CUDA-enabled TensorFlow notebook (includes Python, JupyterLab)
FROM jupyter/base-notebook:latest

USER root

# Install system dependencies: Java (for Hadoop/Spark), git, fuse
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jre-headless \
    curl \
    ca-certificates \
    fuse \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Hadoop client (no HDFS daemon) and set up hadoop-fuse-dfs
ENV HADOOP_VERSION=3.3.6
RUN curl -fsSL https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
    | tar -xz -C /opt && \
    ln -s /opt/hadoop-$HADOOP_VERSION /opt/hadoop
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH

# Install PySpark (match cluster Spark version as needed)
RUN pip install --no-cache-dir pyspark==3.5.1

# Install JAX with CUDA (adjust as needed)
RUN pip install --no-cache-dir -U "jax[cuda12_pip]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

# Generate a list of installed packages
RUN pip freeze > /opt/packages.txt

# Startup script for Git clone
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Allow FUSE inside container
RUN sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf || true

RUN usermod -aG sudo jovyan &&\
    usermod -aG root jovyan 

# Clean up and switch back to jovyan
USER ${NB_UID}

# Default working directory
WORKDIR /home/jovyan

# Start with custom script
CMD ["/usr/local/bin/start.sh"]
