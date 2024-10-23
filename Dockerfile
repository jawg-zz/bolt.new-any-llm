FROM node:18

WORKDIR /app

# Install pnpm and Remix CLI globally
RUN npm install -g pnpm @remix-run/dev
# Expose Vite's default port
EXPOSE 5173

# Set host for Vite
ENV VITE_HOST=0.0.0.0