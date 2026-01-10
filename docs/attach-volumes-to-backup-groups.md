# How to Attach Volumes to Backup Groups

In Longhorn, volumes are attached to recurring job groups via labels. This document explains how to attach your volumes to the daily backup group, **excluding Immich volumes** to reduce backup storage costs.

## Important: Immich Exclusion

**Immich volumes are NOT backed up** due to storage costs (Immich library volume is 512Gi+). All other volumes are backed up daily.

## Understanding Groups

Recurring jobs define groups (e.g., `critical`, `core`, `media`). Volumes are attached to these groups by adding a label:
```
recurring-job-group.longhorn.io/<group-name>: "enabled"
```

## Method 1: Via kubectl (Recommended for GitOps)

### Attach a Single Volume to a Group

```bash
kubectl label volume.longhorn.io <volume-name> \
  -n longhorn-system \
  recurring-job-group.longhorn.io/critical=enabled
```

### Attach Multiple Volumes to a Group

```bash
# Get all PostgreSQL volumes (example)
kubectl get volumes.longhorn.io -n longhorn-system \
  -l longhornvolume \
  -o name | \
  xargs -I {} kubectl label {} \
    -n longhorn-system \
    recurring-job-group.longhorn.io/critical=enabled
```

### Remove a Volume from a Group

```bash
kubectl label volume.longhorn.io <volume-name> \
  -n longhorn-system \
  recurring-job-group.longhorn.io/critical-
```

## Method 2: Via Longhorn UI

1. Navigate to Longhorn UI → Volumes
2. Click on the volume you want to configure
3. Go to the "Recurring Jobs" tab
4. Select the recurring jobs you want to attach
5. Save

## Method 3: Declarative (Kubernetes Manifest)

You can create a script or use kustomize to add labels to volumes. However, volumes are typically managed by Longhorn, so labels need to be patched.

## Available Backup Groups

Based on `manifests/argocd/longhorn-recurring-jobs.yaml`:

### `daily` Group
- **Schedule**: Daily at 3 AM UTC
- **Retention**: 30 days
- **Use for**: All volumes EXCEPT Immich
- **Excluded**: Immich volumes (to reduce storage costs)

```bash
kubectl label volume.longhorn.io <volume-name> \
  -n longhorn-system \
  recurring-job-group.longhorn.io/daily=enabled
```

## Quick Setup: Attach All Volumes (Except Immich)

Use the provided script to automatically attach all non-Immich volumes:

```bash
./scripts/attach-volumes-to-backup.sh
```

This script will:
1. Find all Longhorn volumes
2. Exclude any volumes with "immich" in the name
3. Attach remaining volumes to the `daily` backup group
4. Show a summary of what was attached/excluded

## Example: Attach All Volumes Except Immich

### Using the Script (Recommended)

```bash
# Make script executable (if not already)
chmod +x scripts/attach-volumes-to-backup.sh

# Run the script
./scripts/attach-volumes-to-backup.sh
```

### Manual Method

If you prefer to do it manually:

```bash
# List all volumes
kubectl get volumes.longhorn.io -n longhorn-system \
  -o custom-columns=NAME:.metadata.name,PVC:.metadata.labels.longhornvolume

# Attach each volume (excluding Immich)
# Replace <volume-name> with actual volume names
for volume in $(kubectl get volumes.longhorn.io -n longhorn-system -o name | \
  grep -v immich | grep -v IMIC); do
  kubectl label $volume -n longhorn-system \
    recurring-job-group.longhorn.io/daily=enabled
done
```

## Verify Volume Attachment

Check which groups a volume is attached to:

```bash
kubectl get volume.longhorn.io <volume-name> -n longhorn-system \
  -o jsonpath='{.metadata.labels}' | \
  jq 'to_entries | map(select(.key | startswith("recurring-job-group")))'
```

List all volumes in the daily backup group:

```bash
kubectl get volumes.longhorn.io -n longhorn-system \
  -l recurring-job-group.longhorn.io/daily=enabled
```

Verify Immich volumes are excluded:

```bash
# Should return empty or only show volumes that shouldn't be backed up
kubectl get volumes.longhorn.io -n longhorn-system \
  -l recurring-job-group.longhorn.io/daily=enabled \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.longhornvolume}{"\n"}{end}' | \
  grep -i immich
```

## Best Practices

1. **Classify volumes first**: Before attaching, classify each volume by criticality
2. **Document mappings**: Keep a record of which volumes belong to which group
3. **Test backups**: After attaching, verify backups are created successfully
4. **Monitor**: Set up alerts for backup failures

## Volume Classification

All volumes are backed up daily EXCEPT Immich:

```yaml
daily_backup:
  - PostgreSQL databases
  - Redis caches
  - RabbitMQ queues
  - Vault secrets storage
  - Zulip chat data
  - Wiki content
  - Docker registry
  - All other volumes

excluded:
  - Immich library (512Gi+ - too costly)
  - Immich PostgreSQL (can be recreated)
  - Immich machine learning cache
  - Immich Valkey cache
```

## Troubleshooting

### Volume not backing up
1. Check if volume has the correct label:
   ```bash
   kubectl get volume.longhorn.io <volume-name> -n longhorn-system \
     -o jsonpath='{.metadata.labels.recurring-job-group\.longhorn\.io/daily}'
   ```

2. Check if recurring job exists and has the group:
   ```bash
   kubectl get recurringjob backup-daily -n longhorn-system \
     -o jsonpath='{.spec.groups}'
   ```

3. Verify the volume is not an Immich volume (which should be excluded):
   ```bash
   kubectl get volume.longhorn.io <volume-name> -n longhorn-system \
     -o jsonpath='{.metadata.labels.longhornvolume}' | grep -i immich
   ```

3. Check recurring job status:
   ```bash
   kubectl get recurringjob -n longhorn-system
   ```

4. Check volume backup status in Longhorn UI or:
   ```bash
   kubectl get backups.longhorn.io -n longhorn-system
   ```

