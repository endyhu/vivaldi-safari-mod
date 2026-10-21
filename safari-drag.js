/* safari-drag.js: makes tab dragging work with safari.css's equal-width tabs.

   Vivaldi lays tabs out in its own model (180px per tab) and hit-tests a drag
   by comparing the cursor to that model. safari.css stretches the tabs to fill
   the bar, so the cursor and the model disagree. This script translates the
   cursor from screen space into model space while a tab is held, and draws the
   held tab under the real cursor. Vivaldi's own drag code does everything else
   (reordering, detaching, stacking). Horizontal tab bars only.

   It is not a Vivaldi mod: Vivaldi cannot load JavaScript from the CSS mods
   folder, so patch-vivaldi.bat (Windows) or patch-vivaldi.command (macOS) adds
   it to Vivaldi's window.html. */
(() => {
  'use strict';

  // Vivaldi's own overshoot allowance for a dragged tab (bundle.js, maybeStartDragging).
  const OVERSHOOT = 5;
  // Vivaldi starts a drag after the cursor moves more than this many model pixels.
  const DRAG_THRESHOLD = 5;

  let drag = null;

  const modelValue = (el, prop) => parseFloat(el.style.getPropertyValue(prop));

  /* Pairs of (screen x, model x) for every tab edge, read from the DOM. Model x
     is what Vivaldi's script wrote inline before safari.css overrode it. Between
     pairs the map is linear, so pinned tabs (which keep their model width) and
     equal-width tabs both map correctly. Outside the strip it has slope 1, so
     Vivaldi's 80px "pulled out of the bar" distance stays 80 screen pixels. */
  function buildMap(strip) {
    const pairs = [];
    for (const tab of strip.querySelectorAll('.tab-position')) {
      const x = modelValue(tab, '--PositionX');
      const width = modelValue(tab, '--Width');
      if (Number.isNaN(x) || Number.isNaN(width)) continue;
      const rect = tab.getBoundingClientRect();
      pairs.push([rect.left, x], [rect.right, x + width]);
    }
    pairs.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
    if (pairs.length < 2) return (x) => x;
    const first = pairs[0];
    const last = pairs[pairs.length - 1];
    return (x) => {
      if (x <= first[0]) return first[1] + (x - first[0]);
      if (x >= last[0]) return last[1] + (x - last[0]);
      for (let i = 1; i < pairs.length; i++) {
        const [r0, m0] = pairs[i - 1];
        const [r1, m1] = pairs[i];
        if (x >= r0 && x <= r1 && r1 > r0) return m0 + ((x - r0) / (r1 - r0)) * (m1 - m0);
      }
      return x;
    };
  }

  function retarget(e, clientX) {
    return new MouseEvent(e.type, {
      bubbles: true, cancelable: true, composed: true, view: window,
      detail: e.detail, button: e.button, buttons: e.buttons,
      screenX: e.screenX, screenY: e.screenY, clientX, clientY: e.clientY,
      ctrlKey: e.ctrlKey, shiftKey: e.shiftKey, altKey: e.altKey, metaKey: e.metaKey,
    });
  }

  /* Vivaldi draws the held tab at its model position, which safari.css resets
     (the tabs are flex items), so the held tab is moved here instead: under the
     cursor, within the bar. Its flex slot is read back by removing the
     translation we applied last frame. It runs every frame, not per mouse
     move, because Vivaldi reorders the tabs a moment after the cursor passes
     one, which moves the slot with no mouse event. */
  function render() {
    drag.frame = requestAnimationFrame(render);
    if (!drag.started) return;
    const { tab, strip, grab, x } = drag;
    const slot = tab.getBoundingClientRect().left - drag.tx;
    const tabs = [...strip.querySelectorAll('.tab-position')];
    const lefts = tabs.map((t) => t === tab ? slot : t.getBoundingClientRect().left);
    const min = Math.min(...lefts) - OVERSHOOT;
    const max = Math.max(...lefts) + OVERSHOOT;
    drag.tx = Math.min(Math.max(x - grab, min), max) - slot;
    tab.style.transform = `translateX(${drag.tx}px)`;
  }

  function endDrag() {
    if (!drag) return;
    cancelAnimationFrame(drag.frame);
    drag.tab.style.removeProperty('transform');
    drag = null;
  }

  window.addEventListener('mousedown', (e) => {
    if (!e.isTrusted || e.button !== 0 || e.ctrlKey || e.shiftKey || e.metaKey) return;
    const tab = e.target.closest?.('.tab-strip .tab-position');
    if (!tab) return;
    endDrag();
    const toModel = buildMap(tab.closest('.tab-strip'));
    drag = {
      tab, strip: tab.closest('.tab-strip'), toModel,
      startX: e.clientX, startModelX: toModel(e.clientX), grab: e.clientX - tab.getBoundingClientRect().left,
      x: e.clientX, tx: 0, started: false, frame: 0,
    };
    // Vivaldi prevents the default on the event it handles; the original needs it too.
    e.preventDefault();
    e.stopImmediatePropagation();
    e.target.dispatchEvent(retarget(e, drag.startModelX));
  }, true);

  /* The mouseup never arrives when the tab is pulled out into a native drag, so
     the first move without a held button ends the drag. (A window blur can't be
     used: activating the tab moves focus to the page, which blurs the window
     while the drag is only starting.) */
  window.addEventListener('mousemove', (e) => {
    if (!drag || !e.isTrusted) return;
    if (!(e.buttons & 1)) return endDrag();
    const modelX = drag.toModel(e.clientX);
    drag.x = e.clientX;
    if (Math.abs(modelX - drag.startModelX) > DRAG_THRESHOLD) drag.started = true;
    e.stopImmediatePropagation();
    e.target.dispatchEvent(retarget(e, modelX));
    if (!drag.frame) render();
  }, true);

  window.addEventListener('mouseup', endDrag, true);
})();
