/* ==========================================================
   DPS Clothing Browser — Utilities
   ========================================================== */

/**
 * Send a NUI callback to the Lua client.
 * @param {string} name  Callback name registered in Lua
 * @param {object} data  Payload
 * @returns {Promise<any>}
 */
function fetchNUI(name, data = {}) {
    return fetch(`https://dps-clothingbrowser/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

/**
 * Debounce a function.
 * @param {Function} fn
 * @param {number} ms
 * @returns {Function}
 */
function debounce(fn, ms) {
    let timer;
    return function (...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), ms);
    };
}

/**
 * Copy text to clipboard via execCommand (FiveM CEF blocks the Clipboard API).
 * @param {string} text
 * @returns {boolean}
 */
function copyToClipboard(text) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    let ok = false;
    try { ok = document.execCommand('copy'); } catch { /* noop */ }
    document.body.removeChild(ta);
    return ok;
}

/**
 * Escape HTML entities.
 * @param {string} str
 * @returns {string}
 */
function escapeHtml(str) {
    const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
    return String(str).replace(/[&<>"']/g, c => map[c]);
}

/**
 * Show a toast notification.
 * @param {string} message
 * @param {'success'|'error'|'info'} type
 * @param {number} duration  ms
 */
function showToast(message, type = 'info', duration = 3000) {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = message;
    el.style.animationDuration = '200ms, 200ms';
    el.style.animationDelay = `0ms, ${duration - 200}ms`;
    container.appendChild(el);

    setTimeout(() => el.remove(), duration);
}
