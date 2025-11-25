#!/bin/bash

# Script to apply sealed secrets to the Kubernetes cluster
# Usage: ./apply-secret.sh <sealed-secret-file.yaml>

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl could not be found." >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <sealed-secret-file.yaml>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 sealed-mysecret.yaml" >&2
    echo "  $0 mysealedsecret.json" >&2
    echo "" >&2
    echo "Available sealed secret files:" >&2
    ls -1 sealed-*.yaml sealed-*.json 2>/dev/null | sed 's/^/  /' >&2
    exit 1
fi

SECRET_FILE="$1"

# Check if file exists
if [ ! -f "$SECRET_FILE" ]; then
    echo "Error: Sealed secret file '$SECRET_FILE' not found." >&2
    echo "" >&2
    echo "Available sealed secret files:" >&2
    ls -1 sealed-*.yaml sealed-*.json 2>/dev/null | sed 's/^/  /' >&2
    exit 1
fi

# Validate that it's a sealed secret file
if ! grep -q "kind.*SealedSecret" "$SECRET_FILE"; then
    echo "Error: '$SECRET_FILE' does not appear to be a SealedSecret file." >&2
    echo "The file should contain 'kind: SealedSecret' or 'kind\": \"SealedSecret\"'" >&2
    exit 1
fi

# Extract secret name and namespace for confirmation
if [[ "$SECRET_FILE" == *.json ]]; then
    SECRET_NAME=$(grep -o '"name": *"[^"]*"' "$SECRET_FILE" | head -1 | sed 's/"name": *"\([^"]*\)"/\1/')
    SECRET_NAMESPACE=$(grep -o '"namespace": *"[^"]*"' "$SECRET_FILE" | head -1 | sed 's/"namespace": *"\([^"]*\)"/\1/')
else
    SECRET_NAME=$(grep -A 10 "metadata:" "$SECRET_FILE" | grep "name:" | head -1 | awk '{print $2}')
    SECRET_NAMESPACE=$(grep -A 10 "metadata:" "$SECRET_FILE" | grep "namespace:" | head -1 | awk '{print $2}')
fi

# Default to 'default' namespace if not specified
SECRET_NAMESPACE=${SECRET_NAMESPACE:-default}

echo "📋 Sealed Secret Details:"
echo "  File: $SECRET_FILE"
echo "  Name: $SECRET_NAME"
echo "  Namespace: $SECRET_NAMESPACE"
echo ""

# Confirm before applying
read -p "Do you want to apply this sealed secret to the cluster? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

echo "🚀 Applying sealed secret '$SECRET_NAME' to namespace '$SECRET_NAMESPACE'..."

# Apply the sealed secret
if kubectl apply -f "$SECRET_FILE"; then
    echo ""
    echo "✅ Successfully applied sealed secret '$SECRET_NAME' to namespace '$SECRET_NAMESPACE'"
    echo ""
    echo "🔍 You can verify the secret was created with:"
    echo "  kubectl get secret $SECRET_NAME -n $SECRET_NAMESPACE"
    echo ""
    echo "📖 To view the secret details:"
    echo "  kubectl describe secret $SECRET_NAME -n $SECRET_NAMESPACE"
else
    echo ""
    echo "❌ Failed to apply sealed secret '$SECRET_NAME'"
    echo "Please check the error message above and try again."
    exit 1
fi
