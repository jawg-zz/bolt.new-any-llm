FROM node:18

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Install Remix CLI globally
RUN npm install -g @remix-run/dev

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install

# Copy the rest of the application code
COPY . .

# Build the application
RUN pnpm run build || true

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["pnpm", "run", "dev"]