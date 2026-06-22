# luci-app-kubernetes

> LuCI plugin for managing Kubernetes clusters directly from OpenWrt router.

## Features

- **Cluster Overview**: Dashboard with real-time resource statistics
- **Node Management**: View node status, resources (CPU/Memory), and configuration
- **Workloads**: Manage Pods, Deployments, StatefulSets, DaemonSets, Jobs, CronJobs
- **Network**: View Services, Ingresses
- **Config & Storage**: Manage ConfigMaps, Secrets, PVCs, PVs, StorageClasses
- **Events**: View cluster events with type filtering
- **Resources**: Monitor CPU and memory usage per node and pod
- **Kubeconfig Switching**: Switch between multiple kubeconfig files with history
- **YAML Management**: View, edit, and apply YAML configurations inline
- **Pod Terminal**: Execute commands in running pods

## Environment Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| OpenWrt Version | 19.07+ | 21.02+ / iStoreOS |
| RAM | 256 MB | 512 MB+ |
| Storage | 5 MB free | 10 MB+ |
| Architecture | all | x86_64, ARM64, MIPS |

## Dependencies

| Package | Purpose | Required |
|---|---|---|
| `kubectl` | Kubernetes CLI tool | ✅ Yes |
| `curl` | HTTP requests | ✅ Yes |
| `jq` | JSON parsing | ✅ Yes |

## Installation

### Method 1: Install from IPK

1. Download the latest `.ipk` file from [Releases](https://github.com/gityanfei/luci-app-kubernetes/releases)
2. Upload to your OpenWrt router via SCP or LuCI interface
3. SSH into your router and install:

```bash
opkg install luci-app-kubernetes_*.ipk
```

### Method 2: Build from Source (OpenWrt SDK)

```bash
# Clone into OpenWrt package directory
cd /path/to/openwrt/package/feeds/luci/
git clone https://github.com/gityanfei/luci-app-kubernetes.git

# Build in OpenWrt SDK
make package/feeds/luci/luci-app-kubernetes/compile

# The IPK will be generated at:
# bin/packages/<arch>/luci/luci-app-kubernetes_*.ipk
```

### Method 3: Manual Installation

```bash
# Clone the repository
git clone https://github.com/gityanfei/luci-app-kubernetes.git

# Copy files to OpenWrt system directories
cd luci-app-kubernetes
cp -r luasrc/* /usr/lib/lua/luci/
cp -r root/* /
chmod +x /etc/init.d/luci-kubernetes

# Clear LuCI cache
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*

# Restart rpcd
/etc/init.d/rpcd restart
```

## Configuration

### Prerequisites

1. **kubectl must be installed** on your OpenWrt router and accessible in PATH
2. **kubeconfig file** must exist (default: `/etc/kubernetes/admin.conf`)
3. The router must have **network access** to your Kubernetes cluster

### Setting up kubeconfig

After installation, access the Kubernetes management page in LuCI:

1. Go to **Services → Kubernetes**
2. Use the **kubeconfig dropdown** in the toolbar to switch configurations
3. Select **📝 自定义...** to input a custom kubeconfig path

### Default Configuration

```bash
# Default kubeconfig path
/etc/kubernetes/admin.conf

# UCI config file
/etc/kubernetes/k8s-ui-config.json

# OpenWrt config (legacy)
uci show kubernetes
```

## Usage

### Access the Panel

1. Login to LuCI web interface
2. Navigate to **Services → Kubernetes**
3. The dashboard will automatically load using your default kubeconfig

### Kubeconfig Switching

The toolbar provides a dropdown to switch between kubeconfig files:

- Select from previously used configurations
- Choose **📝 自定义...** to enter a new path
- Configuration is persisted across sessions

### YAML Edit & Apply

1. Click **YAML** on any resource row
2. Click **✏️ 编辑** to enter edit mode
3. Modify the YAML content
4. Click **✅ 应用** to apply changes to the cluster

### Pod Terminal

1. On any Pod row, click **exec** button
2. Select the container (if multi-container Pod)
3. Enter commands in the terminal interface

## Screenshots

| Overview | Nodes | Pods |
|---|---|---|
| Dashboard with resource cards | Node table with CPU/Memory usage | Pod list with status and actions |

## Project Structure

```
luci-app-kubernetes/
├── luasrc/                          # LuCI source
│   ├── controller/
│   │   └── kubernetes.lua           # Backend API handlers
│   └── view/kubernetes/
│       └── main.htm                 # SPA frontend (all views)
├── root/
│   └── etc/
│       ├── config/kubernetes        # UCI config
│       ├── init.d/luci-kubernetes   # Init script
│       └── uci-defaults/99-luci-kubernetes
└── Makefile                         # OpenWrt build config
```

## API Endpoints

The plugin exposes REST-like endpoints at `/admin/services/kubernetes/`:

| Endpoint | Method | Description |
|---|---|---|
| `k8s_nodes` | GET | List all nodes |
| `k8s_namespaces` | GET | List all namespaces |
| `k8s_pods` | GET | List pods (optionally filtered by namespace) |
| `k8s_deployments` | GET | List deployments |
| `k8s_statefulsets` | GET | List StatefulSets |
| `k8s_daemonsets` | GET | List DaemonSets |
| `k8s_jobs` | GET | List Jobs |
| `k8s_cronjobs` | GET | List CronJobs |
| `k8s_services` | GET | List Services |
| `k8s_ingresses` | GET | List Ingresses |
| `k8s_configmaps` | GET | List ConfigMaps |
| `k8s_secrets` | GET | List Secrets |
| `k8s_pvcs` | GET | List PersistentVolumeClaims |
| `k8s_pvs` | GET | List PersistentVolumes |
| `k8s_storageclasses` | GET | List StorageClasses |
| `k8s_events` | GET | List events |
| `k8s_resources` | GET | Get resource usage (kubectl top) |
| `k8s_top_nodes` | GET | Get node resource metrics |
| `k8s_yaml` | GET | Get resource YAML |
| `k8s_describe` | GET | Describe a resource |
| `k8s_delete` | DELETE | Delete a resource |
| `k8s_restart` | POST | Restart a deployment |
| `k8s_apply` | POST | Apply YAML configuration |
| `k8s_logs` | GET | Get pod logs |
| `k8s_exec` | GET | Execute command in pod |
| `k8s_containers` | GET | List pod containers |
| `k8s_settings` | GET | Get current kubeconfig settings |
| `k8s_settings_save` | POST | Save kubeconfig path |

## Troubleshooting

### "Loading..." never finishes
- Check if `kubectl` is installed: `which kubectl`
- Check kubeconfig: `KUBECONFIG=/etc/kubernetes/admin.conf kubectl get nodes`
- Clear LuCI cache: `rm -rf /tmp/luci-* && /etc/init.d/rpcd restart`

### "Connection refused" or "No such host"
- Verify network connectivity to K8s API server
- Check kubeconfig `server` URL is reachable from the router

### YAML apply fails
- Check if the kubeconfig has sufficient permissions
- Verify YAML syntax is valid

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

[gityanfei](https://github.com/gityanfei)
