FROM mcr.microsoft.com/playwright:v1.50.0-noble

# Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install MCPO into a venv (avoids PEP 668 issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
RUN npm -g install playwright
EXPOSE 8000

# We'll add this file to your repo next
# (Docker build will fail until import-cookies.mjs exists)
COPY import-cookies.mjs /app/import-cookies.mjs

CMD ["sh","-lc", "\
export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright; \
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1; \
node /app/import-cookies.mjs || true; \
/opt/venv/bin/mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@0.0.63 \
"]
