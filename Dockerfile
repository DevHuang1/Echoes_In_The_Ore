FROM barichello/godot-ci:4.7.2 AS web-export

WORKDIR /workspace
COPY . .

RUN mkdir -p /out \
    && godot --headless --path /workspace --export-release "Web" /out/index.html \
    && test -s /out/index.html \
    && test -s /out/index.js \
    && test -s /out/index.wasm \
    && test -s /out/index.pck

FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=web-export /out/ /srv/

EXPOSE 8080
