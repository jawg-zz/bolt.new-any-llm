FROM node:20.15.1-alpine as builder

# Install system dependencies and pnpm in one layer
RUN apk add --no-cache libc6-compat && \
    npm install -g pnpm@9.4.0

WORKDIR /app

# Install dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --production=false

# Build application
COPY . .
RUN pnpm run build

# Production stage
FROM node:20.15.1-alpine as runner

# Install production essentials in one layer
RUN apk add --no-cache libc6-compat && \
    npm install -g pnpm@9.4.0 && \
    addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 remixjs

WORKDIR /app

# Copy only necessary files
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/build ./build
COPY --from=builder /app/public ./public

# Install production dependencies and set permissions in one layer
RUN pnpm install --frozen-lockfile --production=true && \
    chown -R remixjs:nodejs /app

USER remixjs

# Set default environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    SHELL=/bin/sh

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000 || exit 1

CMD ["pnpm", "start"]