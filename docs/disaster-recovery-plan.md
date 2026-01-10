# Disaster Recovery Plan for akxr Cluster

## 1. Recovery Objectives

### Recovery Time Objective (RTO)
- **Critical Services** (PostgreSQL, Redis, RabbitMQ): 4 hours
- **Core Services** (Zulip, Immich, Vault): 8 hours
- **Media Services** (Jellyfin, etc.): 24 hours

### Recovery Point Objective (RPO)
- **Critical Data** (Databases): 1 hour (hourly backups)
- **Core Data** (Applications): 6 hours (6-hourly backups)
- **Media Data**: 24 hours (daily backups)

## 2. Backup Strategy Layers

### Layer 1: Longhorn System Backups
**Purpose**: Restore entire Longhorn system state including volumes, settings, recurring jobs

**Configuration**:
- Backup target: `s3://akxr-backup@us-east-005/` (Backblaze B2)
- Frequency: Daily (recommended)
- Retention: 30 days

**What it covers**:
- Volume definitions and metadata
- Longhorn settings
- Recurring job configurations
- Backing images
- Storage classes

**What it doesn't cover**:
- Actual volume data (requires volume backups)
- Kubernetes resources (Deployments, Services, etc.)
- Application-level data consistency

### Layer 2: Longhorn Volume Backups
**Purpose**: Backup actual data in volumes

**Daily Backups** (all volumes except Immich):
- PostgreSQL data volumes
- Redis data volumes
- RabbitMQ data volumes
- Vault data volumes
- Zulip volumes
- Wiki volumes
- Docker registry
- All other volumes

**Excluded from Backup**:
- **Immich volumes** (excluded due to storage costs - 512Gi+ library volume)
  - Immich library volume
  - Immich PostgreSQL volume
  - Immich machine learning cache
  - Immich Valkey cache

### Layer 3: Application-Level Backups
**Purpose**: Ensure application consistency and enable point-in-time recovery

**PostgreSQL**:
- Use `pg_dump` or `pg_basebackup` for logical/physical backups
- Store alongside Longhorn backups
- Frequency: Hourly for production databases

**Redis**:
- RDB snapshots or AOF persistence
- Frequency: Every 6 hours

**RabbitMQ**:
- Export definitions and data
- Frequency: Every 6 hours

### Layer 4: GitOps Repository
**Purpose**: Restore cluster configuration and application definitions

**Already covered**:
- Git repository is version controlled
- All manifests, charts, and configurations are in git

**Additional considerations**:
- Ensure repository is backed up (GitHub/GitLab backup)
- Document which git commit corresponds to which backup

### Layer 5: Secrets Management
**Purpose**: Restore encrypted secrets

**Sealed Secrets**:
- Sealed Secrets are stored in git (already backed up)
- Ensure Sealed Secrets controller private key is backed up securely
- Document key recovery procedure

## 3. Backup Implementation

### 3.1 Longhorn System Backup (Recurring Job)

Create a recurring job for system backups:

```yaml
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: system-backup-daily
  namespace: longhorn-system
spec:
  task: system-backup
  cron: "0 2 * * *"  # Daily at 2 AM
  retain: 30
  concurrency: 1
  labels: {}
  groups: []
```

### 3.2 Longhorn Volume Backups (Recurring Job)

Single daily backup job for all volumes except Immich:

```yaml
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: backup-daily
  namespace: longhorn-system
spec:
  task: backup
  cron: "0 3 * * *"  # Daily at 3 AM UTC
  retain: 30  # 30 days
  concurrency: 2
  labels:
    backup-tier: daily
  groups:
    - daily
```

### 3.3 Attach Volumes to Backup Group

**Important**: Immich volumes are excluded from backups to reduce storage costs.

Use the provided script to attach all non-Immich volumes:

```bash
./scripts/attach-volumes-to-backup.sh
```

Or manually attach volumes (excluding Immich):

