FROM node:18

WORKDIR /app

# Install pnpm and Remix CLI globally
RUN npm install -g pnpm @remix-run/dev

# Only copy package files initially for better caching
COPY package.json pnpm-lock.yaml* ./
COPY vite.config.js ./

# Expose Vite's default port
EXPOSE 5173