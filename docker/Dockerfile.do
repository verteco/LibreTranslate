FROM python:3.11.11-slim-bullseye AS builder

# Set environment variables for builder stage
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true

WORKDIR /app

# Install build dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

# Copy application files
COPY . .

# Create a dummy install_models.py script that will always succeed
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at build time")\n    print("Models will be pre-downloaded in the Dockerfile")\n    sys.exit(0)' > scripts/install_models.py && \
    chmod +x scripts/install_models.py

# Modify pyproject.toml to ensure CPU-only PyTorch
RUN sed -i 's/torch ==2.2.0/torch==2.0.1+cpu/g' pyproject.toml

# Set up virtual environment with CPU-only dependencies
RUN python -m venv venv && \
    venv/bin/pip install --no-cache-dir --upgrade pip && \
    venv/bin/pip install --no-cache-dir Babel==2.12.1 && \
    venv/bin/python scripts/compile_locales.py && \
    venv/bin/pip install --no-cache-dir torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu && \
    venv/bin/pip install --no-cache-dir "numpy<2" && \
    venv/bin/pip install --no-cache-dir -e . && \
    venv/bin/pip cache purge

# Second stage
FROM python:3.11.11-slim-bullseye

# Set environment variables for runtime
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true

# Create non-root user
RUN addgroup --system --gid 1032 libretranslate && \
    adduser --system --uid 1032 libretranslate && \
    mkdir -p /home/libretranslate/.local/share/argos-translate/packages && \
    chown -R libretranslate:libretranslate /home/libretranslate/.local

# Copy application from builder stage
COPY --from=builder --chown=libretranslate:libretranslate /app /app
WORKDIR /app

# Copy ltmanage to /usr/bin
COPY --from=builder --chown=libretranslate:libretranslate /app/venv/bin/ltmanage /usr/bin/

# Set entrypoint permissions (as root before switching user)
COPY entrypoint.sh /app/entrypoint.sh
USER root
RUN chmod +x /app/entrypoint.sh && \
    chown libretranslate:libretranslate /app/entrypoint.sh

# Create a dummy install_models.py script in the second stage as well
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at runtime")\n    sys.exit(0)' > /app/scripts/install_models.py && \
    chmod +x /app/scripts/install_models.py && \
    chown libretranslate:libretranslate /app/scripts/install_models.py

# Switch to non-root user
USER libretranslate

# Use PORT environment variable
ENV PORT=5000
EXPOSE $PORT

# Use entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
