/* THE PEYTON FILES — the corkboard / conspiracy wall.
   Pins accumulate across all three episodes; red string connects them.
   The "Run the String" puzzles happen here. */
"use strict";

const PF_BOARD = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  /* Strings the case makes on its own (drawn when both pins exist). */
  const AUTO = [
    ["p_case","p_storage"], ["p_case","p_pruitt"], ["p_case","p_diner"],
    ["p_route9","p_motel"],
    ["p_motel","p_annex"], ["p_annex","p_locker"],
    ["p_vol1","p_lakehouse"],
  ];

  let stringMode = false;
  let stringKey = "string";
  let sel = null;

  function pinVisible(pin) {
    const S = PF.S;
    if (pin.at === "file1") return true;
    return !!S.solved[pin.at];
  }

  function open(asPuzzle, key) {
    stringKey = key || "string";
    stringMode = !!asPuzzle && !PF.S.solved[stringKey];
    sel = null;
    PF.showScreen("board-mode");
    render();
  }

  function close() {
    PF.showScreen("file-mode");
    PF_FILE.render();
  }

  function render() {
    const bm = $("#board-mode");
    const def = D.puzzles[stringKey];
    bm.innerHTML = `<div class="case-header">
        <div class="case-id"><b>THE BOARD</b>${D.meta.caseNo} — red string &amp; pins</div>
        <button class="icon-btn" id="bd-back">FILE</button>
      </div>
      <div id="board-area">
        <svg id="string-svg"></svg>
      </div>
      ${stringMode ? `<div class="board-hint">${def.hint}</div>` :
        `<div class="board-hint">Everything pinned so far. Tap a pin to read it.</div>`}`;
    bm.querySelector("#bd-back").addEventListener("click", close);

    const area = bm.querySelector("#board-area");
    const W = area.clientWidth, H = area.clientHeight;
    const pins = D.pins.filter(pinVisible);
    const centers = {};

    pins.forEach((pin, i) => {
      const el = document.createElement("div");
      el.className = "pin-card" + (pin.loc ? " loc" : "");
      el.setAttribute("data-pin", pin.id);
      el.style.transform = `rotate(${(i % 2 ? 1 : -1) * (1 + (i % 3))}deg)`;
      el.innerHTML = `<div class="pc-art">${A.PIN_ART[pin.art] || ""}</div><b>${pin.label}</b>`;
      area.appendChild(el);
      const w = el.offsetWidth, h = el.offsetHeight;
      const left = Math.max(4, Math.min(W - w - 4, pin.x * W - w / 2));
      const top  = Math.max(4, Math.min(H - h - 4, pin.y * H - h / 2));
      el.style.left = left + "px";
      el.style.top = top + "px";
      centers[pin.id] = { x: left + w / 2, y: top + 13 };
      el.addEventListener("pointerdown", () => tapPin(pin, el));
    });

    drawStrings(centers);
  }

  function drawStrings(centers) {
    const svg = $("#string-svg");
    if (!svg) return;
    const lines = [];
    AUTO.forEach(([a, b]) => {
      if (centers[a] && centers[b]) lines.push([a, b, "#8a2320", 2.5, .75]);
    });
    (PF.S.connections || []).forEach(([a, b]) => {
      if (centers[a] && centers[b]) lines.push([a, b, "#c23430", 3.5, .95]);
    });
    svg.innerHTML = lines.map(([a, b, col, w, op]) => {
      const p1 = centers[a], p2 = centers[b];
      const mx = (p1.x + p2.x) / 2, my = (p1.y + p2.y) / 2 + 26;
      return `<path d="M${p1.x},${p1.y} Q${mx},${my} ${p2.x},${p2.y}" fill="none"
        stroke="${col}" stroke-width="${w}" opacity="${op}" stroke-linecap="round"/>`;
    }).join("");
  }

  function tapPin(pin, el) {
    if (!stringMode) {
      AU.sfx.pin();
      PF.toast(pin.label);
      return;
    }
    const def = D.puzzles[stringKey];
    if (!sel) {
      sel = pin.id;
      el.classList.add("sel");
      AU.sfx.pin();
      return;
    }
    if (sel === pin.id) {
      sel = null;
      el.classList.remove("sel");
      return;
    }
    const pairKey = (a, b) => [a, b].sort().join("|");
    const attempted = pairKey(sel, pin.id);
    const required = def.connections.map(([a, b]) => pairKey(a, b));
    const already = (PF.S.connections || []).map(([a, b]) => pairKey(a, b));

    if (required.includes(attempted) && !already.includes(attempted)) {
      PF.S.connections.push([sel, pin.id]);
      PF.save();
      AU.sfx.string();
      sel = null;
      render();
      const doneAll = required.every(r => PF.S.connections.map(([a,b]) => pairKey(a,b)).includes(r));
      if (doneAll) {
        PF.S.solved[stringKey] = true;
        PF.save();
        stringMode = false;
        AU.sfx.good();
        PF.toast(def.toast);
        setTimeout(() => {
          render(); // the location pin drops in
          AU.sfx.pin();
          PF.narrate(def.solvedNarration, () => close());
        }, 700);
      }
    } else {
      AU.sfx.bad();
      sel = null;
      render();
    }
  }

  return { open, close, render };
})();
