# luci-app-kubernetes 技术规格文档

> 文档版本: v1.0
> 创建日期: 2026-06-26
> 项目名称: luci-app-kubernetes
> 当前版本: v0.0.2

---

## 1. 系统架构

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    浏览器（客户端）                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              SPA 前端 (main.htm)                    │  │
│  │  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌───────┐  │  │
│  │  │ 左侧导航 │ │ 工具栏   │ │ 数据表格 │ │ 弹窗  │  │  │
│  │  │ (TreeView)│ │(命名空间 │ │ (动态渲染) │ │(YAML │  │  │
│  │  │         │ │ kubeconfig│ │          │ │ 日志  │  │  │
│  │  │         │ │ 刷新按钮) │ │          │ │ 终端) │  │  │
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

### 1.2 架构说明

本插件采用 **SPA（单页应用）架构**，所有页面视图统一由 `main.htm` 承载：

1. **前端**: 纯 JavaScript 实现，无框架依赖（jQuery-free），通过 `fetch()` 调用 LuCI API
2. **后端**: LuCI Controller 模式，通过 `entry()` 注册路由，`action_*()` 处理请求
3. **通信**: HTTP JSON API，利用 LuCI Session 进行认证
4. **数据源**: 通过 `kubectl` CLI 与 K8s API Server 交互，Lua 端负责 JSON 序列化和数据加工

---

## 2. 项目结构

```
luci-app-kubernetes/
├── Makefile                          # OpenWrt 包构建配置
├── LICENSE                           # MIT 许可证
├── README.md                         # 项目文档
├── .gitignore                        # Git 忽略规则
├── .github/
│   └── workflows/
│       └── build-ipk.yml             # GitHub Actions CI/CD
├── luasrc/
│   ├── controller/
│   │   └── kubernetes.lua            # 后端控制器（路由 + API）
│   ├── model/                        # LuCI 模型层（当前为空）
│   └── view/
│       └── kubernetes/
│           ├── main.htm              # SPA 主页面（核心）
│           ├── k8s-common.js         # 共享 JS 工具库（旧版独立页面用）
│           ├── overview.htm          # 旧版独立总览页
│           ├── nodes.htm             # 旧版独立节点页
│           ├── pods.htm              # 旧版独立 Pod 页
│           ├── deployments.htm       # 旧版独立部署页
│           ├── statefulsets.htm      # 旧版独立有状态集页
│           ├── daemonsets.htm        # 旧版独立守护进程页
│           ├── jobs.htm              # 旧版独立任务页
│           ├── cronjobs.htm          # 旧版独立定时任务页
│           ├── services.htm          # 旧版独立服务页
│           ├── ingresses.htm         # 旧版独立入口页
│           ├── configmaps.htm        # 旧版独立配置映射页
│           ├── secrets.htm           # 旧版独立密钥页
│           ├── pvcs.htm              # 旧版独立 PVC 页
│           ├── pvs.htm               # 旧版独立 PV 页
│           ├── storageclasses.htm    # 旧版独立存储类页
│           ├── namespaces.htm        # 旧版独立命名空间页
│           ├── events.htm            # 旧版独立事件页
│           ├── resources.htm         # 旧版独立资源监控页
│           ├── settings.htm          # 旧版独立设置页
│           └── resource_list.htm     # 旧版通用资源列表模板
└── root/
    ├── etc/
    │   ├── config/
    │   │   └── kubernetes            # UCI 配置文件
    │   ├── init.d/
    │   │   └── luci-kubernetes       # init 脚本
    │   └── uci-defaults/
    │       └── 99-luci-kubernetes    # 首次安装默认配置
    ├── usr/lib/lua/luci/             # Lua 扩展目录（当前为空）
    └── www/luci-static/resources/view/kubernetes/  # 静态资源目录（当前为空）
```

### 2.1 核心文件说明

| 文件 | 职责 | 大小 |
|------|------|------|
| `luasrc/controller/kubernetes.lua` | 后端控制器，注册路由和 API 端点 | ~300 行 |
| `luasrc/view/kubernetes/main.htm` | SPA 前端主页面，包含所有视图逻辑 | ~1000 行 |
| `Makefile` | OpenWrt 包构建配置 | 12 行 |
| `root/etc/config/kubernetes` | UCI 配置（kubeconfig 路径、默认命名空间等） | 5 行 |

