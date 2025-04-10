FROM python:3.11.11-slim-bullseye

# Set environment variables to disable CUDA
ENV CUDA_VISIBLE_DEVICES=""
ENV NO_CUDA=1
ENV FORCE_CPU=1
ENV LT_SKIP_INSTALL_MODELS=true

WORKDIR /app

# Install system dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get -qqq install --no-install-recommends -y pkg-config gcc g++ \
  && apt-get upgrade --assume-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt

# Set up user
RUN addgroup --system --gid 1032 libretranslate && \
    adduser --system --uid 1032 libretranslate && \
    mkdir -p /home/libretranslate/.local/share/argos-translate/packages && \
    chown -R libretranslate:libretranslate /home/libretranslate/.local

# Copy application files
COPY --chown=libretranslate:libretranslate . .

# Create and activate virtual environment
RUN python -m venv venv && \
    venv/bin/pip install --no-cache-dir --upgrade pip

# Install libretranslate and its dependencies with CPU-only pytorch
RUN venv/bin/pip install --no-cache-dir Babel==2.12.1 && \
    venv/bin/python scripts/compile_locales.py && \
    venv/bin/pip install --no-cache-dir torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu && \
    venv/bin/pip install --no-cache-dir "numpy<2" && \
    venv/bin/pip install --no-cache-dir -e . && \
    venv/bin/pip cache purge

# Set permission for entrypoint
COPY --chown=libretranslate:libretranslate entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Switch to non-root user
USER libretranslate

# Expose port and set environment variables
ENV PORT=5000
EXPOSE $PORT

# Use entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
