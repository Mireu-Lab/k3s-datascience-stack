FROM jupyter/base-notebook:python-3.11.15

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    build-essential curl git wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

USER $NB_UID
RUN pip install --no-cache-dir jupyterlab pyspark sqlalchemy psycopg2-binary google-cloud-storage

# JAX (GPU)는 CUDA 드라이버/라이브러리가 정확히 맞아야 동작합니다.
# 아래는 CPU fallback 또는 GPU 환경에서 별도 빌드가 필요한 경우 지침으로 남겨둡니다.
# GPU에서 JAX를 사용하려면 호스트에 적절한 NVIDIA 드라이버/CUDA와 컨테이너에서 호환되는 jax[cuda] 패키지를 설치하세요.

EXPOSE 8888
CMD ["start-notebook.sh"]
