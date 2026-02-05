FROM mcr.microsoft.com/playwright:v1.50.0-noble

# Install MCPO (Python-based)
RUN pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

# MCPO runs and launches Playwright MCP via npx
CMD ["sh","-lc","mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@latest"]
