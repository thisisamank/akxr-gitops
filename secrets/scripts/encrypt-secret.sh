#!/bin/bash
# TODO: this script should also put the file it is encrypting into .gitignore


if ! command -v kubeseal &> /dev/null; then
    echo "Error: kubeseal could not be found." >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <input-file.yaml>" >&2
    exit 1
fi

INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found." >&2
    exit 1
fi

CERT_FILE="pub-sealed-secrets.pem"
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Sealed Secrets public key '$CERT_FILE' not found." >&2
    echo "You can fetch it from your cluster with: kubeseal --fetch-cert > $CERT_FILE" >&2
    exit 1
fi

# --- User Input ---
read -p "Enter the name for the Kubernetes Secret: " SECRET_NAME
if [ -z "$SECRET_NAME" ]; then
    echo "Error: Secret name cannot be empty." >&2
    exit 1
fi

read -p "Enter the namespace (defaults to 'default'): " SECRET_NAMESPACE
# Use 'default' if the user input is empty
SECRET_NAMESPACE=${SECRET_NAMESPACE:-default}

# --- Configuration ---
INPUT_BASENAME=$(basename "$INPUT_FILE")
# The output file is now named after the secret name provided by the user
OUTPUT_FILE="$(dirname "$INPUT_FILE")/sealed-${SECRET_NAME}.yaml"

SECRET_MANIFEST=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${SECRET_NAMESPACE}
type: Opaque
data:
EOF
)

while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    key=$(echo "$line" | cut -d ':' -f 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
    value=$(echo "$line" | cut -d ':' -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')

    if [ -z "$key" ]; then
        echo "Warning: Skipping malformed line: $line" >&2
        continue
    fi

    encoded_value=$(echo -n "$value" | base64)

    SECRET_MANIFEST="${SECRET_MANIFEST}\n  ${key}: ${encoded_value}"
done < "$INPUT_FILE"

echo "Sealing secret '${SECRET_NAME}' for namespace '${SECRET_NAMESPACE}'..."

echo -e "${SECRET_MANIFEST}" | kubeseal --format=yaml --cert="$CERT_FILE" > "$OUTPUT_FILE"

echo "✅ Successfully created sealed secret: $OUTPUT_FILE"
