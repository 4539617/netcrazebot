# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install Docker CLI and curl (needed for AWG management)
RUN apk add --no-cache docker-cli curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy application files
COPY src/ ./src/

# Create output directory
RUN mkdir -p /app/output

# Set environment variables
ENV NODE_ENV=production

# Run the bot
CMD ["node", "src/index.js"]

# Made with Bob
