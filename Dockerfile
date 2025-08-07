# Multi-stage build for production
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN npm ci
RUN cd backend && npm ci
RUN cd frontend && npm ci

# Copy source code
COPY . .

# Build applications
RUN cd backend && npm run build
RUN cd frontend && npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Copy built backend
COPY --from=builder /app/backend/dist ./backend/dist
COPY --from=builder /app/backend/package*.json ./backend/
COPY --from=builder /app/backend/node_modules ./backend/node_modules

# Copy built frontend
COPY --from=builder /app/frontend/dist ./frontend/dist

# Copy environment and config files
COPY --from=builder /app/backend/.env* ./backend/
COPY --from=builder /app/vercel.json ./

# Create data directory for SQLite database
RUN mkdir -p /app/backend/data

# Expose port
EXPOSE 4000

# Set environment
ENV NODE_ENV=production

# Start the application
CMD ["node", "backend/dist/index.js"] 