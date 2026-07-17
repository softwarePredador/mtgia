FROM nginx:1.30.3-alpine@sha256:0d3b80406a13a767339fbe2f41406d6c7da727ab89cf8fae399e81f780f814d1

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public /usr/share/nginx/html

RUN test -f /usr/share/nginx/html/downloads/release.json \
    && test -f /usr/share/nginx/html/downloads/manaloom-android.apk \
    && chmod -R a+rX /usr/share/nginx/html/downloads

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
