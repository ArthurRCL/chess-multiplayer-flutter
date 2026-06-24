# ── Stage 1: Build Flutter Web ──────────────────────────────────
FROM ubuntu:24.04 AS build

# Avoid interactive prompts during apt install
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies for Flutter Web build
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (version matching pubspec.lock requirements: >=3.38.4)
ENV FLUTTER_VERSION=3.44.3
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && flutter precache --web \
    && flutter doctor -v

# Limit Dart VM memory to avoid OOM on low-memory servers (1GB RAM + swap)
ENV DART_VM_OPTIONS="--old_gen_heap_size=512"

WORKDIR /app

# Copy dependency files first for better Docker cache
COPY pubspec.yaml pubspec.lock ./

# Create a minimal lib file so pub get can resolve (cache layer)
RUN mkdir -p lib && echo "void main() {}" > lib/main.dart

# Get dependencies (cached unless pubspec changes)
RUN flutter pub get

# Remove the dummy file
RUN rm lib/main.dart

# Copy source code and assets
COPY lib/ lib/
COPY web/ web/
COPY assets/ assets/
COPY analysis_options.yaml ./

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
