# Stage 1: Build stage
FROM golang:1.20-alpine AS build

# Set the working directory
WORKDIR /app

# Copy the source code
COPY . .

# Build the Go application
RUN go build -o main .

# Stage 2: Final stage
FROM alpine:edge

# Set the working directory
WORKDIR /app

# Copy the binary from the build stage
COPY --from=build /app .

# Expose port 8080
EXPOSE 8080

# Binary will be executed when the container starts
CMD ["./main"]