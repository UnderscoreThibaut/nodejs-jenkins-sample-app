# -----------------------------
# 1. Base image for building
# -----------------------------
FROM node:22-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files first for caching
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy the rest of the app
COPY . .

# -----------------------------
# 2. Runtime image
# -----------------------------
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy built node_modules and app files
COPY --from=build /app /app

# Expose app port (must match Jenkinsfile)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