---

## 3. 前端设计

### 3.1 SPA 页面结构

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
│   ├── 终端样式 (.k8s-exec-*)
│   └── YAML 编辑器样式 (.k8s-yaml-editor-*)
│
├── HTML 模板区
│   ├── 主容器 (k8s-container)
│   │   ├── 左侧导航树 (k8s-tree)
│   │   │   └── 分组：集群/工作负载/网络/配置与存储/资源/事件
│   │   └── 右侧内容区 (k8s-content)
│   │       ├── 工具栏 (k8s-toolbar)
│   │       │   ├── 标题 + 计数徽章
│   │       │   ├── 命名空间下拉选择
│   │       │   └── 刷新按钮
│   │       └── 数据面板 (k8s-panel) — 动态渲染
│   ├── YAML 弹窗 (k8sYamlModal) — 含行号和折叠
│   ├── 日志弹窗 (k8sLogModal)
│   ├── 终端弹窗 (k8sExecModal)
│   └── 副本数弹窗 (k8sScaleModal)
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
    │   ├── doDelete / doRestart / doLabel / doQuota / doScale
    │   └── k8sExecCmd — 终端命令执行
    ├── YAML 编辑器
    │   ├── k8sUpdateLineNumbers() — 行号更新
    │   ├── k8sDetectFolds2() — 代码折叠检测
    │   └── k8sToggleYamlFold() — 折叠切换
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

### 3.2 页面配置映射 (cfg)

前端通过 `cfg` 对象定义每个页面的元数据：

```javascript
cfg = {
    overview:     { title:'总览',   api:null,         special:'overview' },
    nodes:        { title:'节点',   api:'k8s_nodes',   kind:'node',    showNS:false, special:'nodes' },
    namespaces:   { title:'命名空间', api:'k8s_namespaces', kind:'namespace', showNS:false,
                    cols:[...], actions:['yaml','edit','label','quota','delete'] },
    pods:         { title:'Pods',  api:'k8s_pods',    kind:'pod',     showNS:true,
                    cols:[...], actions:['yaml','logs','exec','describe','delete'] },
    deployments:  { title:'部署',  api:'k8s_deployments', kind:'deployment', showNS:true,
                    cols:[...], actions:['yaml','restart','describe','delete'] },
    // ... 其他资源页面类似结构
    resources:    { title:'资源',  api:'k8s_resources', kind:'', showNS:true, special:'resources' },
    events:       { title:'事件',  api:'k8s_events',  kind:'event',   showNS:true, cols:[...], actions:[] }
}
```

每个页面配置包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `title` | string | 页面标题 |
| `api` | string | 后端 API 端点名 |
| `kind` | string | K8s 资源类型（用于 YAML/describe/delete 等操作） |
| `showNS` | boolean | 表格是否显示命名空间列 |
| `special` | string | 特殊页面标识（overview/nodes/resources），走自定义渲染逻辑 |
| `cols` | array | 列定义数组，每列包含 label、width、render 函数 |
| `actions` | array | 操作按钮列表 |

### 3.3 页面渲染流程

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
      │     └─ 并行请求各资源 API → 统计数量 → 渲染卡片网格 + 节点卡片
      │
      ├─ special === 'nodes' → loadNodes()
      │     └─ 三路并行请求 → 合并数据 → renderNodesTableInner()
      │
      ├─ special === 'resources' → loadResources()
      │     └─ 请求 k8s_resources → 解析 top 输出 → 渲染节点/Pod 资源表
      │
      └─ 通用路径 → fetch(API) → buildTable()
            └─ 通用表格渲染：表头 + 数据行 + 操作按钮
```

### 3.4 节点页面数据加载流程

```
loadNodes()
      │
      ├─── 并行请求 1: k8s_top_nodes → 解析 top 数据 (CPU/内存/百分比)
      │         └─ 返回 topMap: { nodeName: { cpu, cpuPct, mem, memPct } }
      │
      ├─── 并行请求 2: k8s_nodes → 获取节点列表
      │       │
      │       └─── 并行请求 3: k8s_pods (namespace=all) → 按 nodeName 统计
      │               ├─ Running Pod 数量
      │               ├─ CPU requests 汇总 (parseCpu)
      │               └─ Memory requests 汇总 (parseMem)
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

