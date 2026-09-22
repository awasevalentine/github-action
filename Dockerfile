# syntax=docker/dockerfile:1

# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies using the lockfile for reproducible builds
COPY package.json package-lock.json ./
RUN npm ci

# Copy application source and build
COPY . .
RUN npm run build

# Remove development dependencies after the build
RUN npm prune --omit=dev


# Production stage
FROM node:22-alpine AS production

ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Run as the non-root user included in the Node Alpine image
USER node

# Copy only production dependencies and application output
COPY --chown=node:node --from=builder /app/package.json ./package.json
COPY --chown=node:node --from=builder /app/package-lock.json ./package-lock.json
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]