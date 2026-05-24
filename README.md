# Postgres zeropoint module

This Terraform module brings up a Postgres database container on a pre-created Docker network for use by other zeropoint modules.

## Resources Created

- **Docker Image**: pulls `postgres:15`
- **Docker Container**: Postgres database joined to the provided Docker network

## Requirements

- Terraform >= 1.0
- Docker provider ~> 3.0

## Usage

Install via zeropoint API by specifying module source and required variables (zeropoint injects values):

```bash
curl -X POST http://<zeropoint-node-name>:2370/modules/install \
  -H "Content-Type: application/json" \
  -d '{
    "source": "https://github.com/zeropoint-os/postgres-module.git", 
    "module_id": "postgres"
  }'
```

### Manual (for testing)

Use Run task (Shift+Alt+T)
1. Full test - setup and apply
2. Full test - cleanup

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `zp_module_id` | string | Unique identifier for this module instance | `"postgres"` |
| `zp_network_name` | string | Pre-created Docker network name (injected by zeropoint) | (required) |
| `zp_module_dir` | string | Agent's working directory for this module — terraform state + cloned source (injected by zeropoint) | (required) |
| `zp_storage_dir` | string | Isolated data root for this module — all bind mounts must live under here (injected by zeropoint) | (required) |
| `zp_db_user` | string | Postgres user | `"postgres"` |
| `zp_db_password` | string | Postgres password | `"postgres"` (override in production) |
| `zp_db_name` | string | Postgres database name | `"postgres"` |
| `zp_db_port` | number | Internal Postgres port | `5432` |

## Outputs

| Name | Description |
|------|-------------|
| `main` | The Docker container resource for Postgres |
| `main_ports` | Metadata describing the internal Postgres port (5432) |
| `postgres_connection` | Map with `host`, `port`, `user`, `password`, `database`, and `uri` usable by other modules |

## Network & Service Discovery

- **Internal Port**: 5432 (Postgres)
- **Network**: Uses pre-created network provided by zeropoint via `zp_network_name`
- **No Host Ports**: Service discovery via Docker DNS only; other containers can reach the DB at `<module_id>-main:5432`

## Test

Use Run Task...

After `Full test: Setup and apply`, run the included test script to validate connectivity:

```bash
bash postgres-test.sh
```

This script will attempt a simple `psql` query inside the running Postgres container.

You can then clean up using the task: `Full test: Cleanup`