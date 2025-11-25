# How to add new secrets

## Prerequisites

1. Install kubeseal

```bash
brew install kubeseal
```

2. Get the public key from the cluster. (if you don't have it already)

```bash
kubeseal --fetch-cert > pub-sealed-secrets.pem
```



1. Create a new file from `secret.template.yaml` file with the new secrets.
```bash
cp secret.template.yaml secret.yaml
```

2. Add the new secrets to the `secret.yaml` file.

3. Run the `encrypt-secret.sh` script to encrypt the new secrets. This will create a new file with the new secrets in the `sealed-` prefix and **delete the original file.**

```bash
./encrypt-secret.sh secret.yaml
```

4. Run the `kubectl apply -f sealed-secret.yaml` command to apply the new secrets to the cluster.

```bash
kubectl apply -f secret.yaml
```