### 3.5 资源单位解析

```javascript
// CPU 解析：统一转为毫核 (m)
parseCpu(v):
    "250m"  → 250
    "1"     → 1000
    "0.5"   → 500

// 内存解析：统一转为 MiB
parseMem(v):
    "128Ki" → 0.125
    "256Mi" → 256
    "2Gi"   → 2048
    "1Ti"   → 1048576

// 格式化输出
formatCpuM(m):   m >= 1000 → "2.0 vCPU", 否则 → "250m"
formatMemMi(mi): mi >= 1024 → "2.0 Gi",   否则 → "256 Mi"
```

### 3.6 YAML 编辑器设计

```
┌─────────────────────────────────────────┐
│  YAML - deployment/my-app          [×]  │
├────┬────────────────────────────────────┤
│ 1  │ apiVersion: apps/v1               │
│ 2  │ kind: Deployment                  ▼│
│ 3 ▼│ metadata:                          │
│    │   ...                              │ ← 折叠区域
│ 8  │ spec:                              │
│ 9  │   replicas: 3                      │
│    │   ...                              │
├────┴────────────────────────────────────┤
│                           [ 应用 ]      │
└─────────────────────────────────────────┘

特性：
- 行号 gutter（左侧灰色区域）
- 代码折叠（基于缩进检测，>= 3 行的块可折叠）
- 折叠按钮（行号旁的 ▼/▶ 图标）
- 滚动同步（gutter 与编辑器同步滚动）
- data-full-text 属性保存完整文本（折叠时显示精简版）
```

---

## 4. 后端设计

### 4.1 LuCI Controller 架构

```
kubernetes.lua（后端控制器）
│
├── index() — 路由注册
│   ├── entry("admin/services/kubernetes") → 主入口（alias → app）
│   ├── entry("admin/services/kubernetes/app") → SPA 页面（template）
│   ├── entry("admin/services/kubernetes/<old_pages>") → 旧页面重定向
│   └── entry("admin/services/kubernetes/k8s_*") → 各 API 端点（call）
│
├── 工具函数
│   ├── exec_cmd(cmd) — 执行 Shell 命令（io.popen）
│   ├── run_kubectl(args, ns, as_json) — 封装 kubectl 调用
│   └── get_ns() — 从请求参数获取命名空间
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
│   ├── action_events() — 事件列表（按创建时间排序）
│   ├── action_resources() — 资源监控数据（top nodes + top pods）
│   └── action_top_nodes() — 节点资源指标（结构化 JSON）
│
├── 操作端点
│   ├── action_logs() — 获取 Pod 日志
│   ├── action_describe() — describe 资源
│   ├── action_yaml() — 获取资源 YAML
│   ├── action_delete() — 删除资源
│   ├── action_scale() — 伸缩副本数
│   ├── action_restart() — 重启部署（rollout restart）
│   ├── action_apply() — 应用 YAML（写临时文件后 kubectl apply）
│   ├── action_exec() — 在 Pod 中执行命令
│   └── action_containers() — 获取 Pod 容器列表
```

### 4.2 kubectl 调用封装

```lua
-- 全局 kubeconfig 路径
local KUBECONFIG = "/root/.kube/config"

function run_kubectl(args, ns, as_json)
    local cmd = "KUBECONFIG=" .. KUBECONFIG .. " kubectl"

    -- 命名空间过滤
    if ns and ns ~= "" and ns ~= "all" then
        cmd = cmd .. " -n " .. ns
    end

    -- 拼接参数
    if type(args) == "table" then
        for _, arg in ipairs(args) do
            cmd = cmd .. " " .. arg
        end
    else
        cmd = cmd .. " " .. args
    end

    -- JSON 输出
    if as_json then
        cmd = cmd .. " -o json"
    end

    -- 错误静默
    cmd = cmd .. " 2>/dev/null"

    return exec_cmd(cmd)
end
```

### 4.3 节点资源数据处理

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
      ├─ 按行拆分 (gmatch '[^\n]+')
      ├─ 按空白符分割字段 (gmatch '%S+')
      ├─ 提取 name, cpu, cpuPct, mem, memPct
      ├─ cpuPct/memPct 去除 % 后转数字
      └─ 返回结构化数组
            │
            ▼  JSON 输出:
      {"nodes":[{"name":"xxx","cpu":"276m","cpuPct":27,"mem":"3205Mi","memPct":82},...]}
