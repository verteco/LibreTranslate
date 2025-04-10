FROM python:3.11.11-slim-bullseye AS builder

WORKDIR /app

# Set environment variables to disable CUDA
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

RUN python -mvenv venv && ./venv/bin/pip install --no-cache-dir --upgrade pip

COPY . .

# Modify pyproject.toml to ensure CPU-only PyTorch
RUN sed -i 's/torch ==2.2.0/torch==2.0.1+cpu/g' pyproject.toml

# Pin PyTorch to explicitly use CPU version
RUN ./venv/bin/pip install Babel==2.12.1 && ./venv/bin/python scripts/compile_locales.py \
  && ./venv/bin/pip install --no-cache-dir torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu \
  && ./venv/bin/pip install --no-cache-dir "numpy<2" \
  && ./venv/bin/pip install --no-cache-dir -e . \
  && ./venv/bin/pip cache purge

FROM python:3.11.11-slim-bullseye

# Set environment variables to disable CUDA
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1

RUN addgroup --system --gid 1032 libretranslate && adduser --system --uid 1032 libretranslate && mkdir -p /home/libretranslate/.local && chown -R libretranslate:libretranslate /home/libretranslate/.local
USER libretranslate

COPY --from=builder --chown=1032:1032 /app /app
WORKDIR /app

COPY --from=builder --chown=1032:1032 /app/venv/bin/ltmanage /usr/bin/

# This line initializes language models, we'll rely on the default English models only
RUN ./venv/bin/python scripts/install_models.py --load_only_lang_codes en

# Default port is 5000, but will be overridden by the PORT env var in DigitalOcean
ENV PORT=5000
EXPOSE $PORT

# Use entrypoint script to handle port configuration
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
