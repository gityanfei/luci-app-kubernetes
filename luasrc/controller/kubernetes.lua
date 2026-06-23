--[[
LuCI - Kubernetes Management Plugin (Unified SPA)
]]--

local uci = require "luci.model.uci".cursor()
local http = require "luci.http"

module("luci.controller.kubernetes", package.seeall)

function index()
    -- Unified SPA entry
    entry({"admin", "services", "kubernetes"}, alias("admin", "services", "kubernetes", "app"), _("Kubernetes"), 60).dependent = true
    entry({"admin", "services", "kubernetes", "app"}, template("kubernetes/main"), _("管理"), 1)

    -- Old individual pages (redirect to SPA)
    entry({"admin", "services", "kubernetes", "nodes"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "namespaces"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "pods"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "deployments"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "statefulsets"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "daemonsets"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "jobs"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "cronjobs"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "services"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "ingresses"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "configmaps"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "secrets"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "pvcs"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "pvs"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "storageclasses"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "events"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "resources"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "overview"}, alias("admin", "services", "kubernetes", "app")).dependent = false
    entry({"admin", "services", "kubernetes", "settings"}, alias("admin", "services", "kubernetes", "app")).dependent = false

    -- API endpoints
    entry({"admin", "services", "kubernetes", "k8s_nodes"}, call("action_nodes")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_namespaces"}, call("action_namespaces")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_pods"}, call("action_pods")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_deployments"}, call("action_deployments")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_statefulsets"}, call("action_statefulsets")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_daemonsets"}, call("action_daemonsets")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_jobs"}, call("action_jobs")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_cronjobs"}, call("action_cronjobs")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_services"}, call("action_services")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_ingresses"}, call("action_ingresses")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_configmaps"}, call("action_configmaps")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_secrets"}, call("action_secrets")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_pvcs"}, call("action_pvcs")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_pvs"}, call("action_pvs")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_storageclasses"}, call("action_storageclasses")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_events"}, call("action_events")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_resources"}, call("action_resources")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_logs"}, call("action_logs")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_describe"}, call("action_describe")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_delete"}, call("action_delete")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_scale"}, call("action_scale")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_restart"}, call("action_restart")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_apply"}, call("action_apply")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_yaml"}, call("action_yaml")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_exec"}, call("action_exec")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_containers"}, call("action_containers")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_top_nodes"}, call("action_top_nodes")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_settings"}, call("action_settings")).leaf = true
    entry({"admin", "services", "kubernetes", "k8s_settings_save"}, call("action_settings_save")).leaf = true
end

local function exec_cmd(cmd)
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()
    return output
end

local CONFIG_FILE = "/etc/kubernetes/k8s-ui-config.json"

local function read_config()
    local f = io.open(CONFIG_FILE, "r")
    if not f then
        local default = {kubeconfig="/etc/kubernetes/admin.conf", history={"/etc/kubernetes/admin.conf"}}
        return default
    end
    local content = f:read("*a")
    f:close()
    if content == "" then
        local default = {kubeconfig="/etc/kubernetes/admin.conf", history={"/etc/kubernetes/admin.conf"}}
        return default
    end
    local ok, cfg = pcall(function() return loadstring("return " .. content)() end)
    if not ok or not cfg then
        return {kubeconfig="/etc/kubernetes/admin.conf", history={"/etc/kubernetes/admin.conf"}}
    end
    return cfg
end

local function write_config(cfg)
    local f = io.open(CONFIG_FILE, "w")
    if not f then return false end
    -- Check if table is array-like (sequential integer keys starting from 1)
    local function is_array(t)
        local n = 0
        for k, v in pairs(t) do n = n + 1 end
        for i = 1, n do if t[i] == nil then return false end end
        return true
    end
    local function serialize(val)
        if type(val) == "table" then
            if is_array(val) then
                local parts = {}
                for _, v in ipairs(val) do table.insert(parts, serialize(v)) end
                return "{ " .. table.concat(parts, ", ") .. " }"
            else
                local parts = {}
                for k, v in pairs(val) do
                    -- Check if key is a valid Lua identifier
                    if type(k) == "string" and k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                        table.insert(parts, k .. " = " .. serialize(v))
                    else
                        table.insert(parts, "[" .. serialize(k) .. "] = " .. serialize(v))
                    end
                end
                return "{ " .. table.concat(parts, ", ") .. " }"
            end
        elseif type(val) == "string" then
            return string.format("%q", val)
        elseif type(val) == "nil" then
            return "nil"
        else
            return tostring(val)
        end
    end
    f:write("return " .. serialize(cfg, 0))
    f:close()
    return true
end

local function get_kubeconfig()
    local cfg = read_config()
    return cfg.kubeconfig or "/etc/kubernetes/admin.conf"
