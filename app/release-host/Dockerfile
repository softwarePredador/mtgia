FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public /usr/share/nginx/html

RUN test -f /usr/share/nginx/html/downloads/release.json \
    && test -f /usr/share/nginx/html/downloads/manaloom-android.apk \
    && chmod -R a+rX /usr/share/nginx/html/downloads

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
