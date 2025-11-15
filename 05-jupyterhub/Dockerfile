FROM jupyter/tensorflow-notebook:latest

USER root

# NVIDIA GPU 드라이버 설치
RUN apt-get update && apt-get install -y \
    nvidia-driver-535 \
    nvidia-cuda-toolkit \
    && rm -rf /var/lib/apt/lists/*

# JAX 설치 (NVIDIA GPU 지원)
RUN pip install --upgrade pip && \
    pip install --upgrade "jax[cuda12]" jaxlib

# Hadoop, Spark, PostgreSQL 클라이언트 설치
RUN pip install pyspark==3.5.0 \
    psycopg2-binary \
    hdfs \
    sqlalchemy \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    plotly \
    scikit-learn

# Hadoop 설정 디렉토리 생성
RUN mkdir -p /opt/hadoop/conf

# Git 설정
RUN apt-get update && apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

USER jovyan

WORKDIR /home/jovyan
