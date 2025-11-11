FROM nvcr.io/nvidia/cuda:12.3.0-cudnn9-runtime-ubuntu22.04

LABEL maintainer="Mireu Lab <admin@mireu.xyz>"
LABEL description="Jupyter Lab with JAX GPU support for ML/DL/RL"

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    JUPYTER_ENABLE_LAB=yes \
    GRANT_SUDO=yes

# 기본 패키지 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    curl \
    wget \
    vim \
    sudo \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Python 심볼릭 링크
RUN ln -s /usr/bin/python3 /usr/bin/python

# pip 업그레이드
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# JupyterLab 및 기본 패키지
RUN pip install --no-cache-dir \
    jupyterlab==4.0.9 \
    jupyterhub==4.0.2 \
    notebook==7.0.6 \
    ipywidgets==8.1.1 \
    ipykernel==6.27.1

# JAX with CUDA support
RUN pip install --no-cache-dir \
    "jax[cuda12_pip]" \
    -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

# 데이터 과학 라이브러리
RUN pip install --no-cache-dir \
    numpy==1.26.2 \
    pandas==2.1.4 \
    scipy==1.11.4 \
    scikit-learn==1.3.2 \
    matplotlib==3.8.2 \
    seaborn==0.13.0 \
    plotly==5.18.0 \
    bokeh==3.3.2

# 딥러닝 라이브러리 (JAX 생태계)
RUN pip install --no-cache-dir \
    flax==0.7.5 \
    optax==0.1.7 \
    dm-haiku==0.0.10 \
    chex==0.1.84 \
    jaxlib \
    tensorflow-datasets==4.9.3

# Spark, PostgreSQL, HDFS 연동
RUN pip install --no-cache-dir \
    pyspark==3.5.0 \
    psycopg2-binary==2.9.9 \
    hdfs==2.7.3 \
    pyarrow==14.0.1 \
    findspark==2.0.1

# 추가 유틸리티
RUN pip install --no-cache-dir \
    tqdm==4.66.1 \
    requests==2.31.0 \
    black==23.12.1 \
    pylint==3.0.3 \
    pytest==7.4.3

# Google Cloud Storage 지원
RUN pip install --no-cache-dir \
    google-cloud-storage==2.14.0 \
    gcsfs==2023.12.2

# 사용자 생성 (JupyterHub 호환)
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

ENV USER=${NB_USER} \
    HOME=/home/${NB_USER}

RUN groupadd -g ${NB_GID} ${NB_USER} || true && \
    useradd -m -s /bin/bash -N -u ${NB_UID} -g ${NB_GID} ${NB_USER} && \
    echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${NB_USER} && \
    chmod 0440 /etc/sudoers.d/${NB_USER}

# 작업 디렉토리 생성
RUN mkdir -p ${HOME}/work && \
    chown -R ${NB_USER}:${NB_GID} ${HOME}

# CUDA 경로 설정
ENV PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# JAX 설정
ENV XLA_PYTHON_CLIENT_PREALLOCATE=false \
    XLA_PYTHON_CLIENT_ALLOCATOR=platform

WORKDIR ${HOME}
USER ${NB_USER}

# Jupyter 설정
RUN jupyter lab --generate-config && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> ${HOME}/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.port = 8888" >> ${HOME}/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> ${HOME}/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = False" >> ${HOME}/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.token = ''" >> ${HOME}/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> ${HOME}/.jupyter/jupyter_lab_config.py

# 포트 노출
EXPOSE 8888

# 시작 스크립트
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