```

> **设计决策**: 使用结构化 JSON 而非原始文本的原因是 `http.write_json` 内部使用 `printf` 序列化，`%` 字符会被当作格式说明符处理导致数据丢失。

### 4.4 YAML Apply 实现

```lua
function action_apply()
    local yaml_content = http.formvalue("yaml")
    -- 写入临时文件
    local tmpfile = "/tmp/luci-k8s-apply-" .. tostring(math.random(10000))
    local f = io.open(tmpfile, "w")
    f:write(yaml_content); f:close()

    -- 执行 kubectl apply
    local cmd = "KUBECONFIG=" .. KUBECONFIG .. " kubectl apply -f " .. tmpfile .. " 2>&1"
    local output = exec_cmd(cmd)

    -- 清理临时文件
    os.remove(tmpfile)

    http.prepare_content("application/json")
    http.write_json({message = "applied", detail = output})
end
```

---

## 5. API 接口规格

### 5.1 数据查询接口

所有数据接口基础路径: `/cgi-bin/luci/admin/services/kubernetes/`

| 端点 | 方法 | 参数 | 返回 | 说明 |
|------|------|------|------|------|
| `k8s_nodes` | GET | - | JSON (NodeList) | 获取节点列表 |
| `k8s_namespaces` | GET | - | JSON (NamespaceList) | 获取命名空间列表 |
| `k8s_pods` | GET | `namespace` (可选) | JSON (PodList) | 获取 Pod 列表，不传则全部命名空间 |
| `k8s_deployments` | GET | `namespace` (可选) | JSON (DeploymentList) | 获取部署列表 |
| `k8s_statefulsets` | GET | `namespace` (可选) | JSON (StatefulSetList) | 获取有状态集列表 |
| `k8s_daemonsets` | GET | `namespace` (可选) | JSON (DaemonSetList) | 获取守护进程集列表 |
| `k8s_jobs` | GET | `namespace` (可选) | JSON (JobList) | 获取任务列表 |
| `k8s_cronjobs` | GET | `namespace` (可选) | JSON (CronJobList) | 获取定时任务列表 |
| `k8s_services` | GET | `namespace` (可选) | JSON (ServiceList) | 获取服务列表 |
| `k8s_ingresses` | GET | `namespace` (可选) | JSON (IngressList) | 获取入口列表 |
| `k8s_configmaps` | GET | `namespace` (可选) | JSON (ConfigMapList) | 获取配置映射列表 |
| `k8s_secrets` | GET | `namespace` (可选) | JSON (SecretList) | 获取密钥列表 |
| `k8s_pvcs` | GET | `namespace` (可选) | JSON (PVCList) | 获取持久卷声明列表 |
| `k8s_pvs` | GET | - | JSON (PVList) | 获取持久卷列表 |
| `k8s_storageclasses` | GET | - | JSON (StorageClassList) | 获取存储类列表 |
| `k8s_events` | GET | `namespace` (可选) | JSON (EventList) | 获取事件列表（按时间排序） |
| `k8s_resources` | GET | `namespace` (可选) | JSON `{nodes, pods}` | 获取资源使用情况（原始文本） |
| `k8s_top_nodes` | GET | - | JSON `{nodes: [...]}` | 获取节点资源指标（结构化） |

### 5.2 操作接口

| 端点 | 方法 | 参数 | 返回 | 说明 |
|------|------|------|------|------|
| `k8s_yaml` | GET | `kind`, `name`, `namespace` (可选) | text/plain | 获取资源 YAML |
| `k8s_describe` | GET | `kind`, `name`, `namespace` (可选) | text/plain | 描述资源详情 |
| `k8s_logs` | GET | `name`, `namespace` (可选), `tail` (默认200) | text/plain | 获取 Pod 日志 |
| `k8s_delete` | GET | `kind`, `name`, `namespace` (可选) | JSON | 删除资源 |
| `k8s_scale` | GET | `kind`, `name`, `replicas`, `namespace` (可选) | JSON | 伸缩副本数 |
| `k8s_restart` | GET | `kind`, `name`, `namespace` (可选) | JSON | 重启部署 |
| `k8s_apply` | POST | `yaml` (form body) | JSON | 应用 YAML 配置 |
| `k8s_exec` | GET | `pod`, `command`, `container` (可选), `namespace` (可选) | text/plain | Pod 内执行命令 |
| `k8s_containers` | GET | `pod`, `namespace` (可选) | JSON (Pod) | 获取 Pod 容器列表 |

### 5.3 请求/响应示例

#### 获取 Pod 列表

```
GET /cgi-bin/luci/admin/services/kubernetes/k8s_pods?namespace=default
```

```json
{
  "apiVersion": "v1",
  "kind": "List",
  "items": [
    {
      "metadata": {
        "name": "nginx-xxx",
        "namespace": "default",
        "creationTimestamp": "2026-06-20T10:00:00Z"
      },
      "spec": {
        "nodeName": "worker-1",
        "containers": [...]
      },
      "status": {
        "phase": "Running",
        "podIP": "10.244.0.5",
        "containerStatuses": [...]
      }
    }
  ]
}
```

#### 获取节点资源指标

```
GET /cgi-bin/luci/admin/services/kubernetes/k8s_top_nodes
```

```json
{
  "nodes": [
    {
      "name": "cn-chengdu.192.168.31.225",
      "cpu": "276m",
      "cpuPct": 27,
      "mem": "3205Mi",
      "memPct": 82
    }
  ]
}
```

#### 应用 YAML

```
POST /cgi-bin/luci/admin/services/kubernetes/k8s_apply
Content-Type: application/x-www-form-urlencoded

