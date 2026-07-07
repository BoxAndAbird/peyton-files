/* THE PEYTON FILES — Mode 1: "The File".
   Desk view, document binder, and the file puzzles. */
"use strict";

const PF_FILE = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  const CYCLES = {
    file1: { puzzles: ["photo","redact"],    loc: "storage" },
    file2: { puzzles: ["crossref","cipher"], loc: "diner" },
    file3: { puzzles: ["timeline","string"], loc: "motel" },
  };
  const PUZZLE_LABELS = {
    photo:    ["Reassemble the Photo", "Nine torn pieces."],
    redact:   ["Decode the Memo", "Two redactions."],
    crossref: ["Cross-Reference", "Two documents, one place."],
    cipher:   ["Decode the Matchbook", "Ledger shorthand: 6 — 6 / 3."],
    timeline: ["Reconstruct the 48 Hours", "Five timestamps."],
    string:   ["Run the String", "Connect the route on the board."],
  };

  const shuffle = (arr) => {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  };

  /* ---------------- desk ---------------- */
  function render() {
    const S = PF.S;
    const cyc = CYCLES[S.chapter];
    const stampCls = S.chapter === "epilogue" && PF.flag("ep_stamped") ? "unresolved" : "";
    const stampTxt = stampCls ? "UNRESOLVED" : "ACTIVE";

    let html = `<div class="case-header">
      <div class="case-id"><b>${D.meta.caseNo} — VOSS, P.</b>${D.meta.title} · EP. 1</div>
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
            <div class="d-ic">${A.ICONS[p === "photo" ? "photo" : p === "cipher" ? "match" : "memo"]}</div>
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
    go && go.addEventListener("click", () => PF.travel(CYCLES[PF.S.chapter].loc));
    fm.querySelectorAll("[data-puzzle]").forEach(el =>
      el.addEventListener("click", () => openPuzzle(el.getAttribute("data-puzzle"))));
    fm.querySelectorAll("[data-doc]").forEach(el =>
      el.addEventListener("click", () => openDoc(el.getAttribute("data-doc"))));
  }

  function setStamp(mode) {
    if (mode === "unresolved") PF.setFlag("ep_stamped");
    const el = $("#hdr-stamp");
    if (el) { el.textContent = "UNRESOLVED"; el.classList.add("unresolved"); }
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
    render();
  }

  /* ---------------- documents ---------------- */
  function openDoc(id) {
    const S = PF.S;
    if (!S.seen.includes(id)) { S.seen.push(id); PF.save(); }
    const d = D.docs.find(x => x.id === id);
    if (!d) return;

    if (id === "d_photo") {
      if (S.solved.photo) {
        openOverlay(`<div class="polaroid">${A.photoSVG()}<div class="ph-cap">the storage place — LOOK AT THE DOOR. Unit 14.</div></div>`);
      } else {
        openOverlay(`<div class="paper">${d.body}</div>`,
          `<button class="close-btn" data-close>BACK</button>
           <button class="action-btn" data-act="photo">REASSEMBLE</button>`);
        $("#overlay [data-act]").addEventListener("click", () => openPuzzle("photo"));
      }
      return;
    }
    if (id === "d_memo") {
      if (S.solved.redact) {
        openOverlay(`<div class="paper">${memoHTML(true)}</div>`);
      } else {
        openOverlay(`<div class="paper">${memoHTML(false)}</div>`,
          `<button class="close-btn" data-close>BACK</button>
           <button class="action-btn" data-act="redact">DECODE</button>`);
        $("#overlay [data-act]").addEventListener("click", () => openPuzzle("redact"));
      }
      return;
    }
    if (id === "d_matchbook" && !S.solved.cipher && PF.S.chapter === "file2") {
      openOverlay(`<div class="paper">${d.body}</div>`,
        `<button class="close-btn" data-close>BACK</button>
         <button class="action-btn" data-act="cipher">DECODE THE CODE</button>`);
      $("#overlay [data-act]").addEventListener("click", () => openPuzzle("cipher"));
      return;
    }
    openOverlay(`<div class="paper"><div class="stamp-red">${D.meta.caseNo}</div>${d.body}</div>`);
  }

  /* Render the memo body from puzzle state (the doc IS the puzzle). */
  function memoHTML(solvedAll, reveal) {
    const def = D.puzzles.redact;
    const S = PF.S;
    const shown = reveal || def.slots.map(() => solvedAll);
    let out = `<h3>Internal — Do Not Distribute</h3><div class="meta">RE: ACCOUNT SERVICES · ROUTING: L. ONLY</div>`;
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
    // The board string needs the Route 9 pin, which only appears once the timeline is done.
    if (p === "string" && !PF.S.solved.timeline) {
      PF.toast("Reconstruct the timeline first — the board's still missing a pin.");
      return;
    }
    if (p === "photo") return puzzlePhoto();
    if (p === "redact") return puzzleRedact();
    if (p === "crossref") return puzzleCrossref();
    if (p === "cipher") return puzzleCipher();
    if (p === "timeline") return puzzleTimeline();
    if (p === "string") return PF_BOARD.open(true);
  }

  /* Read-only review of an already-solved puzzle (no markSolved / narration replay). */
  function reviewSolved(p) {
    if (p === "photo")    return openDoc("d_photo");
    if (p === "redact")   return openDoc("d_memo");
    if (p === "cipher")   return openDoc("d_matchbook");
    if (p === "crossref") return openDoc("d_ledger");
    if (p === "string")   return PF_BOARD.open(false);
    if (p === "timeline") {
      const def = D.puzzles.timeline;
      const rows = def.items.slice().sort((a,b)=>a.order-b.order)
        .map((it,i)=>`<div class="tl-item picked"><div class="tl-n">${i+1}</div><div><b>${it.tag}</b>${it.text}</div></div>`).join("");
      openOverlay(`<div class="pz-head"><b>THE 48 HOURS</b><span>Reconstructed.</span></div><div class="tl-list">${rows}</div>`);
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
  function puzzlePhoto() {
    const def = D.puzzles.photo;
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
        t.innerHTML = A.photoSVG();
        const svg = t.firstElementChild;
        svg.style.left = (-col * 100) + "%";
        svg.style.top = (-row * 100) + "%";
        t.addEventListener("pointerdown", () => tap(pos));
        grid.appendChild(t);
      });
    }
    function tap(pos) {
      if (PF.S.solved.photo) return;
      AU.sfx.paper();
      if (sel === -1) { sel = pos; }
      else if (sel === pos) { sel = -1; }
      else {
        [perm[sel], perm[pos]] = [perm[pos], perm[sel]];
        sel = -1;
        if (perm.every((v,i) => v === i)) {
          draw();
          grid.classList.add("solved");
          markSolved("photo");
          finishPuzzle("photo");
          return;
        }
      }
      draw();
    }
    draw();
  }

  /* --- redaction decode: tap a bar, pick the word --- */
  function puzzleRedact() {
    const def = D.puzzles.redact;
    const revealed = def.slots.map(() => false);
    const ov = openOverlay(`
      <div class="pz-head"><b>${def.title}</b><span>${def.hint}</span></div>
      <div class="paper" id="pz-memo">${memoHTML(false, revealed)}</div>
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
      shuffle(D.puzzles.redact.slots[current].options).forEach(opt => {
        const b = document.createElement("button");
        b.className = "choice-chip";
        b.textContent = opt;
        b.addEventListener("click", () => {
          if (opt === def.slots[current].answer) {
            revealed[current] = true;
            AU.sfx.stamp();
            ov.querySelector("#pz-memo").innerHTML = memoHTML(false, revealed);
            current = -1; drawChoices(); wire();
            if (revealed.every(Boolean)) { markSolved("redact"); finishPuzzle("redact"); }
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
  function puzzleCrossref() {
    const def = D.puzzles.crossref;
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
            markSolved("crossref");
            finishPuzzle("crossref");
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

  /* --- cipher: decode 6 — 6 / 3 with the shorthand key --- */
  function puzzleCipher() {
    const def = D.puzzles.cipher;
    const keyDoc = D.docs.find(d => d.id === "d_key");
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
            if (idx >= def.code.length) { markSolved("cipher"); finishPuzzle("cipher"); }
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
  function puzzleTimeline() {
    const def = D.puzzles.timeline;
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
          if (expected === def.items.length) { markSolved("timeline"); finishPuzzle("timeline"); }
        } else {
          el.classList.add("bad"); AU.sfx.bad();
          setTimeout(() => el.classList.remove("bad"), 400);
        }
      });
      list.appendChild(el);
    });
  }

  return { render, openDoc, openPuzzle, setStamp, closeOverlay };
})();
