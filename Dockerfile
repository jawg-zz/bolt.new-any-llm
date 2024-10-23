# Use Node.js as the base image
ARG NODE_VERSION
FROM node:${NODE_VERSION}-slim

# Install pnpm
ARG PNPM_VERSION
RUN npm install -g pnpm@${PNPM_VERSION}

# Set working directory
WORKDIR /app/bolt

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install

# Copy the rest of the application
COPY . .

# Expose Vite dev server port
EXPOSE 5173

# Start development server
CMD ["pnpm", "dev", "--host"]