yaml=apiVersion: apps/v1%0Akind: Deployment%0Ametadata:%0A  name: my-app
```

```json
{
  "message": "applied",
  "detail": "deployment.apps/my-app configured\n"
}
```

---

## 6. 数据流设计

### 6.1 请求/响应流程

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
  │  GET /admin/.../k8s_delete              │  kubectl delete pod <name>              │
  │ ──────────────────────────────────────► │ ──────────────────────────────────────► │
  │  8. 刷新数据                            │                                         │
  │  GET /admin/.../k8s_pods               │                                         │
  │ ──────────────────────────────────────► │                                         │
```

### 6.2 kubeconfig 配置

```
/root/.kube/config  ← 当前使用的 kubeconfig（硬编码于 kubernetes.lua）

注：当前版本 kubeconfig 路径硬编码，不支持动态切换。
```

---

## 7. 构建与部署

### 7.1 Makefile 配置

```makefile
include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Kubernetes Management Plugin
LUCI_DEPENDS:=+curl +jq
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-kubernetes
PKG_VERSION:=0.0.2
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk
```

### 7.2 GitHub Actions CI/CD

```yaml
触发条件:
  - push: main/master 分支
  - push: v* 标签
  - pull_request: main/master 分支

构建矩阵:
  - x86_64 (OpenWrt 23.05.5 SDK)

流程:
  1. checkout 代码
  2. 下载 OpenWrt SDK
  3. 更新 feeds
  4. 链接包到 feeds 目录
  5. 编译 IPK
  6. 上传 artifact
  7. (Tag 触发) 创建 GitHub Release 并上传 IPK
```

### 7.3 安装方式

| 方式 | 命令 |
|------|------|
| IPK 安装 | `opkg install luci-app-kubernetes_*.ipk` |
| SDK 编译 | `make package/feeds/luci/luci-app-kubernetes/compile` |
| 手动安装 | 复制 `luasrc/*` → `/usr/lib/lua/luci/`，复制 `root/*` → `/` |

安装后需清除缓存：
```bash
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*
/etc/init.d/rpcd restart
```

---

## 8. 配置说明

### 8.1 UCI 配置（当前未使用）

> 注意：以下 UCI 配置虽然存在于 `root/etc/config/kubernetes`，但当前代码中并未读取。kubeconfig 路径硬编码于 `kubernetes.lua` 中。

```
config global 'config'
    option enabled '1'
    option kubeconfig '/etc/kubernetes/admin.conf'
    option default_namespace 'default'
    option refresh_interval '15'
```

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `enabled` | `1` | 是否启用插件（未使用） |
| `kubeconfig` | `/etc/kubernetes/admin.conf` | K8s 集群配置文件路径（未使用） |
| `default_namespace` | `default` | 默认命名空间（未使用） |
| `refresh_interval` | `15` | 自动刷新间隔（秒，未使用） |

