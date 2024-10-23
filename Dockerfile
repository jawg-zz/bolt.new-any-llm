# syntax=docker/dockerfile:1.4
FROM --platform=$BUILDPLATFORM node:20.15.1-alpine as builder

# Arguments for multi-arch build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Install system dependencies and pnpm in one layer
RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++ \
    git && \
    npm install -g pnpm@9.4.0

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Create platform-specific package extensions
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    echo '{"@cloudflare/workerd-linux-arm64@*":{"dependencies":{"@cloudflare/workerd-linux-64":"*"}}}' > .pnpmfile.cjs; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    echo '{"@cloudflare/workerd-linux-64@*":{"dependencies":{"@cloudflare/workerd-linux-64":"*"}}}' > .pnpmfile.cjs; \
    fi

# Install dependencies with platform-specific configurations
RUN --mount=type=cache,target=/root/.pnpm-store \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    PNPM_PACKAGE_EXTENSIONS='{"@cloudflare/workerd-linux-arm64@*":{"dependencies":{"@cloudflare/workerd-linux-64":"*"}}}' pnpm install --frozen-lockfile; \
    else \
    pnpm install --frozen-lockfile; \
    fi

# Copy source files
COPY . .

# Build application
RUN pnpm run build

# Production stage
FROM --platform=$TARGETPLATFORM node:20.15.1-alpine as runner

# Install production essentials
RUN apk add --no-cache libc6-compat && \
    npm install -g pnpm@9.4.0 && \
    addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 remixjs

WORKDIR /app

# Copy production files
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/.pnpmfile.cjs ./
COPY --from=builder /app/build ./build
COPY --from=builder /app/public ./public

# Install production dependencies
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --prod && \
    chown -R remixjs:nodejs /app

USER remixjs

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    SHELL=/bin/sh

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000 || exit 1

CMD ["pnpm", "start"]