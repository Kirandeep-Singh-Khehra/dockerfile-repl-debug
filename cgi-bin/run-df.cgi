#!/bin/bash

echo "Access-Control-Allow-Origin: *"
echo "Content-Type: application/json"
echo ""

cat > Dockerfile.tmp.repl

COMMAND_TO_RUN="busybox vi Dockerfile.tmp.repl"

BASE_PORT=16998
INCREMENT=1

PORT=$BASE_PORT

IS_FREE=$(busybox netstat -taln | grep $PORT)

while [[ -n "$IS_FREE" ]]; do
    PORT=$[PORT+INCREMENT]
    IS_FREE=$(busybox netstat -taln | grep $PORT)
done

HOST=$(ip route get 1.2.3.4 | awk '{print $7}')

echo "{ \"host\": \"${HOST}\", \"port\": \"${PORT}\"}"

# ttyd --writable --once --port ${PORT} /bin/bash -c "${COMMAND_TO_RUN}" > /dev/null 2>&1 &
ttyd --writable --once --port ${PORT} ${COMMAND_TO_RUN} > /dev/null 2>&1 &