### 8.2 硬编码配置（kubernetes.lua）

```lua
local KUBECONFIG = "/root/.kube/config"  -- 当前实际使用的 kubeconfig 路径
```

### 8.3 前置条件

| 条件 | 说明 |
|------|------|
| kubectl 已安装 | 在路由器 PATH 中可访问 |
| kubeconfig 文件存在 | 路径 `/root/.kube/config` |
| 网络连通 | 路由器可访问 K8s API Server |
| metrics-server | 部署在 K8s 集群中（资源监控功能需要） |

---

## 9. 依赖关系

### 9.1 系统依赖

| 包名 | 用途 | 必需 |
|------|------|------|
| `kubectl` | Kubernetes CLI 工具，所有数据操作的执行引擎 | 是 |
| `curl` | HTTP 请求（LuCI 框架依赖） | 是 |
| `jq` | JSON 解析（LuCI 框架依赖） | 是 |

### 9.2 LuCI 依赖

| 模块 | 用途 |
|------|------|
| `luci.model.uci` | 读取/写入 UCI 配置 |
| `luci.http` | HTTP 请求/响应处理 |
| `luci.dispatcher` | URL 路由分发 |
| `luci.template` | 模板渲染 |
| `luci.controller.*` | Controller 基模块 |

---

## 10. 已知问题与限制

### 10.1 当前已知问题

| 问题 | 说明 | 状态 |
|------|------|------|
| kubeconfig 路径不一致 | UCI 配置为 `/etc/kubernetes/admin.conf`，代码硬编码为 `/root/.kube/config` | 待修复 |
| UCI 配置未使用 | `root/etc/config/kubernetes` 存在但代码未读取 | 待修复 |
| 旧版页面未清理 | `view/kubernetes/` 下存在大量旧版独立页面 .htm 文件，已不再被路由引用 | 待清理 |
| k8s-common.js 未使用 | 共享 JS 库文件仅被旧版页面引用，SPA 主页面使用内联 JS | 待清理 |
| Pod exec 非交互式 | `kubectl exec -it` 在 HTTP 上下文中无法真正交互式，每次执行独立命令 | 设计限制 |
| 资源监控原始文本 | `k8s_resources` 接口返回原始文本，前端需自行解析 | 待优化 |
| 无自动刷新 | UCI 配置了 `refresh_interval` 但前端未实现自动刷新 | 待实现 |
| 多集群切换未实现 | 无 kubeconfig 切换功能，无 settings 页面 | 待实现 |
| 标签/配额管理未实现 | 命名空间页面配置了 label/quota 操作按钮，但功能通过 exec 端点间接实现 | 部分实现 |

### 10.2 设计限制

| 限制 | 原因 |
|------|------|
| 无 WebSocket | LuCI 框架不支持 WebSocket，终端为模拟实现 |
| 无 RBAC | 依赖 kubeconfig 中的权限，插件本身不做权限控制 |
| 无审计日志 | 操作不记录审计日志 |
| 单集群 | 同一时刻只能查看一个集群，kubeconfig 路径硬编码 |
| YAML 编辑器无语法校验 | 纯文本编辑，提交后才由 kubectl 校验 |

---

## 11. 版本历史

### v0.0.2 (2026-06-23)

**Bug 修复**
- 修复节点页面"按量付费"文字显示（非云环境改为 `-`）
- 修复容器组列显示 allocatable/capacity（固定 110）的问题，改为实际已运行数/总配额
- 修复 CPU/内存请求值为空的问题，改为从 Pod resources.requests 汇总计算
- 修复节点资源百分比显示为 0% 的问题（`http.write_json` 对 `%` 字符的转义 bug）
- 修复 GitHub Actions 创建 Release 权限不足的问题（添加 `contents: write`）

### v0.0.1 (2026-06-22)

**初始版本**
- 集群总览仪表盘
- 节点管理（状态、版本、资源）
- 工作负载管理（Pods/Deployments/StatefulSets/DaemonSets/Jobs/CronJobs）
- 网络管理（Services/Ingresses）
- 配置与存储（ConfigMaps/Secrets/PVC/PV/StorageClasses）
- 事件查看 / 资源监控
- YAML 查看/编辑/应用
- Pod 终端
- Kubeconfig 切换
- GitHub Actions 自动构建 IPK
