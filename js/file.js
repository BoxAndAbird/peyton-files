/* THE PEYTON FILES — Mode 1: "The File".
   Desk view, document binder, and the file puzzles — all three episodes. */
"use strict";

const PF_FILE = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  const PUZZLE_LABELS = {
    photo:    ["Reassemble the Photo", "Nine torn pieces."],
    redact:   ["Decode the Memo", "Two redactions."],
    crossref: ["Cross-Reference", "Two documents, one place."],
    cipher:   ["Decode the Matchbook", "Ledger shorthand: 6 — 6 / 3."],
    timeline: ["Reconstruct the 48 Hours", "Five timestamps."],
    string:   ["Run the String", "Connect the route on the board."],
    redact2:  ["Decode the Routing Memo", "Two redactions. Same bored hand."],
    crossref2:["Cross-Reference", "Two reports, three years apart."],
    cipher2:  ["Decode the Claim Slip", "Vol. 2 shorthand: 5 — 44 / 8."],
    timeline2:["Rebuild Thursday Night", "Five timestamps."],
    photo3:   ["Reassemble the 1931 Photo", "Nine torn pieces. Again."],
    cipher3:  ["Read the Deed Margin", "Shorthand: 8 — 0 / 9."],
    timeline3:["Reconstruct His Three Days", "Five records."],
    string2:  ["Run the Last String", "The board is waiting."],
  };
  const PUZZLE_ICON = (p) =>
    p.startsWith("photo") ? "photo" : p.startsWith("cipher") ? "match" : "memo";
  /* which key document a cipher shows */
  const CIPHER_KEYDOC = { cipher: "d_key", cipher2: "d_key2", cipher3: "d_key2" };
  /* which redaction puzzle builds which doc */
  const REDACT_DOC = { d_memo: "redact", d_memo2: "redact2" };
  /* board-string puzzles need their timeline first */
  const STRING_NEEDS = { string: "timeline", string2: "timeline3" };

  const shuffle = (arr) => {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  };

  const cycleOf = (ch) => {
    const m = D.chapterMeta[ch];
    return (m && m.type === "file") ? { puzzles: m.puzzles, loc: m.loc } : null;
  };

  /* ---------------- desk ---------------- */
  function render() {
    const S = PF.S;
    const meta = D.chapterMeta[S.chapter] || { ep: 1 };
    const ep = D.episodes[meta.ep] || D.episodes[1];
    const cyc = cycleOf(S.chapter);
    let stampCls = "", stampTxt = "ACTIVE";
    if (PF.flag("ep_stamped_pending")) { stampCls = "pending"; stampTxt = "PENDING"; }
    else if (PF.flag("ep_stamped") && meta.ep === 1 && S.chapter === "ep1end") { stampCls = "unresolved"; stampTxt = "UNRESOLVED"; }

    let html = `<div class="case-header">
      <div class="case-id"><b>${ep.caseNo} — VOSS, P.</b>${D.meta.title} · ${ep.num.replace("EPISODE ","EP. ")}</div>
      <div class="status-stamp ${stampCls}" id="hdr-stamp">${stampTxt}</div>
      <button class="icon-btn" id="fm-board">BOARD</button>
      <button class="icon-btn" id="fm-snd">${AU.muted ? "MUTED" : "SND"}</button>
    </div><div class="desk">`;

    html += `<div class="objective"><b>TO DO — M.K.</b>${(D.objectives[S.chapter]||"—").replace(/\n/g,"<br>")}</div>`;

    if (cyc) {
      const allSolved = cyc.puzzles.every(p => S.solved[p]);
      if (allSolved) {
        const loc = D.locations[cyc.loc];
        html += `<div class="loc-card">
          <div class="lc-k">📍 ${loc.key}</div>
          <div class="lc-n">${loc.name}</div>
          <div class="lc-s">${loc.sub}</div>
          <button class="go-btn" id="fm-go">FOLLOW THE LEAD →</button>
        </div>`;
      } else {
        html += `<div class="shelf-label">CASE WORK</div><div class="doc-shelf">`;
        for (const p of cyc.puzzles) {
          const done = S.solved[p];
          html += `<div class="doc-card" data-puzzle="${p}">
            <div class="d-ic">${A.ICONS[PUZZLE_ICON(p)]}</div>
            <div class="d-t"><b>${PUZZLE_LABELS[p][0]}</b><span>${PUZZLE_LABELS[p][1]}</span></div>
            <div class="badge ${done ? "done" : ""}">${done ? "SOLVED" : "OPEN"}</div>
          </div>`;
        }
        html += `</div>`;
      }
    }

    html += `<div class="shelf-label">DOCUMENTS &amp; EVIDENCE</div><div class="doc-shelf">`;
    const docs = PF.S.docs.slice().reverse();
    for (const id of docs) {
      const d = D.docs.find(x => x.id === id);
      if (!d) continue;
      const isNew = !PF.S.seen.includes(id);
      html += `<div class="doc-card ${isNew ? "new" : ""}" data-doc="${id}">
        <div class="d-ic">${A.ICONS[d.icon] || A.ICONS.file}</div>
        <div class="d-t"><b>${d.title}</b><span>${d.sub}</span></div>
      </div>`;
    }
    html += `</div></div>`;

    const fm = $("#file-mode");
    fm.innerHTML = html;

    fm.querySelector("#fm-board").addEventListener("click", () => PF_BOARD.open(false));
    fm.querySelector("#fm-snd").addEventListener("click", (e) => {
      AU.setMuted(!AU.muted);
      e.target.textContent = AU.muted ? "MUTED" : "SND";
    });
    const go = fm.querySelector("#fm-go");
    go && go.addEventListener("click", () => PF.travel(cycleOf(PF.S.chapter).loc));
    fm.querySelectorAll("[data-puzzle]").forEach(el =>
      el.addEventListener("click", () => openPuzzle(el.getAttribute("data-puzzle"))));
    fm.querySelectorAll("[data-doc]").forEach(el =>
      el.addEventListener("click", () => openDoc(el.getAttribute("data-doc"))));
  }

  function setStamp(mode) {
    if (mode === "unresolved") PF.setFlag("ep_stamped");
    if (mode === "pending") PF.setFlag("ep_stamped_pending");
    const el = $("#hdr-stamp");
    if (el) { el.textContent = mode.toUpperCase(); el.classList.add(mode); }
  }

  /* ---------------- overlay helpers ---------------- */
  function openOverlay(inner, barButtons) {
    const ov = $("#overlay");
    ov.innerHTML = `<div class="ov-scroll">${inner}</div>
      <div class="ov-bar">${barButtons || `<button class="close-btn" data-close>BACK TO THE DESK</button>`}</div>`;
    ov.classList.remove("hidden");
    ov.querySelectorAll("[data-close]").forEach(b => b.addEventListener("click", closeOverlay));
    AU.sfx.paperBig();
    return ov;
  }
  function closeOverlay() {
    $("#overlay").classList.add("hidden");
    $("#overlay").innerHTML = "";
    if ((D.chapterMeta[PF.S.chapter] || {}).type !== "world") render();
  }

  /* ---------------- documents ---------------- */
  function openDoc(id) {
    const S = PF.S;
    if (!S.seen.includes(id)) { S.seen.push(id); PF.save(); }
    const d = D.docs.find(x => x.id === id);
    if (!d) return;

    if (id === "d_photo" || id === "d_photo31") {
      const pKey = id === "d_photo" ? "photo" : "photo3";
      const art = pKey === "photo" ? A.photoSVG() : A.photo1931SVG();
      const cap = pKey === "photo" ? "the storage place — LOOK AT THE DOOR. Unit 14."
                                   : "Whitmore Lake House, 1931 — LOOK AT THE WINDOW. The lamp.";
      if (S.solved[pKey]) {
        openOverlay(`<div class="polaroid">${art}<div class="ph-cap">${cap}</div></div>`);
      } else {
        openOverlay(`<div class="paper">${d.body}</div>`,
          `<button class="close-btn" data-close>BACK</button>
           <button class="action-btn" data-act>REASSEMBLE</button>`);
        $("#overlay [data-act]").addEventListener("click", () => openPuzzle(pKey));
      }
      return;
    }
    if (REDACT_DOC[id]) {
      const pKey = REDACT_DOC[id];
      if (S.solved[pKey]) {
        openOverlay(`<div class="paper">${memoHTML(pKey, true)}</div>`);
      } else {
        openOverlay(`<div class="paper">${memoHTML(pKey, false)}</div>`,
          `<button class="close-btn" data-close>BACK</button>
           <button class="action-btn" data-act>DECODE</button>`);
        $("#overlay [data-act]").addEventListener("click", () => openPuzzle(pKey));
      }
      return;
    }
    if (id === "d_matchbook" && !S.solved.cipher && PF.S.chapter === "file2") {
      openOverlay(`<div class="paper">${d.body}</div>`,
        `<button class="close-btn" data-close>BACK</button>
         <button class="action-btn" data-act>DECODE THE CODE</button>`);
      $("#overlay [data-act]").addEventListener("click", () => openPuzzle("cipher"));
      return;
    }
    if (id === "d_manifest" && !S.solved.cipher2 && PF.S.chapter === "file5") {
      openOverlay(`<div class="paper"><div class="stamp-red">31-C</div>${d.body}</div>`,
        `<button class="close-btn" data-close>BACK</button>
         <button class="action-btn" data-act>DECODE THE MARGIN</button>`);
      $("#overlay [data-act]").addEventListener("click", () => openPuzzle("cipher2"));
      return;
    }
    if (id === "d_deed" && !S.solved.cipher3 && PF.S.chapter === "file6") {
      openOverlay(`<div class="paper"><div class="stamp-red">1931</div>${d.body}</div>`,
        `<button class="close-btn" data-close>BACK</button>
         <button class="action-btn" data-act>READ THE MARGIN</button>`);
      $("#overlay [data-act]").addEventListener("click", () => openPuzzle("cipher3"));
      return;
    }
    const epMeta = D.episodes[(D.chapterMeta[PF.S.chapter] || { ep: 1 }).ep] || D.episodes[1];
    openOverlay(`<div class="paper"><div class="stamp-red">${epMeta.caseNo}</div>${d.body}</div>`);
  }

  /* Render a redaction-memo body from puzzle state (the doc IS the puzzle). */
  function memoHTML(pKey, solvedAll, reveal) {
    const def = D.puzzles[pKey];
    const shown = reveal || def.slots.map(() => solvedAll);
    let out = `<h3>${def.intro.split("\n")[0]}</h3><div class="meta">${def.intro.split("\n")[1] || ""} · ROUTING: L. ONLY</div>`;
    for (const line of def.lines) {
      if (line.slot === -1) { out += `<p>${line.pre}</p>`; continue; }
      const s = def.slots[line.slot];
      const cell = shown[line.slot]
        ? `<span class="redacted slot done" data-slot="${line.slot}">${s.answer}</span>`
        : `<span class="redacted slot" data-slot="${line.slot}">██████</span>`;
      out += `<p>${line.pre}${cell}${line.post}</p>`;
    }
    return out;
  }

  /* ---------------- puzzles ---------------- */
  function openPuzzle(p) {
    // A solved puzzle re-opens as a read-only review — never replays the solve chain.
    if (PF.S.solved[p]) return reviewSolved(p);
    // Board strings need their pins, which appear once the matching timeline is done.
    if (STRING_NEEDS[p] && !PF.S.solved[STRING_NEEDS[p]]) {
      PF.toast("Reconstruct the timeline first — the board's still missing a pin.");
      return;
    }
    if (p === "photo")    return puzzlePhoto("photo", A.photoSVG());
    if (p === "photo3")   return puzzlePhoto("photo3", A.photo1931SVG());
    if (p === "redact" || p === "redact2") return puzzleRedact(p);
    if (p === "crossref" || p === "crossref2") return puzzleCrossref(p);
    if (p.startsWith("cipher")) return puzzleCipher(p);
    if (p.startsWith("timeline")) return puzzleTimeline(p);
    if (p === "string")   return PF_BOARD.open(true, "string");
    if (p === "string2")  return PF_BOARD.open(true, "string2");
  }

  /* Read-only review of an already-solved puzzle (no markSolved / narration replay). */
  function reviewSolved(p) {
    if (p === "photo")    return openDoc("d_photo");
    if (p === "photo3")   return openDoc("d_photo31");
    if (p === "redact")   return openDoc("d_memo");
    if (p === "redact2")  return openDoc("d_memo2");
    if (p === "cipher")   return openDoc("d_matchbook");
    if (p === "cipher2")  return openDoc("d_manifest");
    if (p === "cipher3")  return openDoc("d_deed");
    if (p === "crossref") return openDoc("d_ledger");
    if (p === "crossref2")return openDoc("d_intake");
    if (p === "string" || p === "string2") return PF_BOARD.open(false);
    if (p.startsWith("timeline")) {
      const def = D.puzzles[p];
      const rows = def.items.slice().sort((a,b)=>a.order-b.order)
        .map((it,i)=>`<div class="tl-item picked"><div class="tl-n">${i+1}</div><div><b>${it.tag}</b>${it.text}</div></div>`).join("");
      openOverlay(`<div class="pz-head"><b>RECONSTRUCTED</b><span>The order holds.</span></div><div class="tl-list">${rows}</div>`);
    }
  }

  function markSolved(p) {
    PF.S.solved[p] = true;
    PF.save();
    AU.sfx.good();
    PF.toast(D.puzzles[p].toast);
  }
  function finishPuzzle(p, extraDelay) {
    setTimeout(() => {
      PF.narrate(D.puzzles[p].solvedNarration, () => closeOverlay());
    }, extraDelay || 900);
  }

  /* --- photo reassembly: tap two tiles to swap --- */
  function puzzlePhoto(pKey, artSVG) {
    const def = D.puzzles[pKey];
    let perm = shuffle([0,1,2,3,4,5,6,7,8]);
    while (perm.every((v,i) => v === i)) perm = shuffle(perm);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="photo-grid" id="pz-grid"></div>`);
    const grid = ov.querySelector("#pz-grid");
    let sel = -1;

    function draw() {
      grid.innerHTML = "";
      perm.forEach((seg, pos) => {
        const t = document.createElement("div");
        t.className = "tile" + (pos === sel ? " sel" : "");
        const col = seg % 3, row = Math.floor(seg / 3);
        t.innerHTML = artSVG;
        const svg = t.firstElementChild;
        svg.style.left = (-col * 100) + "%";
        svg.style.top = (-row * 100) + "%";
        t.addEventListener("pointerdown", () => tap(pos));
        grid.appendChild(t);
      });
    }
    function tap(pos) {
      if (PF.S.solved[pKey]) return;
      AU.sfx.paper();
      if (sel === -1) { sel = pos; }
      else if (sel === pos) { sel = -1; }
      else {
        [perm[sel], perm[pos]] = [perm[pos], perm[sel]];
        sel = -1;
        if (perm.every((v,i) => v === i)) {
          draw();
          grid.classList.add("solved");
          markSolved(pKey);
          finishPuzzle(pKey);
          return;
        }
      }
      draw();
    }
    draw();
  }

  /* --- redaction decode: tap a bar, pick the word --- */
  function puzzleRedact(pKey) {
    const def = D.puzzles[pKey];
    const revealed = def.slots.map(() => false);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="paper" id="pz-memo">${memoHTML(pKey, false, revealed)}</div>
      <div class="choice-row" id="pz-choices"></div>`);
    let current = -1;

    function wire() {
      ov.querySelectorAll(".redacted.slot:not(.done)").forEach(el => {
        el.addEventListener("pointerdown", () => {
          current = +el.getAttribute("data-slot");
          drawChoices();
          ov.querySelectorAll(".redacted.slot").forEach(x => x.style.boxShadow = "");
          el.style.boxShadow = "0 0 0 3px " + "#ffb35c";
          AU.sfx.paper();
        });
      });
    }
    function drawChoices() {
      const row = ov.querySelector("#pz-choices");
      if (current < 0) { row.innerHTML = ""; return; }
      row.innerHTML = "";
      shuffle(def.slots[current].options).forEach(opt => {
        const b = document.createElement("button");
        b.className = "choice-chip";
        b.textContent = opt;
        b.addEventListener("click", () => {
          if (opt === def.slots[current].answer) {
            revealed[current] = true;
            AU.sfx.stamp();
            ov.querySelector("#pz-memo").innerHTML = memoHTML(pKey, false, revealed);
            current = -1; drawChoices(); wire();
            if (revealed.every(Boolean)) { markSolved(pKey); finishPuzzle(pKey); }
          } else {
            b.classList.add("bad"); AU.sfx.bad();
            setTimeout(() => b.classList.remove("bad"), 400);
          }
        });
        row.appendChild(b);
      });
    }
    wire();
  }

  /* --- cross-reference: tap the matching detail in each document --- */
  function puzzleCrossref(pKey) {
    const def = D.puzzles[pKey];
    const a = D.docs.find(d => d.id === def.docA), b = D.docs.find(d => d.id === def.docB);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="paper" data-side="a">${a.body}</div>
      <div class="paper" data-side="b">${b.body}</div>`);
    const sel = { a: null, b: null };
    ov.querySelectorAll(".paper .hl").forEach(el => {
      el.addEventListener("pointerdown", () => {
        const side = el.closest(".paper").getAttribute("data-side");
        ov.querySelectorAll(`.paper[data-side="${side}"] .hl`).forEach(x => x.classList.remove("linked"));
        el.classList.add("linked");
        sel[side] = el.getAttribute("data-link");
        AU.sfx.pin();
        if (sel.a && sel.b) {
          const ok = (sel.a === def.pair[0] && sel.b === def.pair[1]) ||
                     (sel.a === def.pair[1] && sel.b === def.pair[0]);
          if (ok) {
            markSolved(pKey);
            finishPuzzle(pKey);
          } else {
            AU.sfx.bad();
            setTimeout(() => {
              ov.querySelectorAll(".hl").forEach(x => x.classList.remove("linked"));
              sel.a = sel.b = null;
            }, 450);
          }
        }
      });
    });
  }

  /* --- cipher: decode a shorthand code with its key --- */
  function puzzleCipher(pKey) {
    const def = D.puzzles[pKey];
    const keyDoc = D.docs.find(d => d.id === CIPHER_KEYDOC[pKey]);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="cipher-slots" id="pz-slots"></div>
      <div class="choice-row" id="pz-copts"></div>
      ${def.note ? `<div class="pz-head"><span>${def.note}</span></div>` : ""}
      <div class="paper" style="font-size:12px">${keyDoc.body}</div>`);
    let idx = 0;
    const got = [];

    function drawSlots() {
      const wrap = ov.querySelector("#pz-slots");
      wrap.innerHTML = "";
      def.code.forEach((sym, i) => {
        const s = document.createElement("div");
        s.className = "cipher-slot" + (i < idx ? " done" : i === idx ? " cur" : "");
        s.textContent = i < idx ? got[i] : sym;
        wrap.appendChild(s);
      });
    }
    function drawOpts() {
      const row = ov.querySelector("#pz-copts");
      row.innerHTML = "";
      if (idx >= def.code.length) return;
      shuffle(def.options[idx]).forEach(opt => {
        const b = document.createElement("button");
        b.className = "choice-chip";
        b.textContent = opt;
        b.addEventListener("click", () => {
          if (opt === def.answers[idx]) {
            got[idx] = opt; idx++;
            AU.sfx.pin();
            drawSlots(); drawOpts();
            if (idx >= def.code.length) { markSolved(pKey); finishPuzzle(pKey); }
          } else {
            b.classList.add("bad"); AU.sfx.bad();
            setTimeout(() => b.classList.remove("bad"), 400);
          }
        });
        row.appendChild(b);
      });
    }
    drawSlots(); drawOpts();
  }

  /* --- timeline: tap the records earliest-first --- */
  function puzzleTimeline(pKey) {
    const def = D.puzzles[pKey];
    const items = shuffle(def.items);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="tl-list" id="pz-tl"></div>`);
    const list = ov.querySelector("#pz-tl");
    let expected = 0;
    items.forEach(it => {
      const el = document.createElement("div");
      el.className = "tl-item";
      el.innerHTML = `<div class="tl-n">?</div><div><b>${it.tag}</b>${it.text}</div>`;
      el.addEventListener("pointerdown", () => {
        if (el.classList.contains("picked")) return;
        if (it.order === expected) {
          el.classList.add("picked");
          el.querySelector(".tl-n").textContent = String(expected + 1);
          expected++;
          AU.sfx.pin();
          if (expected === def.items.length) { markSolved(pKey); finishPuzzle(pKey); }
        } else {
          el.classList.add("bad"); AU.sfx.bad();
          setTimeout(() => el.classList.remove("bad"), 400);
        }
      });
      list.appendChild(el);
    });
  }

  /* =================================================================
     WORLD PUZZLES — physical locks, opened where they stand.
     openWorldPuzzle(kind, onSolved) is called from world mode.
     ================================================================= */
  function openWorldPuzzle(kind, onSolved) {
    if (PF.S.solved[kind]) { onSolved && onSolved(); return; }
    if (kind === "vault") return puzzleVault(onSolved);
    if (kind === "phone") return puzzlePhone(onSolved);
  }
  function markWorldSolved(kind) {
    PF.S.solved[kind] = true;
    PF.save();
    AU.sfx.good();
    PF.toast(D.puzzles[kind].toast);
  }

  /* --- the locker dial: three numbers, left to right --- */
  function puzzleVault(onSolved) {
    const def = D.puzzles.vault;
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="vault">
        <div class="vault-slots" id="v-slots"></div>
        <div class="vault-dial">
          <button class="dial-btn" id="v-dn">◀</button>
          <div class="dial-num" id="v-num">0</div>
          <button class="dial-btn" id="v-up">▶</button>
        </div>
        <button class="action-btn" id="v-set" style="min-width:170px">SET</button>
      </div>`,
      `<button class="close-btn" data-close>STEP AWAY</button>`);
    let cur = 0, at = 0;
    const got = [];
    const slots = ov.querySelector("#v-slots");
    const num = ov.querySelector("#v-num");

    function drawSlots() {
      slots.innerHTML = def.combo.map((c, i) =>
        `<div class="cipher-slot ${i < at ? "done" : i === at ? "cur" : ""}">
          ${i < at ? got[i] : (def.comboLabels[i] || "?")}</div>`).join("");
    }
    function drawNum() { num.textContent = String(cur); }
    ov.querySelector("#v-up").addEventListener("click", () => { cur = (cur + 1) % (def.max + 1); AU.sfx.tick(); drawNum(); });
    ov.querySelector("#v-dn").addEventListener("click", () => { cur = (cur - 1 + def.max + 1) % (def.max + 1); AU.sfx.tick(); drawNum(); });
    ov.querySelector("#v-set").addEventListener("click", () => {
      if (cur === def.combo[at]) {
        got[at] = cur; at++;
        AU.sfx.pin();
        drawSlots();
        if (at >= def.combo.length) {
          AU.sfx.clunk();
          markWorldSolved("vault");
          setTimeout(() => {
            PF.narrate(def.solvedNarration, () => {
              $("#overlay").classList.add("hidden"); $("#overlay").innerHTML = "";
              onSolved && onSolved();
            });
          }, 500);
        }
      } else {
        AU.sfx.bad();
        at = 0; got.length = 0;
        drawSlots();
        PF.toast("The dial resets. Left to right, all three.");
      }
    });
    drawSlots(); drawNum();
  }

  /* --- the rotary phone: dial the house line --- */
  function puzzlePhone(onSolved) {
    const def = D.puzzles.phone;
    const digitsHTML = ["1","2","3","4","5","6","7","8","9","0"].map(d =>
      `<button class="rotary-digit" data-d="${d}">${d}</button>`).join("");
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="rotary">
        <div class="rotary-num" id="r-num">— — — —</div>
        <div class="rotary-wheel" id="r-wheel">${digitsHTML}<div class="rotary-hub"></div></div>
      </div>`,
      `<button class="close-btn" data-close>HANG UP</button>`);
    let at = 0;
    const numEl = ov.querySelector("#r-num");
    const wheel = ov.querySelector("#r-wheel");

    function drawNum() {
      numEl.textContent = def.number.map((d, i) => i < at ? d : "—").join(" ");
    }
    ov.querySelectorAll(".rotary-digit").forEach(b => {
      b.addEventListener("click", () => {
        const d = b.getAttribute("data-d");
        if (d === def.number[at]) {
          at++;
          AU.sfx.dialA();
          wheel.classList.remove("spin"); void wheel.offsetWidth; wheel.classList.add("spin");
          AU.sfx.dialB(3 + (+d || 10));
          drawNum();
          if (at >= def.number.length) {
            setTimeout(() => {
              AU.sfx.ring1();
              markWorldSolved("phone");
              setTimeout(() => {
                $("#overlay").classList.add("hidden"); $("#overlay").innerHTML = "";
                onSolved && onSolved();
              }, 900);
            }, 700);
          }
        } else {
          AU.sfx.bad();
          at = 0; drawNum();
          PF.toast("A tired dial tone. Start over — 0114.");
        }
      });
    });
    drawNum();
  }

  return { render, openDoc, openPuzzle, openWorldPuzzle, setStamp, closeOverlay };
})();
