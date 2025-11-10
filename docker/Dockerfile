ARG BASE_IMAGE=jupyter/base-notebook:python-3.11.6
ARG INSTALL_JAX=0
ARG JAX_CUDA_WHEEL_URL=""

FROM ${BASE_IMAGE}
LABEL maintainer="Mireu-Lab <limmireu1214@gmail.com>"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Root 단계: 시스템 종속성, Java, Hadoop client, JDBC 드라이버 등 설치
USER root
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
             openjdk-17-jre-headless build-essential curl git wget ca-certificates unzip \
             python3-dev libpq-dev pkg-config ca-certificates gnupg \
        && rm -rf /var/lib/apt/lists/*

# Hadoop client 설치 (HDFS에 접근하기 위한 최소 클라이언트)
ENV HADOOP_VERSION=3.3.5
RUN mkdir -p /opt && \
        curl -fsSL https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -o /tmp/hadoop.tar.gz && \
        tar xzf /tmp/hadoop.tar.gz -C /opt && \
        ln -s /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
        rm /tmp/hadoop.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV PATH="$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# PostgreSQL JDBC (Spark / Java 앱이 DB에 접속할 수 있도록)
ENV PGJDBC_VERSION=42.6.0
RUN mkdir -p /opt/jdbc && \
        curl -fsSL https://repo1.maven.org/maven2/org/postgresql/postgresql/${PGJDBC_VERSION}/postgresql-${PGJDBC_VERSION}.jar -o /opt/jdbc/postgresql.jar

# Switch back to notebook user for Python package installs (keeps files owned by NB user)
USER ${NB_UID}

# Python packages: JupyterLab, Spark/Python, DB 및 GCS 연동, nbgitpuller 등
RUN pip install --no-cache-dir \
        jupyterlab nbgitpuller jupyterlab-git jupyterlab_widgets ipywidgets \
        pyspark sqlalchemy psycopg2-binary google-cloud-storage google-auth

# Optional JAX installation: set --build-arg INSTALL_JAX=1 to enable.
# For GPU-enabled JAX you should build with a CUDA-compatible base image and pass
# the pre-built wheel URL via --build-arg JAX_CUDA_WHEEL_URL=<wheel_url>
USER root
RUN if [ "${INSTALL_JAX}" = "1" ]; then \
            if [ -n "${JAX_CUDA_WHEEL_URL}" ]; then \
                echo "Installing JAX GPU wheel from ${JAX_CUDA_WHEEL_URL}" && \
                pip install --no-cache-dir "${JAX_CUDA_WHEEL_URL}" || (echo "JAX GPU wheel install failed"; exit 1); \
            else \
                echo "Installing JAX (CPU)" && pip install --no-cache-dir "jax[cpu]" || (echo "JAX CPU install failed"; exit 1); \
            fi; \
        else \
            echo "Skipping JAX install (use --build-arg INSTALL_JAX=1 to enable)"; \
        fi

# Ensure NB user owns home/work directories
USER ${NB_UID}

EXPOSE 8888
ENV JUPYTER_ENABLE_LAB=1
# Ensure the notebook starts in Lab by default
CMD ["start-notebook.sh", "--NotebookApp.default_url=/lab"]
