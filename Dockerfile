FROM python:3.12-slim

WORKDIR /app

# ripgrep for fallback grep, git for cloning the target project repo.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ripgrep git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Install Python deps first for better layer reuse.
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

# Copy only files needed at runtime to keep image small and pulls fast.
COPY dashboard /app/contextkit-dashboard/dashboard
COPY bin /app/contextkit-dashboard/bin

# Dashboard API runs internally on 8787; MCP SSE uses Railway's PORT.
ENV DG_BASE_URL=http://127.0.0.1:8787

RUN chmod +x /app/contextkit-dashboard/dashboard/start.sh

# Optional env vars (set in Railway dashboard):
#   GITHUB_REPO_URL    – repo to clone as the target project
#   GITHUB_TOKEN       – personal access token for private repos
#   DG_API_TOKEN       – bearer token to protect the dashboard API
#   DUAL_GRAPH_PROJECT_ROOT – overrides the default clone path (/app/project)

CMD ["/app/contextkit-dashboard/dashboard/start.sh"]
