#!/usr/bin/env bash
PROTO_DIR='./chat-service'
OUT_DIR='./chat-service'\

echo "Adding comments on every proto..."
echo "See https://github.com/improbable-eng/grpc-web/issues/96#issuecomment-523448731 for detail"
for f in "${OUT_DIR}"/*.js
do
    echo '/* eslint-disable */' | cat - "${f}" > temp && mv temp "${f}"
done