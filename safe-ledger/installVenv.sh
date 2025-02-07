VENV_PATH="$ROOT_DIR/safe-ledger/venv/bin/activate"

if [ ! -f "$VENV_PATH" ]; then
    echo "Virtual Environment nicht gefunden, erstelle es..."
    python3 -m venv "$ROOT_DIR/safe-ledger/venv"
    source "$VENV_PATH"
    pip install -r "$ROOT_DIR/safe-ledger/requirements.txt"
else
    source "$VENV_PATH"
fi