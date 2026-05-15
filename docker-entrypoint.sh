#!/bin/bash

source /opt/emsdk/emsdk_env.sh

export SRC_DIR="/lupinho/src"
export CODEC_DIR="/lupinho/lupi-codec"
export CODEC_OUTPUT="/lupinho/lupi-codec/output"
export ENGINE_SRC="/lupinho/lupinho/src"
export DIST_DIR="/lupinho/dist"

build() {
    set -e
    echo "[lupi] Encoding src..."
    rm -rf "$CODEC_OUTPUT"
    rm -rf /tmp/lupi-src && cp -r "$SRC_DIR" /tmp/lupi-src
    cd "$CODEC_DIR" && lua run.lua /tmp/lupi-src "$CODEC_OUTPUT" || { echo "[lupi] Codec failed"; exit 1; }

    LATEST=$(ls -t "$CODEC_OUTPUT/releases/" 2>/dev/null | head -1)
    [ -z "$LATEST" ] && { echo "[lupi] No release found"; exit 1; }

    echo "[lupi] Zipping release $LATEST..."
    cd "$CODEC_OUTPUT/releases/$LATEST"
    rm -f /tmp/jogo.lupi
    zip -r /tmp/jogo.lupi .

    echo "[lupi] Building webgame..."
    cd "$ENGINE_SRC" && make web-game GAME_PATH=/tmp/jogo.lupi

    echo "[lupi] Copying to dist..."
    mkdir -p "$DIST_DIR/webgame"
    cp -r "$ENGINE_SRC/../dist/webgame/." "$DIST_DIR/webgame/"
    echo "[lupi] Done! Recarregue o browser para ver as alteracoes."
}
export -f build

kill_build() {
    if [ -f /tmp/lupi-build.pid ]; then
        local pid
        pid=$(cat /tmp/lupi-build.pid)
        if kill -0 "$pid" 2>/dev/null; then
            echo "[lupi] Canceling build (PID $pid)..."
            kill -TERM -- -"$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
        rm -f /tmp/lupi-build.pid
    fi
}

start_build() {
    kill_build
    setsid bash -c 'source /opt/emsdk/emsdk_env.sh; build' &
    echo $! > /tmp/lupi-build.pid
}

mkdir -p "$DIST_DIR"
python3 -m http.server 3000 --directory "$DIST_DIR" > /dev/null 2>&1 &

start_build

while inotifywait -r -e modify,create,delete,move "$SRC_DIR" 2>/dev/null; do
    echo "[lupi] Change detected, rebuilding..."
    start_build
done
