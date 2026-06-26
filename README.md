# luci-app-kubernetes

> 在 OpenWrt 路由器上通过 LuCI 管理 Kubernetes 集群的轻量级 Web 插件

---

## 📋 目录

- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [依赖组件](#依赖组件)
- [安装指南](#安装指南)
- [快速开始](#快速开始)
- [架构设计](#架构设计)
- [前端设计](#前端设计)
- [后端设计](#后端设计)
- [数据流设计](#数据流设计)
- [API 接口](#api-接口)
- [配置说明](#配置说明)
- [版本历史](#版本历史)
- [常见问题](#常见问题)
- [开源协议](#开源协议)

---

## 项目简介

**luci-app-kubernetes** 是一个运行在 OpenWrt/iStoreOS 路由器上的 LuCI 插件，让用户能够通过路由器 Web 管理界面直接操作 Kubernetes 集群。无需额外部署管理面板，路由器就是你的 K8s 控制中心。

### 为什么做这个项目？

1. **轻量**：不依赖 Node.js、Python 等运行时环境，纯 Lua + JavaScript 实现，内存占用极低
2. **原生集成**：作为 LuCI 插件，与路由器管理界面无缝融合
3. **随时随地管理**：只要有路由器 Web 界面，就能管理 K8s 集群
4. **适合边缘场景**：在家庭实验室、边缘计算、IoT 网关等场景中，路由器通常是常驻设备

### 适用场景

| 场景 | 说明 |
|------|------|
| 家庭 K8s 实验室 | 在软路由上管理家中的 K8s 集群 |
| 边缘计算节点 | 在边缘路由器上监控和管理边缘 K8s 节点 |
| 轻量运维 | 不需要部署重型 Dashboard，手机/电脑打开浏览器即可操作 |

---

## 功能特性

### 集群总览
- 📊 资源概览仪表盘，一键查看各类型资源数量
- 🖥️ 节点状态卡片，直观展示节点健康状态

### 节点管理
- 查看节点状态、IP、Kubelet 版本、操作系统版本
- 实时展示 **CPU/内存使用率**（含进度条和百分比）
- 显示 **已运行 Pod 数 / 最大配额**
- 自动汇总各 Pod 的 **CPU/内存资源请求值**
- 节点详情查看（`kubectl describe`）
- 查看/编辑节点 YAML

### 工作负载管理
- 📦 **Pods** — 查看 Pod 状态、就绪数、重启次数、IP、节点
- 🚀 **Deployments** — 管理部署，查看就绪/最新/可用副本数
- 🔄 **StatefulSets** — 管理有状态应用
- 🛡️ **DaemonSets** — 管理守护进程集
- ⚡ **Jobs** — 查看任务执行状态
- ⏰ **CronJobs** — 管理定时任务

### 网络管理
- 🌐 **Services** — 查看服务类型、ClusterIP、ExternalIP、端口
- 🔀 **Ingresses** — 查看入口规则、主机、路径

### 配置与存储
- ⚙️ **ConfigMaps** — 管理配置映射
- 🔑 **Secrets** — 查看密钥（安全不展示内容）
- 💾 **PVC** — 管理持久卷声明
- 🗄️ **PV** — 管理持久卷
- 📁 **StorageClasses** — 管理存储类

### 监控与事件
- 🔔 **事件** — 查看集群事件（按类型区分警告/正常）
- 📊 **资源** — 查看节点和 Pod 的 CPU/内存使用情况（`kubectl top`）

### 高级操作
- 📝 **YAML 管理** — 查看、编辑、应用任意资源的 YAML 配置
- 💻 **Pod 终端** — 在运行中的 Pod 内执行命令
- 📋 **日志查看** — 查看 Pod 容器日志
- 🔄 **重启部署** — 一键重启 Deployment
- 🗑️ **删除资源** — 安全删除各类资源
- 🏷️ **标签管理** — 为资源打标签
- 📦 **配额管理** — 为命名空间配置资源配额

---

## 系统要求

| 要求 | 最低 | 推荐 |
|------|------|------|
| OpenWrt 版本 | 19.07+ | 21.02+ / iStoreOS |
| RAM | 256 MB | 512 MB+ |
| 存储空间 | 5 MB 可用 | 10 MB+ |
| 架构 | all | x86_64, ARM64, MIPS |

---

## 依赖组件

| 包名 | 用途 | 必需 |
|------|------|------|
| `kubectl` | Kubernetes CLI 工具 | ✅ 是 |
| `curl` | HTTP 请求 | ✅ 是 |
| `jq` | JSON 解析 | ✅ 是 |

---

## 安装指南

### 方法一：安装 IPK 包（推荐）

1. 从 [Releases](https://github.com/gityanfei/luci-app-kubernetes/releases) 下载最新 `.ipk` 文件
2. 通过 SCP 或 LuCI 界面上传到路由器
3. SSH 登录路由器安装：

```bash
opkg install luci-app-kubernetes_*.ipk
```

### 方法二：使用 OpenWrt SDK 编译

```bash
# 克隆到 OpenWrt 包目录
cd /path/to/openwrt/package/feeds/luci/
git clone https://github.com/gityanfei/luci-app-kubernetes.git

# 在 OpenWrt SDK 中编译
make package/feeds/luci/luci-app-kubernetes/compile

# 编译产物位置：
# bin/packages/<arch>/luci/luci-app-kubernetes_*.ipk
```

### 方法三：手动安装

```bash
# 克隆仓库
git clone https://github.com/gityanfei/luci-app-kubernetes.git

# 复制文件到 OpenWrt 系统目录
cd luci-app-kubernetes
cp -r luasrc/* /usr/lib/lua/luci/
cp -r root/* /
chmod +x /etc/init.d/luci-kubernetes

# 清除 LuCI 缓存
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*

# 重启 rpcd
/etc/init.d/rpcd restart
```

---

## 快速开始

1. 登录 LuCI Web 管理界面
2. 导航到 **服务 → Kubernetes**
3. 面板自动加载，默认使用 `/root/.kube/config`
4. 点击左侧树导航切换不同视图

---

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    浏览器（客户端）                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              SPA 前端 (main.htm)                    │  │
│  │  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌───────┐  │  │
│  │  │ 左侧导航 │ │ 工具栏   │ │ 数据表格 │ │ 弹窗  │  │  │
│  │  │ (TreeView)│ │(命名空间 │ │ (动态渲染) │ │(YAML │  │  │
│  │  │         │ │ 刷新按钮) │ │          │ │ 日志  │  │  │
│  │  │         │ │          │ │          │ │ 终端) │  │  │
│  │  └─────────┘ └──────────┘ └──────────┘ └───────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│                          │ fetch()                      │
└──────────────────────────┼──────────────────────────────┘
                           │ HTTP (LuCI Session)
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  OpenWrt 路由器                          │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │          LuCI Web Framework (uhttpd)               │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  kubernetes.lua (后端控制器)                  │  │  │
│  │  │                                             │  │  │
│  │  │  ┌──────────┐ ┌──────────┐ ┌─────────────┐  │  │  │
│  │  │  │ 路由注册 │ │ API 处理  │ │ 工具函数    │  │  │  │
│  │  │  │ (entry)  │ │ (action_*)│ │ (exec_cmd)  │  │  │  │
│  │  │  └──────────┘ └──────────┘ └─────────────┘  │  │  │
│  │  │        │              │                     │  │  │
│  │  │        ▼              ▼                     │  │  │
│  │  │  ┌──────────────────────────────────────┐   │  │  │
│  │  │  │  kubectl 命令执行 (io.popen)          │   │  │  │
│  │  │  │  - get nodes/pods/deployments...     │   │  │  │
│  │  │  │  - top nodes/pods                    │   │  │  │
│  │  │  │  - describe/logs/exec/apply/delete   │   │  │  │
│  │  │  └──────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
│                          ▼                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Kubeconfig (/root/.kube/config)                   │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
└──────────────────────────┼──────────────────────────────┘
                           │ Kubernetes API
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Kubernetes 集群                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Master   │  │ Worker 1 │  │ Worker 2 │  ...         │
│  │ (API Srv)│  │          │  │          │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

### 架构说明

本插件采用 **SPA（单页应用）架构**，所有页面视图统一由 `main.htm` 承载：

1. **前端**：纯 JavaScript 实现，无框架依赖（jQuery-free），通过 `fetch()` 调用 LuCI API
2. **后端**：LuCI Controller 模式，通过 `entry()` 注册路由，`action_*()` 处理请求
3. **通信**：HTTP JSON API，利用 LuCI Session 进行认证
4. **数据源**：通过 `kubectl` CLI 与 K8s API Server 交互，Lua 端负责 JSON 序列化和数据加工

---

## 前端设计

### SPA 页面结构

```
main.htm（单一 HTML 文件，包含所有视图）
│
├── CSS 样式区（内联 <style>）
│   ├── 左侧导航树样式 (.k8s-tree)
│   ├── 工具栏样式 (.k8s-toolbar)
│   ├── 数据表格样式 (.k8s-table)
│   ├── 弹窗样式 (.k8s-overlay / .k8s-box)
│   ├── 总览卡片样式 (.k8s-ov-card)
│   ├── 节点卡片样式 (.k8s-node-card)
│   └── 终端样式 (.k8s-exec-*)
│
├── HTML 模板区
│   ├── 主容器 (k8s-container)
│   │   ├── 左侧导航树 (k8s-tree)
│   │   │   └── 分组：集群/工作负载/网络/配置与存储/监控
│   │   └── 右侧内容区 (k8s-content)
│   │       ├── 工具栏 (k8s-toolbar)
│   │       │   ├── 标题 + 计数徽章
│   │       │   ├── 命名空间下拉选择
│   │       │   └── 刷新按钮
│   │       └── 数据面板 (k8s-panel) — 动态渲染
│   ├── YAML 弹窗 (k8sYamlModal)
│   ├── 日志弹窗 (k8sLogModal)
│   └── 终端弹窗 (k8sExecModal)
│
└── JavaScript 逻辑区（内联 <script>）
    ├── 页面配置映射 (cfg 对象)
    │   └── 每个页面定义：图标、标题、API、列定义、操作按钮
    ├── 数据加载函数
    │   ├── k8sLoadData() — 通用数据加载
    │   ├── loadNodes() — 节点数据加载（含 top 数据）
    │   ├── loadOverview() — 总览仪表盘
    │   └── loadResources() — 资源监控
    ├── 表格渲染函数
    │   ├── buildTable() — 通用表格渲染
    │   └── renderNodesTableInner() — 节点专用表格
    ├── 操作处理函数
    │   ├── showYAML / k8sYamlEdit / k8sYamlApply
    │   ├── showLogs / showExec / showDescribe
    │   ├── doDelete / doRestart / doLabel / doQuota
    │   └── k8sExecCmd — 终端命令执行
    ├── 工具函数
    │   ├── esc() — HTML 转义
    │   ├── age() — 计算运行时间
    │   ├── parseCpu / parseMem — 资源单位解析
    │   └── formatCpuM / formatMemMi — 资源单位格式化
    └── 初始化入口
        ├── 导航事件绑定
        ├── 弹窗事件绑定
        └── loadNS / loadKc / k8sLoadData
```

### 页面渲染流程图

```
用户点击导航项
      │
      ▼
navigate(page) — 设置当前 page，更新导航高亮
      │
      ▼
k8sLoadData() — 读取 cfg[page] 配置
      │
      ├─ special === 'overview' → loadOverview()
      ├─ special === 'nodes'    → loadNodes()
      ├─ special === 'resources'→ loadResources()
      └─ 通用路径               → fetch(API) → buildTable()
      │
      ▼
数据渲染到 k8s-panel
```

### 节点页面数据加载流程

```
loadNodes()
      │
      ├─── 并行请求 1: k8s_top_nodes ──→ 解析 top 数据 (CPU/内存/百分比)
      │
      ├─── 并行请求 2: k8s_nodes ──────→ 获取节点列表
      │       │
      │       └─── 并行请求 3: k8s_pods (namespace=all) ──→ 按 nodeName 统计 Running Pod
      │                                                      ├─ Pod 数量
      │                                                      ├─ CPU requests 汇总
      │                                                      └─ Memory requests 汇总
      │
      └─── 三路数据合并 → renderNodesTableInner()
                │
                └─── 渲染表格：
                      ├── 节点信息（名称/IP/实例ID）
                      ├── 状态/Condition
                      ├── 配置（实例类型/CPU内存容量/可用区）
                      ├── 容器组（已运行数/总配额）
                      ├── CPU（请求值 / 使用值 + 进度条 + 百分比）
                      ├── 内存（请求值 / 使用值 + 进度条 + 百分比）
                      ├── Kubelet版本/Runtime/OS
                      ├── 创建时间
                      └── 操作按钮（YAML / 详情 / 删除）
```

---

## 后端设计

### LuCI Controller 架构

```
kubernetes.lua（后端控制器）
│
├── index() — 路由注册
│   ├── entry("admin/services/kubernetes") → 主入口
│   ├── entry("admin/services/kubernetes/app") → SPA 页面
│   ├── entry("admin/services/kubernetes/k8s_*") → 各 API 端点
│   └── ...
│
├── 工具函数
│   ├── exec_cmd(cmd) — 执行 Shell 命令（io.popen）
│   ├── get_kubeconfig() — 从 UCI 读取 kubeconfig 路径
│   └── run_kubectl(args, ns, as_json) — 封装 kubectl 调用
│
├── 数据端点（GET → JSON）
│   ├── action_nodes() — 节点列表
│   ├── action_namespaces() — 命名空间列表
│   ├── action_pods() — Pod 列表（支持按命名空间过滤）
│   ├── action_deployments() — 部署列表
│   ├── action_statefulsets() — 有状态集列表
│   ├── action_daemonsets() — 守护进程集列表
│   ├── action_jobs() — 任务列表
│   ├── action_cronjobs() — 定时任务列表
│   ├── action_services() — 服务列表
│   ├── action_ingresses() — 入口列表
│   ├── action_configmaps() — 配置映射列表
│   ├── action_secrets() — 密钥列表
│   ├── action_pvcs() — PVC 列表
│   ├── action_pvs() — PV 列表
│   ├── action_storageclasses() — 存储类列表
│   ├── action_events() — 事件列表
│   ├── action_resources() — 资源监控数据（top nodes + top pods）
│   └── action_top_nodes() — 节点资源指标（结构化 JSON）
│
├── 操作端点
│   ├── action_logs() — 获取 Pod 日志
│   ├── action_describe() — describe 资源
│   ├── action_yaml() — 获取资源 YAML
│   ├── action_delete() — 删除资源
│   ├── action_scale() — 伸缩副本数
│   ├── action_restart() — 重启部署
│   ├── action_apply() — 应用 YAML（写临时文件后 kubectl apply）
│   ├── action_exec() — 在 Pod 中执行命令
│   └── action_containers() — 获取 Pod 容器列表
```

### kubectl 调用封装

```
run_kubectl(args, ns, as_json)
      │
      ├── 读取当前 kubeconfig
      ├── 构建命令: KUBECONFIG=<path> kubectl
      ├── 添加命名空间参数（如指定）: -n <namespace>
      ├── 添加业务参数: args...
      ├── 如需 JSON 输出: 追加 -o json
      ├── 追加错误重定向: 2>/dev/null
      └── 执行并返回输出
```

### 节点资源数据处理

`action_top_nodes()` 对 `kubectl top nodes` 输出进行结构化处理：

```
kubectl top nodes --no-headers
      │
      ▼  原始输出（文本）:
      cn-chengdu.192.168.31.225   276m   27%   3205Mi   82%
      cn-chengdu.192.168.31.226   242m   13%   5473Mi   69%
      cn-chengdu.192.168.31.227   294m   14%   4143Mi   52%
      │
      ▼  Lua 解析:
      ├─ 按行拆分
      ├─ 按空白符分割字段
      ├─ 提取 name, cpu, cpuPct, mem, memPct
      ├─ cpuPct/memPct 去除 % 后转数字
      └─ 返回结构化数组
            │
            ▼  JSON 输出:
      {"nodes":[{"name":"xxx","cpu":"276m","cpuPct":27,"mem":"3205Mi","memPct":82},...]}
```

> **注意**：使用结构化 JSON 而非原始文本的原因是 `http.write_json` 内部使用 `printf` 序列化，`%` 字符会被当作格式说明符处理导致数据丢失。

---

## 数据流设计

### 请求/响应流程

```
浏览器                                    路由器                                    K8s 集群
  │                                         │                                         │
  │  1. 页面加载                            │                                         │
  │  GET /admin/services/kubernetes/app     │                                         │
  │ ──────────────────────────────────────► │                                         │
  │  2. 返回 SPA HTML                      │                                         │
  │  ◄───────────────────────────────────── │                                         │
  │                                         │                                         │
  │  3. 加载命名空间列表                    │                                         │
  │  GET /admin/.../k8s_namespaces          │                                         │
  │ ──────────────────────────────────────► │  kubectl get namespaces -o json          │
  │                                         │ ──────────────────────────────────────► │
  │                                         │  JSON 响应                                │
  │                                         │ ◄────────────────────────────────────── │
  │  4. JSON 数据                          │                                         │
  │  ◄───────────────────────────────────── │                                         │
  │                                         │                                         │
  │  5. 加载节点数据（含 top）              │                                         │
  │  GET /admin/.../k8s_top_nodes           │  kubectl top nodes                      │
  │ ──────────────────────────────────────► │ ──────────────────────────────────────► │
  │  GET /admin/.../k8s_nodes              │  kubectl get nodes -o json               │
  │ ──────────────────────────────────────► │ ──────────────────────────────────────► │
  │  GET /admin/.../k8s_pods?ns=all        │  kubectl get pods --all-namespaces       │
  │ ──────────────────────────────────────► │ ──────────────────────────────────────► │
  │  6. 合并渲染                            │                                         │
  │  ◄───────────────────────────────────── │                                         │
  │                                         │                                         │
  │  7. 用户操作（如删除 Pod）              │                                         │
  │  DELETE /admin/.../k8s_delete           │  kubectl delete pod <name>              │
  │ ──────────────────────────────────────► │ ──────────────────────────────────────► │
  │  8. 刷新数据                            │                                         │
  │  GET /admin/.../k8s_pods               │                                         │
  │ ──────────────────────────────────────► │                                         │
```

### kubeconfig 配置

```
/root/.kube/config  ← 当前使用的 kubeconfig（硬编码路径，位于 kubernetes.lua）
```

---

## API 接口

| 端点 | 方法 | 说明 |
|------|------|------|
| `k8s_nodes` | GET | 获取节点列表 |
| `k8s_namespaces` | GET | 获取命名空间列表 |
| `k8s_pods` | GET | 获取 Pod 列表（可指定 namespace） |
| `k8s_deployments` | GET | 获取部署列表 |
| `k8s_statefulsets` | GET | 获取有状态集列表 |
| `k8s_daemonsets` | GET | 获取守护进程集列表 |
| `k8s_jobs` | GET | 获取任务列表 |
| `k8s_cronjobs` | GET | 获取定时任务列表 |
| `k8s_services` | GET | 获取服务列表 |
| `k8s_ingresses` | GET | 获取入口列表 |
| `k8s_configmaps` | GET | 获取配置映射列表 |
| `k8s_secrets` | GET | 获取密钥列表 |
| `k8s_pvcs` | GET | 获取 PVC 列表 |
| `k8s_pvs` | GET | 获取 PV 列表 |
| `k8s_storageclasses` | GET | 获取存储类列表 |
| `k8s_events` | GET | 获取事件列表 |
| `k8s_resources` | GET | 获取资源使用情况（top nodes + pods） |
| `k8s_top_nodes` | GET | 获取节点资源指标（结构化 JSON） |
| `k8s_yaml` | GET | 获取资源 YAML 配置 |
| `k8s_describe` | GET | 描述资源详情 |
| `k8s_delete` | DELETE | 删除资源 |
| `k8s_restart` | POST | 重启部署 |
| `k8s_apply` | POST | 应用 YAML 配置 |
| `k8s_scale` | POST | 伸缩副本数 |
| `k8s_logs` | GET | 获取 Pod 日志 |
| `k8s_exec` | GET | 在 Pod 中执行命令 |
| `k8s_containers` | GET | 获取 Pod 容器列表 |

---

## 配置说明

### 前置条件

1. **kubectl 已安装** 且在路由器 PATH 中可访问
2. **kubeconfig 文件存在**（默认路径：`/root/.kube/config`）
3. 路由器能**网络访问** K8s API Server

### 默认配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| kubeconfig 路径 | `/root/.kube/config` | K8s 集群配置文件（通过 UCI 管理） |
| UCI 配置 | `uci show kubernetes` | OpenWrt UCI 配置 |

### 修改配置

```bash
# 查看当前配置
uci show kubernetes

# 修改 kubeconfig 路径
uci set kubernetes.config.kubeconfig='/path/to/your/kubeconfig'
uci commit kubernetes
```

---

## 版本历史

### v0.0.2（2026-06-23）

**Bug 修复**
- 🔧 修复节点页面"按量付费"文字显示（非云环境改为 `-`）
- 🔧 修复容器组列显示 allocatable/capacity（固定 110）的问题，改为实际已运行数/总配额
- 🔧 修复 CPU/内存请求值为空的问题，改为从 Pod resources.requests 汇总计算
- 🔧 修复节点资源百分比显示为 0% 的问题（http.write_json 对 `%` 字符的转义 bug）
- 🔧 修复 GitHub Actions 创建 Release 权限不足的问题（添加 contents: write）

### v0.0.1（2026-06-22）

**初始版本**
- 🎉 集群总览仪表盘
- 🖥️ 节点管理（状态、版本、资源）
- 📦 Pods / 🚀 Deployments / 🔄 StatefulSets / 🛡️ DaemonSets
- ⚡ Jobs / ⏰ CronJobs
- 🌐 Services / 🔀 Ingresses
- ⚙️ ConfigMaps / 🔑 Secrets / 💾 PVC / 🗄️ PV / 📁 StorageClasses
- 🔔 事件查看 / 📊 资源监控
- 📝 YAML 查看/编辑/应用
- 💻 Pod 终端
- 🚀 GitHub Actions 自动构建 IPK

---

## 常见问题

### 页面一直显示"加载中..."

1. 检查 kubectl 是否已安装：`which kubectl`
2. 检查 kubeconfig 是否有效：`KUBECONFIG=/root/.kube/config kubectl get nodes`
3. 清除 LuCI 缓存：`rm -rf /tmp/luci-* && /etc/init.d/rpcd restart`

### 连接被拒绝或找不到主机

1. 检查路由器到 K8s API Server 的网络连通性
2. 检查 kubeconfig 中的 server URL 是否可从路由器访问

### YAML 应用 失败

1. 确认 kubeconfig 有足够权限
2. 检查 YAML 语法是否合法
3. 查看错误输出中的具体原因

### 节点资源百分比显示为 0%

- 确保 metrics-server 已在 K8s 集群中部署并正常运行
- 执行 `kubectl top nodes` 验证是否能获取资源数据

---

## 开源协议

MIT License

## 作者

[gityanfei](https://github.com/gityanfei)
