# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

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
