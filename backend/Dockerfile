# ---- Stage 1: Build ----
# This stage installs dependencies
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package.json ./
COPY package-lock.json ./

# Install all dependencies
RUN npm install

# Copy the rest of your application's source code
COPY . .

# ---- Stage 2: Production ----
# This stage creates the final, lean image
FROM node:18-alpine

# Set the environment to production
ENV NODE_ENV=production

WORKDIR /usr/src/app

# Copy the installed node_modules from the 'builder' stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy the application source code from the 'builder' stage
COPY --from=builder /usr/src/app .

# IMPORTANT: Download the Amazon DocumentDB CA certificate
# This is required for your Mongoose connection to work over TLS
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem .

# Your Terraform infrastructure expects the app on port 8080
EXPOSE 8080

# The command to start the server when the container starts
CMD [ "node", "server.js" ]