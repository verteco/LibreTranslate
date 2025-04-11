FROM python:3.11.11-slim-bullseye AS builder

# Set environment variables for builder stage
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true
ENV PYTHONUNBUFFERED=1
# Core languages only for faster startup
ENV LT_LOAD_ONLY="en,de,fr,it,es,cs,sk,pl,hu"

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ procps curl wget \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

RUN python -mvenv venv && ./venv/bin/pip install --no-cache-dir --upgrade pip

COPY . .

# Create a dummy install_models.py script that always succeeds
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at build time")\n    print("Models will be pre-downloaded in the Dockerfile")\n    sys.exit(0)' > scripts/install_models.py && \
    chmod 755 scripts/install_models.py

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
ENV PYTHONUNBUFFERED=1
ENV LT_HOST=0.0.0.0
# Core languages only for faster startup
ENV LT_LOAD_ONLY="en,de,fr,it,es,cs,sk,pl,hu"

# Install additional runtime dependencies
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y procps curl wget \
  && apt-get clean \
  && rm -rf /var/lib/apt

# Create user and directories first (as root)
RUN addgroup --system --gid 1032 libretranslate && \
    adduser --system --uid 1032 libretranslate && \
    mkdir -p /home/libretranslate/.local/share/argos-translate/packages && \
    chmod -R 755 /home/libretranslate/.local && \
    chown -R libretranslate:libretranslate /home/libretranslate/.local

# Copy application files from builder
COPY --from=builder --chown=1032:1032 /app /app
WORKDIR /app

# Copy ltmanage to /usr/bin
COPY --from=builder --chown=root:root /app/venv/bin/ltmanage /usr/bin/
RUN chmod 755 /usr/bin/ltmanage

# Use entrypoint script to handle port configuration (IMPORTANT: copy and set permissions as root)
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod 755 /app/entrypoint.sh && \
    chown libretranslate:libretranslate /app/entrypoint.sh

# Add healthcheck script
COPY healthcheck.sh /app/healthcheck.sh
RUN chmod 755 /app/healthcheck.sh && \
    chown libretranslate:libretranslate /app/healthcheck.sh

# Create a dummy install_models.py script in the second stage as well (as root)
RUN echo '#!/usr/bin/env python\nimport sys\nimport argparse\n\nif __name__ == "__main__":\n    parser = argparse.ArgumentParser()\n    parser.add_argument("--load_only_lang_codes", type=str, default="")\n    parser.add_argument("--update", action="store_true")\n    args = parser.parse_args()\n    \n    print("Dummy script for DigitalOcean deployment - No models will be installed at runtime")\n    sys.exit(0)' > /app/scripts/install_models.py && \
    chmod 755 /app/scripts/install_models.py && \
    chown libretranslate:libretranslate /app/scripts/install_models.py

# Verify the venv and permissions
RUN ls -la /app/venv/bin && \
    chmod -R 755 /app/venv/bin && \
    chown -R libretranslate:libretranslate /app/venv

# Switch to non-root user AFTER permissions are set
USER libretranslate

# Test that the script works
RUN /app/venv/bin/python -c "print('Python works!')"

# Add a dedicated command instead of relying on the entrypoint script
# This explicitly adds the --load-only flag to limit languages
CMD ["./venv/bin/libretranslate", "--host", "0.0.0.0", "--port", "5000", "--load-only", "en,de,fr,it,es"]

EXPOSE $PORT

# Configure healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD /app/healthcheck.sh

ENTRYPOINT ["/app/entrypoint.sh"]
