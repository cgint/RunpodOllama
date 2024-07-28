#!/bin/bash

cleanup() {
    echo "Cleaning up..."
    pkill -P $$ # Kill all child processes of the current script
    exit 0
}

# Trap exit signals and call the cleanup function
trap cleanup SIGINT SIGTERM

# Kill any existing ollama processes
pgrep ollama | xargs kill

# Start the ollama server and log its output
# Create /workspace directory if it doesn't exist
OLLAMA_HOME=${OLLAMA_HOME:-/runpod-volume/.ollama}
OLLAMA_MODELS="$OLLAMA_HOME/models"
export OLLAMA_HOME
export OLLAMA_MODELS
MODEL_NAME=${MODEL_NAME:-llama3.1}
export MODEL_NAME
echo "OLLAMA_HOME is set to $OLLAMA_HOME"
echo "MODEL_NAME is set to $MODEL_NAME"
if [ ! -d "$OLLAMA_HOME" ]; then
    mkdir -p "$OLLAMA_HOME"
    echo "Created OLLAMA_HOME directory: $OLLAMA_HOME"
fi

ollama serve 2>&1 | tee ollama.server.log &
OLLAMA_PID=$! # Store the process ID (PID) of the background command

check_server_is_running() {
    echo "Checking if server is running..."
    if cat ollama.server.log | grep -q "Listening"; then
        return 0 # Success
    else
        return 1 # Failure
    fi
}

# Wait for the server to start
while ! check_server_is_running; do
    sleep 5
done

time ollama list | grep $MODEL_NAME || time ollama pull $MODEL_NAME

echo "About to start serving ..."
uptime

python -u runpod_wrapper.py $MODEL_NAME
