# Jupyter Lab with JAX GPU Support

NVIDIA CUDA 12.3 + cuDNN 9 기반 Jupyter Lab 이미지로, JAX GPU 가속을 지원합니다.

## 포함된 패키지

### 기본 환경
- Ubuntu 22.04
- CUDA 12.3.0
- cuDNN 9
- Python 3.10

### Jupyter 스택
- JupyterLab 4.0.9
- JupyterHub 4.0.2
- IPython Kernel

### JAX 생태계
- JAX (CUDA 12 support)
- Flax (Neural network library)
- Optax (Optimization library)
- dm-haiku (Deep learning library)
- Chex (Testing utilities)

### 데이터 과학
- NumPy
- Pandas
- SciPy
- Scikit-learn
- Matplotlib
- Seaborn
- Plotly

### 데이터 연동
- PySpark 3.5.0
- PostgreSQL (psycopg2)
- HDFS client
- PyArrow
- Google Cloud Storage

## 빌드 방법

```bash
# 로컬 빌드
docker build -t your-registry/jupyter-jax-gpu:latest .

# 특정 사용자로 빌드
docker build \
  --build-arg NB_USER=jovyan \
  --build-arg NB_UID=1000 \
  -t your-registry/jupyter-jax-gpu:latest .
```

## GitHub Container Registry에 푸시

```bash
# GitHub Container Registry 로그인
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 태그
docker tag your-registry/jupyter-jax-gpu:latest ghcr.io/mireu-lab/jupyter-jax-gpu:latest

# 푸시
docker push ghcr.io/mireu-lab/jupyter-jax-gpu:latest
```

## 로컬 테스트

```bash
# GPU 포함 실행
docker run --gpus all -p 8888:8888 \
  -v $(pwd)/work:/home/jovyan/work \
  your-registry/jupyter-jax-gpu:latest

# 브라우저에서 http://localhost:8888 접속
```

## GPU 확인

컨테이너 내에서:

```python
import jax
print(f"JAX devices: {jax.devices()}")
print(f"JAX backend: {jax.default_backend()}")

# GPU 연산 테스트
import jax.numpy as jnp
x = jnp.ones((1000, 1000))
y = jnp.dot(x, x)
print(f"Result device: {y.device()}")
```

## 사용 예제

### JAX 기본 사용

```python
import jax
import jax.numpy as jnp
from jax import grad, jit, vmap

# 함수 정의
def sum_logistic(x):
    return jnp.sum(1.0 / (1.0 + jnp.exp(-x)))

# Gradient 계산
x_small = jnp.arange(3.0)
derivative_fn = grad(sum_logistic)
print(derivative_fn(x_small))

# JIT 컴파일
sum_logistic_jit = jit(sum_logistic)
%timeit sum_logistic_jit(x_small).block_until_ready()
```

### Flax Neural Network

```python
import flax.linen as nn
import jax
import jax.numpy as jnp

# 모델 정의
class SimpleMLP(nn.Module):
    features: int

    @nn.compact
    def __call__(self, x):
        x = nn.Dense(128)(x)
        x = nn.relu(x)
        x = nn.Dense(self.features)(x)
        return x

# 모델 초기화
model = SimpleMLP(features=10)
params = model.init(jax.random.PRNGKey(0), jnp.ones((1, 784)))

# Forward pass
x = jax.random.normal(jax.random.PRNGKey(1), (32, 784))
y = model.apply(params, x)
print(y.shape)
```

### Spark 연동

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("JAX-Spark") \
    .master("spark://spark-master-svc.datascience.svc.cluster.local:7077") \
    .getOrCreate()

# Spark로 데이터 로드
df = spark.read.parquet("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/data")

# Pandas로 변환하여 JAX에서 사용
pdf = df.toPandas()
data = jnp.array(pdf.values)

# JAX로 연산
result = jnp.mean(data, axis=0)
```

## 커스터마이징

### 추가 패키지 설치

Dockerfile에 추가:

```dockerfile
RUN pip install --no-cache-dir \
    your-package==version
```

### 환경 변수

```dockerfile
ENV YOUR_VAR=value
```

## 문제 해결

### GPU 인식 안 됨

```bash
# 호스트에서 NVIDIA 드라이버 확인
nvidia-smi

# 컨테이너 내에서 CUDA 확인
python -c "import jax; print(jax.devices())"
```

### 메모리 부족

JAX GPU 메모리 사전 할당 비활성화:

```python
import os
os.environ['XLA_PYTHON_CLIENT_PREALLOCATE'] = 'false'
```

### 패키지 충돌

가상 환경 사용:

```bash
python -m venv /home/jovyan/venv
source /home/jovyan/venv/bin/activate
pip install your-package
```

## 버전 관리

태그 전략:
- `latest`: 최신 안정 버전
- `v1.0.0`: 특정 버전
- `dev`: 개발 버전

```bash
docker tag your-registry/jupyter-jax-gpu:latest your-registry/jupyter-jax-gpu:v1.0.0
docker push your-registry/jupyter-jax-gpu:v1.0.0
```

## CI/CD

GitHub Actions 예시 (`.github/workflows/docker-build.yml`):

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    paths:
      - 'docker/jupyter-jax-gpu/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./docker/jupyter-jax-gpu
          push: true
          tags: |
            ghcr.io/mireu-lab/jupyter-jax-gpu:latest
            ghcr.io/mireu-lab/jupyter-jax-gpu:${{ github.sha }}
```

## 라이선스

이 이미지는 다음 소프트웨어를 포함합니다:
- NVIDIA CUDA: [NVIDIA EULA](https://docs.nvidia.com/cuda/eula/index.html)
- JAX: Apache 2.0
- JupyterLab: BSD License
