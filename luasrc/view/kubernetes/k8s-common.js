/*
 * k8s-common.js - 共享 JavaScript 库
 * 用于 LuCI Kubernetes 管理插件
 */

// K8S_BASE is defined in each .htm file before loading this script

function fetchK8sAPI(action) {
    return fetch(K8S_BASE + '/' + action).then(function(r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        var ct = r.headers.get('Content-Type') || '';
        if (ct.indexOf('json') >= 0) return r.json();
        return r.text().then(function(t) { return { text: t }; });
    });
}

function postK8sAPI(action, params) {
    var qs = Object.keys(params).map(function(k) {
        return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
    }).join('&');
    return fetch(K8S_BASE + '/' + action + '?' + qs, { method: 'POST' }).then(function(r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
    });
}

function deleteK8sAPI(action, params) {
    var qs = Object.keys(params).map(function(k) {
        return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
    }).join('&');
    return fetch(K8S_BASE + '/' + action + '?' + qs, { method: 'DELETE' }).then(function(r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
    });
}

function escHtml(str) {
    if (!str) return '';
    var d = document.createElement('div');
    d.appendChild(document.createTextNode(str));
    return d.innerHTML;
}

function ageSince(timestamp) {
    if (!timestamp) return '-';
    var now = Date.now();
    var created = new Date(timestamp).getTime();
    var diff = Math.max(0, now - created);
    var secs = Math.floor(diff / 1000);
    if (secs < 60) return secs + 's';
    var mins = Math.floor(secs / 60);
    if (mins < 60) return mins + 'm';
    var hours = Math.floor(mins / 60);
    if (hours < 24) return hours + 'h';
    var days = Math.floor(hours / 24);
    if (days < 365) return days + 'd';
    return Math.floor(days / 365) + 'y';
}

function getNamespace(item) {
    return (item.metadata && item.metadata.namespace) ? item.metadata.namespace : '';
}

function getName(item) {
    return (item.metadata && item.metadata.name) ? item.metadata.name : '';
}

function getAge(item) {
    return (item.metadata && item.metadata.creationTimestamp) ? ageSince(item.metadata.creationTimestamp) : '-';
}

function showStatus(type, msg) {
    var el = document.getElementById('statusMsg');
    if (!el) return;
    el.textContent = msg;
    el.className = type === 'error' ? 'status-error' : 'status-ok';
    el.style.display = 'block';
    setTimeout(function() { el.style.display = 'none'; }, 5000);
}

function showModal(title, content) {
    var overlay = document.getElementById('modalOverlay');
    var titleEl = document.getElementById('modalTitle');
    var bodyEl = document.getElementById('modalBody');
    if (!overlay || !titleEl || !bodyEl) return;
    titleEl.textContent = title;
    bodyEl.innerHTML = content;
    overlay.style.display = 'flex';
}

function closeModal() {
    var overlay = document.getElementById('modalOverlay');
    if (overlay) overlay.style.display = 'none';
}

document.addEventListener('DOMContentLoaded', function() {
    var overlay = document.getElementById('modalOverlay');
    if (overlay) {
        overlay.addEventListener('click', function(e) {
            if (e.target === overlay) closeModal();
        });
    }
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeModal();
    });
});
