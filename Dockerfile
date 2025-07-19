# Multi-stage Dockerfile for TopList Application

# Stage 1: Build React Frontend
FROM node:18-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --only=production
COPY frontend/ ./
RUN npm run build

# Stage 2: Build Java Backend
FROM maven:3.9.0-openjdk-17-slim AS backend-build
WORKDIR /app
COPY pom.xml ./
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 3: Production Runtime
FROM openjdk:17-jdk-slim
WORKDIR /app

# Install nginx for serving frontend
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Copy built backend jar
COPY --from=backend-build /app/target/*.jar app.jar

# Copy built frontend
COPY --from=frontend-build /app/frontend/build /var/www/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create startup script
RUN echo '#!/bin/bash\n\
nginx &\n\
java -jar app.jar' > /app/start.sh && chmod +x /app/start.sh

# Expose ports
EXPOSE 80 8080

# Start both services
CMD ["/app/start.sh"]
