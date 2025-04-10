FROM python:3.11.11-slim-bullseye AS builder

# Set environment variables for builder stage
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

RUN python -mvenv venv && ./venv/bin/pip install --no-cache-dir --upgrade pip

COPY . .

# Create a dummy install_models.py script that always succeeds
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at build time")\n    print("Models will be pre-downloaded in the Dockerfile")\n    sys.exit(0)' > scripts/install_models.py && \
    chmod +x scripts/install_models.py

# Install package from source code, compile translations
RUN ./venv/bin/pip install Babel==2.12.1 && ./venv/bin/python scripts/compile_locales.py \
  && ./venv/bin/pip install torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu \
  && ./venv/bin/pip install "numpy<2" \
  && ./venv/bin/pip install -e . \
  && ./venv/bin/pip cache purge

FROM python:3.11.11-slim-bullseye

# Set environment variables for runtime
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true
ENV PORT=5000

# Create user and directories first (as root)
RUN addgroup --system --gid 1032 libretranslate && \
    adduser --system --uid 1032 libretranslate && \
    mkdir -p /home/libretranslate/.local/share/argos-translate/packages && \
    chown -R libretranslate:libretranslate /home/libretranslate/.local

# Copy application files from builder
COPY --from=builder --chown=1032:1032 /app /app
WORKDIR /app

# Copy ltmanage to /usr/bin
COPY --from=builder --chown=1032:1032 /app/venv/bin/ltmanage /usr/bin/

# Use entrypoint script to handle port configuration (IMPORTANT: copy and set permissions as root)
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    chown libretranslate:libretranslate /app/entrypoint.sh

# Create a dummy install_models.py script in the second stage as well (as root)
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at runtime")\n    sys.exit(0)' > /app/scripts/install_models.py && \
    chmod +x /app/scripts/install_models.py && \
    chown libretranslate:libretranslate /app/scripts/install_models.py

# Switch to non-root user AFTER permissions are set
USER libretranslate

EXPOSE $PORT

ENTRYPOINT ["/app/entrypoint.sh"]
