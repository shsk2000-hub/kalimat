# Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.44.4 AS flutter-build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY lib ./lib
COPY assets ./assets
COPY web ./web
COPY analysis_options.yaml ./
RUN flutter pub get
RUN flutter build web --release

# Run Node server + static web app
FROM node:20-alpine
WORKDIR /app
COPY server/package.json server/package-lock.json* ./
RUN npm install --omit=dev
COPY server/index.js ./
COPY --from=flutter-build /app/build/web ./public
ENV PORT=3000
EXPOSE 3000
CMD ["node", "index.js"]