```bash
# Attach a volume to daily backup group
kubectl label volume.longhorn.io <volume-name> \
  -n longhorn-system \
  recurring-job-group.longhorn.io/daily=enabled

# Verify Immich volumes are NOT attached
kubectl get volumes.longhorn.io -n longhorn-system \
  -l recurring-job-group.longhorn.io/daily=enabled \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.longhornvolume}{"\n"}{end}' | \
  grep -i immich
```

## 4. Disaster Scenarios & Recovery Procedures

### Scenario 1: Full Cluster Loss
**Assumption**: Complete cluster destruction, need to rebuild from scratch

**Recovery Steps**:
1. Provision new Kubernetes cluster (k3s)
2. Install Longhorn
3. Configure backup target (restore from git)
4. Restore Longhorn system backup
5. Restore volumes from backups
6. Restore GitOps repository
7. ArgoCD will sync applications
8. Verify application data integrity

**RTO**: 4-8 hours
**RPO**: Depends on last backup

### Scenario 2: Partial Node Failure
**Assumption**: One or more nodes fail, but cluster is still operational

**Recovery Steps**:
1. Longhorn automatically rebuilds replicas on remaining nodes
2. If data loss occurs, restore from volume backups
3. Scale applications if needed

**RTO**: 1-2 hours (automatic)
**RPO**: Minimal (Longhorn replication)

### Scenario 3: Data Corruption
**Assumption**: Application data is corrupted but infrastructure is intact

**Recovery Steps**:
1. Identify corrupted volume
2. Detach volume
3. Restore from most recent known-good backup
4. Reattach volume
5. Verify application functionality

**RTO**: 2-4 hours
**RPO**: Depends on backup frequency

### Scenario 4: Application-Level Failure
**Assumption**: Application misconfiguration or data inconsistency

**Recovery Steps**:
1. Use application-level backups (PostgreSQL dumps, etc.)
2. Restore to point-in-time if available
3. Verify data consistency

**RTO**: 1-2 hours
**RPO**: Depends on application backup frequency

## 5. Backup Verification & Testing

### Monthly Tests
- **Full restore test**: Restore entire cluster in test environment
- **Volume restore test**: Restore individual volumes
- **Application restore test**: Restore application data

### Quarterly Tests
- **Disaster simulation**: Full cluster rebuild
- **Documentation review**: Update procedures based on findings

### Backup Integrity Checks
- Verify backups are accessible in Backblaze B2
- Check backup sizes (detect anomalies)
- Verify backup timestamps

## 6. Monitoring & Alerting

### Backup Monitoring
- Monitor recurring job execution
- Alert on backup failures
- Track backup sizes and growth
- Monitor backup target availability

### Key Metrics
- Backup success rate
- Backup duration
- Backup storage usage
- Time since last successful backup

## 7. Documentation & Runbooks

### Runbooks to Create
1. **Full Cluster Restore**: Step-by-step procedure
2. **Volume Restore**: How to restore individual volumes
3. **Application Restore**: Application-specific restore procedures
4. **Backup Verification**: How to verify backup integrity

### Information to Document
- Backup target credentials location
- Sealed Secrets key recovery
- Critical volume mappings
- Application dependencies
- Recovery contact information

## 8. Backup Storage Considerations

### Backblaze B2
- Current bucket: `akxr-backup`
- Region: `us-east-005`
- Lifecycle policies: Consider implementing to manage costs
- Versioning: Enable if supported

### Storage Costs
- Monitor backup storage usage
- Implement retention policies
- Consider compression (Longhorn supports compression)

## 9. Next Steps

1. **Implement recurring jobs** for system and volume backups
2. **Set up monitoring** for backup jobs
3. **Create runbooks** for common recovery scenarios
4. **Test restore procedures** in non-production environment
5. **Document** critical volume mappings and dependencies
6. **Set up alerts** for backup failures
7. **Schedule regular** backup verification tests

## 10. Critical Questions to Answer

Before implementing, answer these:

1. **What's your actual RTO/RPO requirements?** (This plan assumes certain values)
2. **Which volumes are truly critical?** (Need to classify all 20 volumes)
3. **What's your backup storage budget?** (Affects retention policies)
4. **How often can you test restores?** (Affects confidence in recovery)
5. **Who has access to restore?** (Security and access control)

