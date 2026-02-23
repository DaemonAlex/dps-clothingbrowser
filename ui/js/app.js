/* ==========================================================
   DPS Clothing Browser v2.0 — ClothingBrowser Singleton
   ========================================================== */

const ClothingBrowser = (() => {
    // ── State ──────────────────────────────────────────────
    let isOpen = false;
    let activeTab = 'components';
    let selectedSlot = null;      // { type: 'component'|'prop', id: number }
    let browseState = null;       // { drawable, texture, maxDrawable, maxTexture }
    let savedPieces = { components: {}, props: {} };
    let model = 'male';
    let exportData = null;        // outfit data for the export modal

    // Slot metadata (populated on open)
    let slotMeta = { components: {}, props: {} };

    // ── DOM refs ───────────────────────────────────────────
    const $ = id => document.getElementById(id);
    const app          = $('app');
    const modelBadge   = $('model-badge');
    const slotGrid     = $('slot-grid');
    const browseCtrl   = $('browse-controls');
    const browseSlotName = $('browse-slot-name');
    const drawableDisp = $('drawable-display');
    const textureDisp  = $('texture-display');
    const jumpInput    = $('jump-input');
    const savedCountEl = $('saved-count');
    const outfitList   = $('outfit-list');
    const btnClearAll  = $('btn-clear-all');
    const exportModal  = $('export-modal');
    const exportPreview = $('export-preview');

    // ── Slot definitions ───────────────────────────────────
    const COMPONENT_SLOTS = [
        { id: 0,  name: 'Face' },
        { id: 1,  name: 'Mask' },
        { id: 2,  name: 'Hair' },
        { id: 3,  name: 'Arms/Torso' },
        { id: 4,  name: 'Pants' },
        { id: 5,  name: 'Bag' },
        { id: 6,  name: 'Shoes' },
        { id: 7,  name: 'Accessories' },
        { id: 8,  name: 'Undershirt' },
        { id: 9,  name: 'Body Armor' },
        { id: 10, name: 'Decals/Badge' },
        { id: 11, name: 'Tops' },
    ];

    const PROP_SLOTS = [
        { id: 0, name: 'Hats' },
        { id: 1, name: 'Glasses' },
        { id: 2, name: 'Ears' },
        { id: 6, name: 'Watches' },
        { id: 7, name: 'Bracelets' },
    ];

    // ── Rendering ──────────────────────────────────────────
    function renderSlotGrid() {
        const slots = activeTab === 'components' ? COMPONENT_SLOTS : PROP_SLOTS;
        const type  = activeTab === 'components' ? 'component' : 'prop';
        const meta  = activeTab === 'components' ? slotMeta.components : slotMeta.props;
        const saved = activeTab === 'components' ? savedPieces.components : savedPieces.props;

        slotGrid.innerHTML = slots.map(s => {
            const m = meta[s.id] || {};
            const isSaved = saved[s.id] !== undefined;
            const isActive = selectedSlot && selectedSlot.type === type && selectedSlot.id === s.id;
            const valueText = m.drawable !== undefined ? `${m.drawable}:${m.texture}` : '--';

            return `<button class="slot-btn${isActive ? ' active' : ''}${isSaved ? ' saved' : ''}"
                            data-type="${type}" data-id="${s.id}">
                        <span class="saved-dot"></span>
                        <span class="slot-name">${escapeHtml(s.name)}</span>
                        <span class="slot-value">${valueText}</span>
                    </button>`;
        }).join('');
    }

    function renderBrowseControls() {
        if (!browseState || !selectedSlot) {
            browseCtrl.classList.add('hidden');
            return;
        }
        browseCtrl.classList.remove('hidden');

        const slots = selectedSlot.type === 'component' ? COMPONENT_SLOTS : PROP_SLOTS;
        const slotDef = slots.find(s => s.id === selectedSlot.id);
        browseSlotName.textContent = slotDef ? slotDef.name : `Slot ${selectedSlot.id}`;
        drawableDisp.textContent = `${browseState.drawable} / ${browseState.maxDrawable}`;
        textureDisp.textContent  = `${browseState.texture} / ${browseState.maxTexture}`;
    }

    function renderOutfitList() {
        const items = [];

        for (const [id, data] of Object.entries(savedPieces.components)) {
            const slot = COMPONENT_SLOTS.find(s => s.id === parseInt(id));
            items.push({
                type: 'component',
                id: parseInt(id),
                name: slot ? slot.name : `Comp ${id}`,
                drawable: data.drawable,
                texture: data.texture,
            });
        }
        for (const [id, data] of Object.entries(savedPieces.props)) {
            const slot = PROP_SLOTS.find(s => s.id === parseInt(id));
            items.push({
                type: 'prop',
                id: parseInt(id),
                name: slot ? slot.name : `Prop ${id}`,
                drawable: data.drawable,
                texture: data.texture,
            });
        }

        const count = items.length;
        savedCountEl.textContent = `(${count})`;
        btnClearAll.classList.toggle('hidden', count === 0);

        if (count === 0) {
            outfitList.innerHTML = '<div class="empty-state">No pieces saved yet</div>';
            return;
        }

        // Sort: components first (by id), then props (by id)
        items.sort((a, b) => {
            if (a.type !== b.type) return a.type === 'component' ? -1 : 1;
            return a.id - b.id;
        });

        outfitList.innerHTML = items.map(it => `
            <div class="outfit-item" data-type="${it.type}" data-id="${it.id}">
                <div class="outfit-item-info">
                    <span class="outfit-item-name">${escapeHtml(it.name)}</span>
                    <span class="outfit-item-value">${it.type === 'component' ? 'Comp' : 'Prop'} ${it.id} &mdash; ${it.drawable}:${it.texture}</span>
                </div>
                <button class="btn-remove" title="Remove">&times;</button>
            </div>
        `).join('');
    }

    function renderAll() {
        renderSlotGrid();
        renderBrowseControls();
        renderOutfitList();
    }

    // ── Export Modal ────────────────────────────────────────
    function buildExportJSON() {
        const label  = $('export-label').value || 'Unnamed Outfit';
        const job    = $('export-job').value;
        const grades = $('export-grades').value;

        const obj = { label, model: model === 'male' ? 'mp_m_freemode_01' : 'mp_f_freemode_01' };
        if (job) obj.job = job;
        if (grades) {
            obj.grades = grades.split(',').map(g => parseInt(g.trim())).filter(g => !isNaN(g));
        }

        if (exportData) {
            obj.components = exportData.components || [];
            obj.props = exportData.props || [];
        }

        return JSON.stringify(obj, null, 2);
    }

    function updateExportPreview() {
        exportPreview.textContent = buildExportJSON();
    }

    function openExportModal(data) {
        exportData = data;
        $('export-label').value = '';
        $('export-job').value = '';
        $('export-grades').value = '';
        updateExportPreview();
        exportModal.classList.remove('hidden');
    }

    function closeExportModal() {
        exportModal.classList.add('hidden');
        exportData = null;
    }

    // ── Actions ────────────────────────────────────────────
    async function selectSlot(type, id) {
        selectedSlot = { type, id };
        const result = await fetchNUI('selectSlot', { type, id });
        if (result) {
            browseState = {
                drawable: result.drawable,
                texture: result.texture,
                maxDrawable: result.maxDrawable,
                maxTexture: result.maxTexture,
            };
            // Update slotMeta with current values
            const metaGroup = type === 'component' ? slotMeta.components : slotMeta.props;
            metaGroup[id] = { drawable: result.drawable, texture: result.texture };
        }
        renderAll();
    }

    async function changeDrawable(delta) {
        if (!selectedSlot) return;
        const result = await fetchNUI('changeDrawable', { delta });
        if (result) {
            browseState = {
                drawable: result.drawable,
                texture: result.texture,
                maxDrawable: result.maxDrawable,
                maxTexture: result.maxTexture,
            };
            const metaGroup = selectedSlot.type === 'component' ? slotMeta.components : slotMeta.props;
            metaGroup[selectedSlot.id] = { drawable: result.drawable, texture: result.texture };
            renderAll();
        }
    }

    async function changeTexture(delta) {
        if (!selectedSlot) return;
        const result = await fetchNUI('changeTexture', { delta });
        if (result) {
            browseState.texture = result.texture;
            browseState.maxTexture = result.maxTexture;
            const metaGroup = selectedSlot.type === 'component' ? slotMeta.components : slotMeta.props;
            metaGroup[selectedSlot.id] = { drawable: browseState.drawable, texture: result.texture };
            renderAll();
        }
    }

    async function jumpToDrawable() {
        const val = parseInt(jumpInput.value);
        if (isNaN(val) || val < 0 || !selectedSlot) return;
        const result = await fetchNUI('jumpToDrawable', { drawable: val });
        if (result) {
            browseState = {
                drawable: result.drawable,
                texture: result.texture,
                maxDrawable: result.maxDrawable,
                maxTexture: result.maxTexture,
            };
            const metaGroup = selectedSlot.type === 'component' ? slotMeta.components : slotMeta.props;
            metaGroup[selectedSlot.id] = { drawable: result.drawable, texture: result.texture };
            renderAll();
        }
        jumpInput.value = '';
        jumpInput.blur();
    }

    async function savePiece() {
        if (!selectedSlot || !browseState) return;
        const result = await fetchNUI('savePiece', {
            type: selectedSlot.type,
            id: selectedSlot.id,
            drawable: browseState.drawable,
            texture: browseState.texture,
        });
        if (result && result.ok) {
            const group = selectedSlot.type === 'component' ? 'components' : 'props';
            savedPieces[group][selectedSlot.id] = {
                drawable: browseState.drawable,
                texture: browseState.texture,
            };
            showToast('Piece saved', 'success');
            renderAll();
        }
    }

    async function removePiece(type, id) {
        await fetchNUI('removePiece', { type, id });
        const group = type === 'component' ? 'components' : 'props';
        delete savedPieces[group][id];
        showToast('Piece removed', 'info');
        renderAll();
    }

    async function clearAllPieces() {
        await fetchNUI('clearAllPieces', {});
        savedPieces = { components: {}, props: {} };
        showToast('All pieces cleared', 'info');
        renderAll();
    }

    async function closeBrowser() {
        isOpen = false;
        app.classList.add('hidden');
        selectedSlot = null;
        browseState = null;
        await fetchNUI('close', {});
    }

    // ── Event Listeners ────────────────────────────────────
    function isInputFocused() {
        const tag = document.activeElement?.tagName;
        return tag === 'INPUT' || tag === 'TEXTAREA';
    }

    // Keyboard
    document.addEventListener('keydown', e => {
        if (!isOpen) return;

        // If an input is focused, only handle Escape
        if (isInputFocused()) {
            if (e.key === 'Escape') {
                document.activeElement.blur();
                e.preventDefault();
            }
            // Enter in jump input
            if (e.key === 'Enter' && document.activeElement === jumpInput) {
                jumpToDrawable();
                e.preventDefault();
            }
            return;
        }

        // Close modal first if open
        if (!exportModal.classList.contains('hidden')) {
            if (e.key === 'Escape') { closeExportModal(); e.preventDefault(); }
            return;
        }

        const shift = e.shiftKey;
        switch (e.key) {
            case 'Escape':
                closeBrowser();
                e.preventDefault();
                break;
            case 'ArrowRight':
                changeDrawable(shift ? 10 : 1);
                e.preventDefault();
                break;
            case 'ArrowLeft':
                changeDrawable(shift ? -10 : -1);
                e.preventDefault();
                break;
            case 'ArrowUp':
                changeTexture(1);
                e.preventDefault();
                break;
            case 'ArrowDown':
                changeTexture(-1);
                e.preventDefault();
                break;
            case 'e':
            case 'E':
                savePiece();
                e.preventDefault();
                break;
        }
    });

    // Click delegation on slot grid
    slotGrid.addEventListener('click', e => {
        const btn = e.target.closest('.slot-btn');
        if (!btn) return;
        selectSlot(btn.dataset.type, parseInt(btn.dataset.id));
    });

    // Tabs
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            activeTab = tab.dataset.tab;
            selectedSlot = null;
            browseState = null;
            renderAll();
        });
    });

    // Browse arrow buttons
    document.querySelectorAll('.btn-arrow').forEach(btn => {
        btn.addEventListener('click', () => {
            switch (btn.dataset.action) {
                case 'drawable-prev': changeDrawable(-1); break;
                case 'drawable-next': changeDrawable(1); break;
                case 'texture-prev':  changeTexture(-1); break;
                case 'texture-next':  changeTexture(1); break;
            }
        });
    });

    // Jump to drawable
    $('btn-jump').addEventListener('click', jumpToDrawable);

    // Save piece button
    $('btn-save-piece').addEventListener('click', savePiece);

    // Reset camera button
    $('btn-reset-camera').addEventListener('click', () => {
        fetchNUI('resetCamera', {});
    });

    // Close button
    $('btn-close').addEventListener('click', closeBrowser);

    // Clear all
    btnClearAll.addEventListener('click', clearAllPieces);

    // Outfit list — remove buttons
    outfitList.addEventListener('click', e => {
        const btn = e.target.closest('.btn-remove');
        if (!btn) return;
        const item = btn.closest('.outfit-item');
        removePiece(item.dataset.type, parseInt(item.dataset.id));
    });

    // Export buttons
    $('btn-snapshot').addEventListener('click', async () => {
        const data = await fetchNUI('getExportData', { mode: 'snapshot' });
        if (data) openExportModal(data);
    });

    $('btn-export').addEventListener('click', async () => {
        const data = await fetchNUI('getExportData', { mode: 'saved' });
        if (data) {
            if ((!data.components || data.components.length === 0) &&
                (!data.props || data.props.length === 0)) {
                showToast('No pieces saved to export', 'error');
                return;
            }
            openExportModal(data);
        }
    });

    $('btn-restore').addEventListener('click', async () => {
        const result = await fetchNUI('restoreOriginal', {});
        if (result && result.ok) {
            showToast('Original appearance restored', 'success');
            // Refresh slot meta from Lua
            if (result.slotMeta) {
                slotMeta = result.slotMeta;
            }
            renderAll();
        }
    });

    // Modal close
    $('btn-modal-close').addEventListener('click', closeExportModal);
    exportModal.addEventListener('click', e => {
        if (e.target === exportModal) closeExportModal();
    });

    // Modal inputs update preview
    ['export-label', 'export-job', 'export-grades'].forEach(id => {
        $(id).addEventListener('input', updateExportPreview);
    });

    // Copy JSON
    $('btn-copy-json').addEventListener('click', () => {
        const json = buildExportJSON();
        const ok = copyToClipboard(json);
        showToast(ok ? 'JSON copied to clipboard' : 'Copy failed', ok ? 'success' : 'error');
    });

    // Save export
    $('btn-save-export').addEventListener('click', async () => {
        const json = buildExportJSON();
        const label = $('export-label').value || 'outfit';
        const result = await fetchNUI('confirmExport', { json, label });
        if (result && result.ok) {
            showToast(`Saved to: ${result.path}`, 'success', 5000);
            closeExportModal();
        } else {
            showToast('Export failed', 'error');
        }
    });

    // ── NUI Message Listener ───────────────────────────────
    window.addEventListener('message', e => {
        const msg = e.data;

        switch (msg.action) {
            case 'open':
                isOpen = true;
                model = msg.model || 'male';
                modelBadge.textContent = model.toUpperCase();
                modelBadge.classList.toggle('female', model === 'female');
                slotMeta = msg.slotMeta || { components: {}, props: {} };
                savedPieces = msg.savedPieces || { components: {}, props: {} };
                activeTab = 'components';
                selectedSlot = null;
                browseState = null;
                // Reset tab UI
                document.querySelectorAll('.tab').forEach(t => {
                    t.classList.toggle('active', t.dataset.tab === 'components');
                });
                app.classList.remove('hidden');
                renderAll();
                break;

            case 'close':
                isOpen = false;
                app.classList.add('hidden');
                selectedSlot = null;
                browseState = null;
                break;

            case 'updateBrowseState':
                if (msg.data) {
                    browseState = {
                        drawable: msg.data.drawable,
                        texture: msg.data.texture,
                        maxDrawable: msg.data.maxDrawable,
                        maxTexture: msg.data.maxTexture,
                    };
                    if (selectedSlot) {
                        const metaGroup = selectedSlot.type === 'component' ? slotMeta.components : slotMeta.props;
                        metaGroup[selectedSlot.id] = { drawable: msg.data.drawable, texture: msg.data.texture };
                    }
                    renderAll();
                }
                break;

            case 'updateSavedPieces':
                if (msg.data) {
                    savedPieces = msg.data;
                    renderAll();
                }
                break;

            case 'toast':
                showToast(msg.message || '', msg.type || 'info', msg.duration || 3000);
                break;
        }
    });

    // Public API (mostly for debugging)
    return {
        getState: () => ({ isOpen, activeTab, selectedSlot, browseState, savedPieces, model }),
    };
})();
