FROM python:3.11.11-slim-bullseye

# Set environment variables
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true

WORKDIR /app

# Install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

# Create user
RUN addgroup --system --gid 1032 libretranslate && \
    adduser --system --uid 1032 libretranslate && \
    mkdir -p /home/libretranslate/.local/share/argos-translate/packages && \
    chown -R libretranslate:libretranslate /home/libretranslate/.local

# Copy application files (with special handling for scripts directory)
COPY libretranslate /app/libretranslate
COPY *.py pyproject.toml babel.cfg VERSION /app/

# Create and set up scripts directory - IMPORTANT: We'll use our dummy install_models.py
RUN mkdir -p /app/scripts
COPY scripts/install_models.py /app/scripts/

# Copy entrypoint script and make it executable (MUST do this before switching users)
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    chown -R libretranslate:libretranslate /app/

# Set up virtual environment
RUN python -m venv venv && \
    venv/bin/pip install --no-cache-dir --upgrade pip && \
    venv/bin/pip install --no-cache-dir Babel==2.12.1 && \
    venv/bin/pip install --no-cache-dir torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu && \
    venv/bin/pip install --no-cache-dir "numpy<2" && \
    venv/bin/pip install --no-cache-dir -e . && \
    venv/bin/pip cache purge && \
    chown -R libretranslate:libretranslate /app/venv

# Switch to non-root user
USER libretranslate

# Expose port and set environment variables
ENV PORT=5000
EXPOSE $PORT

# Use entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
