# ── Stage 1: Build Flutter Web ──────────────────────────────────
FROM instrumentisto/flutter:3.22.0 AS build

WORKDIR /app

# Copy dependency files first for better Docker cache
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build Flutter Web release
ARG API_BASE_URL=http://136.248.113.214:8080
ARG WS_BASE_URL=http://136.248.113.214:8080/ws
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=WS_BASE_URL=${WS_BASE_URL}

# ── Stage 2: Serve with Nginx ──────────────────────────────────
FROM nginx:alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Nginx config for SPA (single-page application) routing
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
