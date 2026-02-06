FROM mcr.microsoft.com/playwright:v1.58.1-noble

# Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Python venv for mcpo
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
 && /opt/venv/bin/pip install --no-cache-dir mcpo

WORKDIR /app

# Install Node deps needed for import-cookies.mjs (so `import 'playwright'` works)
RUN npm init -y \
 && npm install --omit=dev playwright

# Copy your bootstrapper (keep it in repo)
COPY import-cookies.mjs /app/import-cookies.mjs

EXPOSE 8000 6080

# IMPORTANT: use --headed (NOT --headless=false)
CMD ["sh","-lc", "\
  node /app/import-cookies.mjs || true; \
  exec /opt/venv/bin/mcpo --host 0.0.0.0 --port 8000 --api-key \"$MCPO_API_KEY\" -- \
    npx -y @playwright/mcp@0.0.63 --browser firefox --headed --user-data-dir /data/profile \
"]