end

local function run_kubectl(args, ns, as_json)
    local kubeconfig = get_kubeconfig()
    local cmd = "KUBECONFIG=" .. kubeconfig .. " kubectl"
    if ns and ns ~= "" and ns ~= "all" then
        cmd = cmd .. " -n " .. ns
    end
    if type(args) == "table" then
        for _, arg in ipairs(args) do
            cmd = cmd .. " " .. arg
        end
    else
        cmd = cmd .. " " .. args
    end
    if as_json then
        cmd = cmd .. " -o json"
    end
    cmd = cmd .. " 2>/dev/null"
    return exec_cmd(cmd)
end

local function get_ns()
    return http.formvalue("namespace") or ""
end

-- Data actions
function action_nodes()
    local output = run_kubectl({"get", "nodes"}, nil, true)
    http.prepare_content("application/json")
    http.write(output ~= "" and output or "{}")
end
function action_namespaces()
    local output = run_kubectl({"get", "namespaces"}, nil, true)
    http.prepare_content("application/json")
    http.write(output ~= "" and output or "{}")
end
function action_pods()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "pods"}, ns, true) or run_kubectl({"get", "pods", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_deployments()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "deployments"}, ns, true) or run_kubectl({"get", "deployments", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_statefulsets()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "statefulsets"}, ns, true) or run_kubectl({"get", "statefulsets", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_daemonsets()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "daemonsets"}, ns, true) or run_kubectl({"get", "daemonsets", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_jobs()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "jobs"}, ns, true) or run_kubectl({"get", "jobs", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_cronjobs()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "cronjobs"}, ns, true) or run_kubectl({"get", "cronjobs", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_services()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "services"}, ns, true) or run_kubectl({"get", "services", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_ingresses()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "ingresses"}, ns, true) or run_kubectl({"get", "ingresses", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_configmaps()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "configmaps"}, ns, true) or run_kubectl({"get", "configmaps", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_secrets()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "secrets"}, ns, true) or run_kubectl({"get", "secrets", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_pvcs()
    local ns = get_ns()
    local output = ns ~= "" and ns ~= "all" and run_kubectl({"get", "pvc"}, ns, true) or run_kubectl({"get", "pvc", "--all-namespaces"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_pvs()
    local output = run_kubectl({"get", "pv"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_storageclasses()
    local output = run_kubectl({"get", "sc"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_events()
    local ns = get_ns()
    local cmd = {"get", "events", "--sort-by=.metadata.creationTimestamp"}
    local output = ns ~= "" and ns ~= "all" and run_kubectl(cmd, ns, true) or run_kubectl({"get", "events", "--all-namespaces", "--sort-by=.metadata.creationTimestamp"}, nil, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end
function action_resources()
    local ns = get_ns()
    local nodes_out = run_kubectl({"top", "nodes", "--no-headers"}, nil, false)
    local pods_out = ns ~= "" and ns ~= "all" and run_kubectl({"top", "pods", "--no-headers"}, ns, false) or run_kubectl({"top", "pods", "--all-namespaces", "--no-headers"}, nil, false)
    http.prepare_content("application/json")
    http.write_json({nodes = nodes_out, pods = pods_out})
end

-- Utility actions
function action_logs()
    local ns = get_ns()
    local name = http.formvalue("name") or ""
    local tail = http.formvalue("tail") or "200"
    if name == "" then http.write_json({error = "name required"}); return end
    local output = run_kubectl({"logs", name, "--tail=" .. tail}, ns, false)
    http.prepare_content("text/plain"); http.write(output)
end
function action_describe()
    local ns = get_ns()
    local kind = http.formvalue("kind") or ""
    local name = http.formvalue("name") or ""
    if kind == "" or name == "" then http.write_json({error = "kind and name required"}); return end
    local output = run_kubectl({"describe", kind, name}, ns, false)
    http.prepare_content("text/plain"); http.write(output)
end
function action_delete()
    local ns = get_ns()
    local kind = http.formvalue("kind") or ""
    local name = http.formvalue("name") or ""
    if kind == "" or name == "" then http.write_json({error = "kind and name required"}); return end
    local output = run_kubectl({"delete", kind, name}, ns, false)
    http.prepare_content("application/json"); http.write_json({message = "deleted", detail = output})
end
function action_scale()
    local ns = get_ns()
    local kind = http.formvalue("kind") or ""
    local name = http.formvalue("name") or ""
    local replicas = http.formvalue("replicas") or ""
    if kind == "" or name == "" or replicas == "" then http.write_json({error = "kind, name and replicas required"}); return end
    local output = run_kubectl({"scale", kind, name, "--replicas=" .. replicas}, ns, false)
    http.prepare_content("application/json"); http.write_json({message = "scaled", detail = output})
end
function action_restart()
    local ns = get_ns()
    local kind = http.formvalue("kind") or ""
    local name = http.formvalue("name") or ""
    if kind == "" or name == "" then http.write_json({error = "kind and name required"}); return end
    local output = run_kubectl({"rollout", "restart", kind, name}, ns, false)
    http.prepare_content("application/json"); http.write_json({message = "restarted", detail = output})
end
function action_apply()
    local yaml_content = http.formvalue("yaml")
    if not yaml_content or yaml_content == "" then http.write_json({error = "yaml required"}); return end
    local tmpfile = "/tmp/luci-k8s-apply-" .. tostring(math.random(10000))
    local f = io.open(tmpfile, "w")
    if not f then http.write_json({error = "cannot create temp file"}); return end
    f:write(yaml_content); f:close()
    local kubeconfig = get_kubeconfig()
    local cmd = "KUBECONFIG=" .. kubeconfig .. " kubectl apply -f " .. tmpfile .. " 2>&1"
    local output = exec_cmd(cmd); os.remove(tmpfile)
    http.prepare_content("application/json"); http.write_json({message = "applied", detail = output})
end

-- YAML view
function action_yaml()
    local ns = get_ns()
    local kind = http.formvalue("kind") or ""
    local name = http.formvalue("name") or ""
    if kind == "" or name == "" then http.write_json({error = "kind and name required"}); return end
    local output = run_kubectl({"get", kind, name, "-o", "yaml"}, ns, false)
    http.prepare_content("text/plain"); http.write(output)
end

-- Pod exec
function action_exec()
    local ns = get_ns()
    local pod = http.formvalue("pod") or ""
    local container = http.formvalue("container") or ""
    local command = http.formvalue("command") or "/bin/sh"
    if pod == "" then http.write_json({error = "pod name required"}); return end
    local args = {"exec", "-it"}
    if ns ~= "" and ns ~= "all" then args[#args+1] = "-n"; args[#args+1] = ns end
    if container ~= "" then args[#args+1] = "-c"; args[#args+1] = container end
    args[#args+1] = pod; args[#args+1] = "--"; args[#args+1] = command
    local kubeconfig = get_kubeconfig()
    local cmd = "KUBECONFIG=" .. kubeconfig .. " kubectl"
    for _, arg in ipairs(args) do cmd = cmd .. " " .. arg end
    cmd = cmd .. " 2>&1"
    local output = exec_cmd(cmd)
    http.prepare_content("text/plain"); http.write(output)
end

-- Pod containers list
function action_containers()
    local ns = get_ns()
    local pod = http.formvalue("pod") or ""
    if pod == "" then http.write_json({error = "pod name required"}); return end
    local output = run_kubectl({"get", "pod", pod}, ns, true)
    http.prepare_content("application/json"); http.write(output ~= "" and output or "{}")
end

-- Top nodes
function action_top_nodes()
    local output = exec_cmd("KUBECONFIG=" .. get_kubeconfig() .. " kubectl top nodes --no-headers 2>/dev/null")
    local nodes = {}
    for line in output:gmatch('[^\n]+') do
        line = line:gsub('^%s+', ''):gsub('%s+$', '')
        if line ~= '' then
            local f = {}
            for word in line:gmatch('%S+') do
                table.insert(f, word)
            end
            if #f >= 5 then
                table.insert(nodes, {
                    name = f[1],
                    cpu = f[2],
                    cpuPct = tonumber((f[3]:gsub('%%', ''))) or 0,
                    mem = f[4],
                    memPct = tonumber((f[5]:gsub('%%', ''))) or 0
                })
            end
        end
    end
    http.prepare_content("application/json")
    http.write_json({nodes = nodes})
end

-- Settings: get current config and history
function action_settings()
    local cfg = read_config()
    http.prepare_content("application/json")
    http.write_json({kubeconfig = cfg.kubeconfig or "/etc/kubernetes/admin.conf", history = cfg.history or {"/etc/kubernetes/admin.conf"}})
end

-- Settings: save kubeconfig path
function action_settings_save()
    local new_kc = http.formvalue("kubeconfig") or ""
    if new_kc == "" then http.write_json({error = "kubeconfig path required"}); return end
    local cfg = read_config()
    local hist = cfg.history or {}
    local new_hist = {}
    table.insert(new_hist, new_kc)
    for _, h in ipairs(hist) do
        if h ~= new_kc then table.insert(new_hist, h) end
    end
    while #new_hist > 20 do table.remove(new_hist) end
    cfg.kubeconfig = new_kc
    cfg.history = new_hist
    write_config(cfg)
    http.prepare_content("application/json")
    http.write_json({ok = true, kubeconfig = new_kc, history = new_hist})
end
