# Official JupyterHub Notebook Image with CUDA Support
# Base Image: https://hub.docker.com/r/jupyter/scipy-notebook
# CUDA Base: https://hub.docker.com/r/nvidia/cuda

FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

LABEL maintainer="ResearchOps Team"
LABEL description="JupyterHub singleuser image with NVIDIA drivers, JAX, PySpark, and HDFS support"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    HOME=/home/jovyan \
    PATH=/usr/local/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    git \
    vim \
    curl \
    openssh-client \
    build-essential \
    # Python 3 and pip
    python3 \
    python3-pip \
    python3-dev \
    # Java for Spark and Hadoop
    openjdk-11-jdk \
    # Additional tools
    htop \
    tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Configure locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Create user with sudo privileges
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    usermod -aG sudo $NB_USER && \
    echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$NB_USER && \
    chmod 0440 /etc/sudoers.d/$NB_USER

# Upgrade pip
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Set pip to break system packages (we're in a container, this is safe)
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install JupyterHub, JupyterLab and core packages
RUN pip3 install --no-cache-dir \
    jupyterhub>=3.0 \
    jupyterlab>=4.0 \
    notebook>=7.0 \
    ipywidgets>=8.0 \
    pandas>=2.0 \
    matplotlib>=3.7 \
    scipy>=1.10 \
    seaborn>=0.12 \
    scikit-learn>=1.3 \
    numpy>=1.24

# Install JAX with CUDA support
# Reference: https://github.com/google/jax#installation
RUN pip3 install --no-cache-dir \
    "jax[cuda11_pip]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html \
    jaxlib \
    flax \
    optax

# Install PySpark
# Reference: https://spark.apache.org/docs/latest/api/python/getting_started/install.html
RUN pip3 install --no-cache-dir \
    pyspark>=3.5.0 \
    pyarrow>=14.0.0 \
    findspark

# Install Hadoop client libraries
USER root
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Download Hadoop with retry and timeout, prefer CDN mirror
RUN wget --timeout=30 --tries=3 --quiet \
    https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz || \
    wget --timeout=30 --tries=3 --quiet \
    https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R $NB_USER:$NB_GID $HADOOP_HOME

# Install Spark
ENV SPARK_VERSION=3.5.7
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=jupyter
ENV PYSPARK_DRIVER_PYTHON_OPTS=lab

# Download Spark with retry and timeout, prefer CDN mirror
RUN wget --timeout=30 --tries=3 --quiet \
    https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz || \
    wget --timeout=30 --tries=3 --quiet \
    https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt/ && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 $SPARK_HOME && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    chown -R $NB_USER:$NB_GID $SPARK_HOME

# Install PostgreSQL client and Python driver
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    psycopg2-binary>=2.9.0 \
    sqlalchemy>=2.0.0

# Create Spark and Hadoop configuration directories
USER root
RUN mkdir -p $SPARK_HOME/conf && \
    mkdir -p $HADOOP_CONF_DIR && \
    chown -R $NB_USER:$NB_GID $SPARK_HOME/conf $HADOOP_CONF_DIR

# Copy Spark configuration template
RUN cat > $SPARK_HOME/conf/spark-defaults.conf <<EOF
# Spark Configuration
spark.master                     k8s://https://kubernetes.default.svc:443
spark.executor.instances         2
spark.executor.memory            4g
spark.driver.memory              4g
spark.executor.cores             2
spark.sql.warehouse.dir          hdfs://hdfs-namenode-0.hdfs-namenode.hdfs.svc.cluster.local:9000/user/hive/warehouse
spark.hadoop.fs.defaultFS        hdfs://hdfs-namenode-0.hdfs-namenode.hdfs.svc.cluster.local:9000
# PostgreSQL JDBC
spark.jars.packages              org.postgresql:postgresql:42.6.0
spark.driver.extraClassPath      /opt/spark/jars/postgresql-42.6.0.jar
spark.executor.extraClassPath    /opt/spark/jars/postgresql-42.6.0.jar
EOF

# Copy Hadoop core-site.xml template
RUN cat > $HADOOP_CONF_DIR/core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hdfs-namenode-0.hdfs-namenode.hdfs.svc.cluster.local:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/tmp/hadoop-\${user.name}</value>
    </property>
</configuration>
EOF

# Copy Hadoop hdfs-site.xml template
RUN cat > $HADOOP_CONF_DIR/hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.client.use.datanode.hostname</name>
        <value>true</value>
    </property>
</configuration>
EOF

# Download PostgreSQL JDBC driver
RUN wget --quiet -P $SPARK_HOME/jars/ \
    https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

# Set proper permissions
RUN chown -R $NB_USER:$NB_GID \
    $SPARK_HOME/conf \
    $HADOOP_CONF_DIR \
    $SPARK_HOME/jars

# Create workspace directory structure
RUN mkdir -p /home/jovyan/workspace && \
    mkdir -p /mnt/hdfs && \
    mkdir -p /mnt/nvme && \
    mkdir -p /mnt/hdd && \
    mkdir -p /mnt/gcs && \
    chown -R $NB_USER:$NB_GID /home/jovyan /mnt/hdfs /mnt/nvme /mnt/hdd /mnt/gcs

# Install commonly used visualization packages (lightweight)
RUN pip3 install --no-cache-dir \
    plotly>=5.17.0 \
    ipympl>=0.9.0

# Note: Heavy ML/DL packages (TensorFlow, PyTorch, etc.) should be installed 
# by users in their notebooks as needed using:
# !pip install --user <package-name>
# This keeps the base image lightweight and allows users to choose their versions.

# Create startup script for environment setup
RUN cat > /home/jovyan/.jupyter_startup.py <<'EOF'
import os
import sys

# Configure Spark environment
os.environ['SPARK_HOME'] = '/opt/spark'
os.environ['HADOOP_HOME'] = '/opt/hadoop'
os.environ['HADOOP_CONF_DIR'] = '/opt/hadoop/etc/hadoop'
os.environ['PYSPARK_PYTHON'] = '/usr/bin/python3'

# Add Spark to Python path
sys.path.insert(0, os.path.join(os.environ['SPARK_HOME'], 'python'))
sys.path.insert(0, os.path.join(os.environ['SPARK_HOME'], 'python', 'lib', 'py4j-0.10.9.7-src.zip'))

print("✓ Spark and Hadoop environment configured")
print(f"  SPARK_HOME: {os.environ['SPARK_HOME']}")
print(f"  HADOOP_HOME: {os.environ['HADOOP_HOME']}")
print(f"  HDFS NameNode: {os.environ.get('HDFS_NAMENODE_HOST', 'Not set')}")
print(f"  PostgreSQL: {os.environ.get('POSTGRES_HOST', 'Not set')}")
EOF

# Configure JupyterLab to run startup script
RUN mkdir -p /home/jovyan/.ipython/profile_default/startup && \
    ln -s /home/jovyan/.jupyter_startup.py /home/jovyan/.ipython/profile_default/startup/00-env-setup.py && \
    chown -R $NB_USER:$NB_GID /home/jovyan/.ipython /home/jovyan/.jupyter_startup.py

# Create start-notebook.sh script
RUN cat > /usr/local/bin/start-notebook.sh <<'EOF'
#!/bin/bash
set -e

# Allow jovyan to access GPU devices
if [ -e /dev/nvidia0 ]; then
    sudo chmod 666 /dev/nvidia* 2>/dev/null || true
    sudo chmod 666 /dev/nvidiactl 2>/dev/null || true
    sudo chmod 666 /dev/nvidia-uvm* 2>/dev/null || true
fi

# Start JupyterHub single-user server
exec jupyterhub-singleuser "$@"
EOF

RUN chmod +x /usr/local/bin/start-notebook.sh

# Set working directory
WORKDIR /home/jovyan

# Expose JupyterLab port
EXPOSE 8888

# Switch to user (jovyan has sudo NOPASSWD access)
USER $NB_USER

# Start JupyterLab
CMD ["start-notebook.sh"]
