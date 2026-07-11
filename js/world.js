/* THE PEYTON FILES — Mode 2: "The World".
   Painted side-view walk-and-explore. Tap the ground to walk; tap rings to interact.
   Kessler is the straight-man camera the comedy reflects off of —
   and, lately, the thing the scenery has started watching back. */
"use strict";

const PF_WORLD = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  const VIEW_H = 720;
  const K_W = 120, K_H = 190;
  const SPEED = 330;                 // scene px / second

  let sceneId = null, def = null, sceneW = 0, groundY = 640;
  let svg = null, stage = null, viewport = null;
  let kx = 0, ktarget = 0, facing = 1, walkCb = null;
  let camX = 0, camInit = false;
  let raf = 0, lastT = 0, stepT = 0;
  let selItem = null, dlgOpen = false, whitlocksLeaving = false;
  let hauntTimer = 0;

  /* ---------------- scene entry ---------------- */
  function enter(id) {
    sceneId = id;
    def = D.scenes[id];
    sceneW = def.art ? A.ART_W : def.width;
    groundY = def.ground || 640;
    const wm = $("#world-mode");
    wm.innerHTML = `
      <div id="world-viewport"><div id="world-stage">${def.art ? A.sceneArt(id, def) : A.SCENES[id]()}</div></div>
      ${def.rain ? `<div class="rain"></div><div class="rain r2"></div>` : ""}
      <div class="fogdrift"></div><div class="fogdrift f2"></div>
      <div class="scene-title">${def.title}</div>
      <div class="world-vignette"></div>
      <button class="world-return hidden" id="w-return">BACK TO THE FILE →</button>
      <div id="inv-bar"></div>
      <div id="dialogue" class="hidden"></div>`;
    viewport = wm.querySelector("#world-viewport");
    stage = wm.querySelector("#world-stage");
    svg = stage.querySelector("svg");

    sizeStage();
    buildActors();
    if (def.dark) buildDarkness();
    renderInventory();
    refreshHotspots();
    checkExit(true);

    kx = def.spawnX; ktarget = kx; facing = 1; walkCb = null; selItem = null; dlgOpen = false; whitlocksLeaving = false;
    camInit = false;
    placeKessler(); placeCamera(true);

    viewport.addEventListener("pointerdown", onTap);
    window.addEventListener("resize", sizeStage);

    AU.startWind(sceneId === "lakehouse");
    scheduleHaunt();

    cancelAnimationFrame(raf);
    lastT = 0;
    raf = requestAnimationFrame(loop);
  }

  function exitScene() {
    cancelAnimationFrame(raf);
    clearTimeout(hauntTimer);
    AU.stopWind();
    window.removeEventListener("resize", sizeStage);
  }

  function sizeStage() {
    if (!viewport) return;
    const h = viewport.clientHeight;
    const scale = h / VIEW_H;
    const w = sceneW * scale;
    stage.style.width = w + "px";
    svg.setAttribute("width", w);
    svg.setAttribute("height", h);
    placeCamera(true);
  }

  const scale = () => viewport.clientHeight / VIEW_H;

  /* ---------------- actors ---------------- */
  function buildActors() {
    // hotspot rings
    for (const h of def.hotspots) {
      svg.insertAdjacentHTML("beforeend",
        `<g class="hs" data-hs="${h.id}" style="transform:translate(${h.x}px,${h.y}px)">
          <circle class="hotspot-ring" r="16" fill="none" stroke="${A.WARM}" stroke-width="3" opacity=".8"/>
          <circle r="4.5" fill="${A.WARM}"/>
        </g>`);
    }
    // NPCs
    for (const n of def.npcs) {
      const [w, h] = A.NPC_SIZE[n.art];
      svg.insertAdjacentHTML("beforeend",
        `<g class="npc" data-npc="${n.id}" style="transform:translate(${n.x - w/2}px,${groundY - h}px)">${A.NPC_ART[n.art]()}</g>`);
      if (n.hiddenUntil && !PF.flag("npcvis_" + n.id)) {
        svg.querySelector(`[data-npc="${n.id}"]`).style.display = "none";
      }
      // stay gone across reloads once they've left
      if (n.departFlag && PF.flag(n.departFlag)) {
        svg.querySelector(`[data-npc="${n.id}"]`).style.display = "none";
      }
    }
    // Kessler, always in front
    svg.insertAdjacentHTML("beforeend", `<g id="kessler">${A.kesslerSVG()}</g>`);
  }

  /* Darkness + flashlight (the annex's dead aisle).
     def.darkFrom: scene x where the dark begins — everything right of it is
     swallowed except a light circle that follows Kessler. */
  function buildDarkness() {
    const from = def.darkFrom || 0;
    const fade = 170;
    svg.insertAdjacentHTML("beforeend", `
      <defs>
        <radialGradient id="dkg">
          <stop offset="0" stop-color="#000"/><stop offset=".7" stop-color="#111"/><stop offset="1" stop-color="#fff"/>
        </radialGradient>
        <linearGradient id="dkfade" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stop-color="#03050a" stop-opacity="0"/>
          <stop offset="1" stop-color="#03050a" stop-opacity="1"/>
        </linearGradient>
        <mask id="dkmask">
          <rect x="0" y="0" width="${sceneW}" height="720" fill="#fff"/>
          <circle id="dk-hole" cx="${def.spawnX}" cy="${groundY - 90}" r="235" fill="url(#dkg)"/>
        </mask>
      </defs>
      <g id="dark-layer" opacity=".86" mask="url(#dkmask)">
        <rect x="${from}" y="0" width="${fade}" height="720" fill="url(#dkfade)"/>
        <rect x="${from + fade}" y="0" width="${Math.max(0, sceneW - from - fade)}" height="720" fill="#03050a"/>
      </g>`);
    // Kessler must render above the darkness
    const k = svg.querySelector("#kessler");
    if (k) svg.appendChild(k);
  }

  function placeKessler() {
    const k = svg.querySelector("#kessler");
    if (!k) return;
    const flip = facing < 0 ? ` translate(${K_W}px, 0) scale(-1,1)` : "";
    k.style.transform = `translate(${kx - K_W/2}px, ${groundY - K_H}px)${flip}`;
    const hole = svg.querySelector("#dk-hole");
    if (hole) { hole.setAttribute("cx", kx); hole.setAttribute("cy", groundY - 90); }
  }

  function camTarget() {
    const vw = viewport.clientWidth;
    const stW = sceneW * scale();
    let cam = kx * scale() - vw / 2;
    cam = Math.max(0, Math.min(stW - vw, cam));
    if (stW <= vw) cam = (stW - vw) / 2;
    return cam;
  }
  function placeCamera(instant) {
    if (!viewport || !stage) return;
    const t = camTarget();
    if (instant || !camInit) { camX = t; camInit = true; }
    stage.style.transform = `translateX(${-camX}px)`;
  }

  /* ---------------- movement ---------------- */
  function loop(t) {
    raf = requestAnimationFrame(loop);
    if (!lastT) { lastT = t; return; }
    const dt = Math.min(0.05, (t - lastT) / 1000);
    lastT = t;
    const k = svg && svg.querySelector("#kessler");
    if (!k) return;
    // eased camera
    const ct = camTarget();
    if (Math.abs(ct - camX) > 0.5) {
      camX += (ct - camX) * Math.min(1, dt * 6);
      stage.style.transform = `translateX(${-camX}px)`;
    }
    const d = ktarget - kx;
    if (Math.abs(d) > 4) {
      facing = d > 0 ? 1 : -1;
      kx += Math.sign(d) * Math.min(Math.abs(d), SPEED * dt);
      k.classList.add("walking");
      stepT += dt;
      if (stepT > 0.32) { stepT = 0; AU.sfx.step(); }
      placeKessler();
    } else if (k.classList.contains("walking")) {
      k.classList.remove("walking");
      placeKessler();
      const cb = walkCb; walkCb = null;
      cb && cb();
    }
  }

  function walkTo(x, cb) {
    ktarget = Math.max(60, Math.min(sceneW - 60, x));
    walkCb = cb || null;
    // Already standing at the target (e.g. re-tapping the same NPC/hotspot): the loop's
    // arrival branch won't fire, so run the callback now. Also keeps interactions working
    // when requestAnimationFrame is paused (e.g. a backgrounded tab).
    if (Math.abs(ktarget - kx) <= 4 && walkCb) {
      const cb2 = walkCb; walkCb = null; cb2();
    }
  }

  /* ---------------- tap routing ---------------- */
  function onTap(e) {
    if (dlgOpen || !$("#overlay").classList.contains("hidden")) return;
    const r = svg.getBoundingClientRect();
    const sx = (e.clientX - r.left) / r.width * sceneW;
    const sy = (e.clientY - r.top) / r.height * VIEW_H;

    // collect every interactive thing near the tap, then take the closest
    const candidates = [];
    for (const n of def.npcs) {
      const g = svg.querySelector(`[data-npc="${n.id}"]`);
      if (!g || g.style.display === "none") continue;
      const [w, h] = A.NPC_SIZE[n.art];
      if (sx > n.x - w/2 - 20 && sx < n.x + w/2 + 20 && sy > groundY - h - 30) {
        candidates.push({
          dist: Math.hypot(sx - n.x, sy - (groundY - h/2)),
          stand: n.x + (kx < n.x ? -(w/2 + 90) : (w/2 + 90)),
          act: () => interactNPC(n),
        });
      }
    }
    for (const h of def.hotspots) {
      const g = svg.querySelector(`[data-hs="${h.id}"]`);
      if (!g || g.style.display === "none") continue;
      const d = Math.hypot(sx - h.x, sy - h.y);
      if (d < 95) {
        candidates.push({
          dist: d,
          stand: h.x + (kx < h.x ? -95 : 95),
          act: () => interactHotspot(h),
        });
      }
    }
    if (candidates.length) {
      candidates.sort((a, b) => a.dist - b.dist);
      const c = candidates[0];
      walkTo(c.stand, c.act);
      return;
    }
    // plain walk
    if (selItem) { selItem = null; renderInventory(); }
    walkTo(sx);
  }

  /* ---------------- hotspots ---------------- */
  function refreshHotspots() {
    for (const h of def.hotspots) {
      const g = svg.querySelector(`[data-hs="${h.id}"]`);
      if (!g) continue;
      let vis = true;
      if (h.showFlag) vis = PF.flag(h.showFlag);
      else if (h.hidden) {
        if (sceneId === "storage") vis = PF.flag("g_talked");
        if (sceneId === "motel") vis = PF.flag("w3_gone");
      }
      if (h.pickup && PF.hasItem(h.pickup)) vis = false;
      if (h.isNote && PF.flag("note_read")) vis = false;
      if (h.isFinale && PF.flag("wall_read")) vis = false;
      if (h.worldPuzzle && PF.S.solved[h.worldPuzzle]) vis = false;
      if (h.gives && PF.flag("got_" + h.id) && h.hideAfter) vis = false;
      g.style.display = vis ? "" : "none";
    }
  }

  function interactHotspot(h) {
    // reveal an NPC (Gerald behind the unit 14 door)
    if (h.npcTrigger) {
      const n = def.npcs.find(x => x.id === h.npcTrigger);
      const g = svg.querySelector(`[data-npc="${n.id}"]`);
      if (g.style.display === "none") {
        g.style.display = "";
        PF.setFlag("npcvis_" + n.id);
        AU.sfx.paper();
      }
      interactNPC(n);
      return;
    }
    if (h.pickup) {
      PF.addItem(h.pickup);
      PF.toast(h.toastText || "Taken.");
      renderInventory();
      refreshHotspots();
      return;
    }
    if (h.worldPuzzle) {
      if (h.needsFlag && !PF.flag(h.needsFlag)) { PF.narrate(h.examineLocked); return; }
      if (h.needsItem && !PF.hasItem(h.needsItem)) { PF.narrate(h.examineLocked); return; }
      PF_FILE.openWorldPuzzle(h.worldPuzzle, () => onWorldPuzzleSolved(h));
      return;
    }
    if (h.isFinale) {
      showWall();
      return;
    }
    if (h.gives) {
      if (!PF.flag("got_" + h.id)) {
        PF.setFlag("got_" + h.id);
        if (h.id === "h_boxes") PF.setFlag("w1_boxes");
        (h.gives || []).forEach(d => PF.addDoc(d));
        if (h.givesItem2) PF.addItem(h.givesItem2);
        PF.narrate(h.examine, () => {
          PF.toast(h.toastText || "Evidence noted.");
          renderInventory();
          checkExit();
        });
      } else {
        PF.narrate(h.examineAfter || "The rest is cardboard and alphabetized fear.");
      }
      return;
    }
    if (h.needs) {
      if (PF.flag("got_" + h.id)) { PF.narrate(h.examineAfter || "Nothing more here."); return; }
      if (!PF.flag(h.needs)) { PF.narrate(h.examineLocked); return; }
      startDialogue(h.npcTalk, def.npcs[0]);
      return;
    }
    if (h.isNote) {
      showNote();
      return;
    }
    if (h.examine) PF.narrate(h.examine);
  }

  /* ---------------- world puzzles (locker dial, payphone) ---------------- */
  function onWorldPuzzleSolved(h) {
    refreshHotspots();
    if (h.worldPuzzle === "vault") {
      // locker 44 swings open: the ledger page and the second note
      PF.addDoc("d_page"); PF.addDoc("d_note2");
      const d = D.docs.find(x => x.id === "d_note2");
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll">
          <div class="paper"><div class="stamp-red">LOCKER 44</div>${d.body}</div></div>
        <div class="ov-bar"><button class="action-btn" id="note2-take">TAKE EVERYTHING</button></div>`;
      AU.sfx.paperBig();
      $("#note2-take").addEventListener("click", () => {
        ov.classList.add("hidden"); ov.innerHTML = "";
        PF.setFlag("note2_read");
        PF.toast("Taken: ledger page + the second note.");
        exitScene();
        PF.completeWorld("terminal");
      });
    }
    if (h.worldPuzzle === "phone") {
      PF.setFlag("phone_done");
      PF.addDoc("d_call");
      const d = D.docs.find(x => x.id === "d_call");
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll">
          <div class="paper"><div class="stamp-red">11 SEC</div>${d.body}</div></div>
        <div class="ov-bar"><button class="action-btn" id="ph-up">HANG UP</button></div>`;
      $("#ph-up").addEventListener("click", () => {
        ov.classList.add("hidden"); ov.innerHTML = "";
        checkExit();
        if (!PF.flag("phone_after")) {
          PF.setFlag("phone_after");
          setTimeout(() => {
            AU.sfx.ring1();
            PF.narrate("Halfway back across the lot, the phone rang once. Just once. I didn't answer, and it didn't seem to mind.");
          }, 4500);
        }
      });
    }
  }

  /* ---------------- the notes & the wall ---------------- */
  function showNote() {
    const d = D.docs.find(x => x.id === "d_note");
    const ov = $("#overlay");
    ov.classList.remove("hidden");
    ov.innerHTML = `<div class="ov-scroll">
        <div class="paper"><div class="stamp-red">EVIDENCE</div>${d.body}</div></div>
      <div class="ov-bar"><button class="action-btn" id="note-take">TAKE THE NOTE</button></div>`;
    AU.sfx.paperBig();
    $("#note-take").addEventListener("click", () => {
      ov.classList.add("hidden"); ov.innerHTML = "";
      PF.setFlag("note_read");
      refreshHotspots();
      PF.narrate(D.narration.world3_note, () => {
        exitScene();
        PF.completeWorld("motel");
      });
    });
  }

  function showWall() {
    const d = D.docs.find(x => x.id === "d_wall");
    PF.addDoc("d_wall");
    const ov = $("#overlay");
    ov.classList.remove("hidden");
    ov.innerHTML = `<div class="ov-scroll">
        <div class="paper"><div class="stamp-red">ACCT 0001</div>${d.body}</div></div>
      <div class="ov-bar"><button class="action-btn" id="wall-close">CLOSE THE BOOK</button></div>`;
    AU.sfx.paperBig();
    $("#wall-close").addEventListener("click", () => {
      ov.classList.add("hidden"); ov.innerHTML = "";
      PF.setFlag("wall_read");
      refreshHotspots();
      // the lamp dips while she reads you out
      const lamp = svg.querySelector("#hx-lamp");
      if (lamp) { lamp.style.transition = "opacity 2.5s"; lamp.style.opacity = ".15"; }
      AU.sfx.heartbeat();
      PF.narrate(D.narration.world7_wall, () => {
        const ab = def.npcs.find(n => n.id === "abernathy");
        dlgOpen = true; showDlgBox();
        runLines(D.dialogue.a_end.lines.slice(), ab, () => {
          closeDialogue();
          exitScene();
          PF.completeWorld("lakehouse");
        });
      });
    });
  }

  /* ---------------- NPCs & items ---------------- */
  function interactNPC(n) {
    // Once the Whitlocks have left (or are mid-departure) they're no longer here to talk to.
    if (n.id === "whitlocks" && (PF.flag("w3_gone") || whitlocksLeaving)) return;
    if (selItem) {
      const resp = n.itemResponses && n.itemResponses[selItem];
      const item = selItem;
      selItem = null; renderInventory();
      if (typeof resp === "string") { startDialogue(resp, n); }
      else if (resp) { dlgOpen = true; showDlgBox(); runLines(resp.lines.slice(), n, () => closeDialogue()); }
      else PF.narrate("They looked at it. It didn't change anything.");
      return;
    }
    // Whitlocks are mid-argument the first time you approach
    if (n.id === "whitlocks" && !PF.flag("w3_heard")) {
      PF.setFlag("w3_heard");
      PF.setFlag("met_" + n.id);
      dlgOpen = true; showDlgBox();
      runLines(D.dialogue.r_ambient.slice(), n, () => playNode(n.dialogue, n));
      return;
    }
    if (!PF.flag("met_" + n.id)) {
      PF.setFlag("met_" + n.id);
      startDialogue(n.dialogue, n);
    } else {
      startDialogue(n.hub, n);
    }
  }

  /* ---------------- dialogue engine ---------------- */
  function showDlgBox() {
    const box = $("#dialogue");
    box.classList.remove("hidden");
    box.innerHTML = "";
  }
  function closeDialogue() {
    dlgOpen = false;
    $("#dialogue").classList.add("hidden");
    $("#dialogue").innerHTML = "";
  }

  function startDialogue(nodeId, npc) {
    dlgOpen = true;
    showDlgBox();
    playNode(nodeId, npc);
  }

  function playNode(nodeId, npc) {
    const node = D.dialogue[nodeId];
    if (!node) { closeDialogue(); return; }
    if (node.options) { showHub(nodeId, npc); return; }   // it's a hub
    runLines((node.lines || []).slice(), npc, () => {
      if (node.sets) { PF.setFlag(node.sets); refreshHotspots(); }
      if (node.onEnd) { closeDialogue(); handleEvent(node.onEnd, npc); return; }
      if (node.choices) { showHub(node.choices, npc); return; }
      closeDialogue();
    });
  }

  function portraitHTML(speaker) {
    const src = A.PORTRAITS[speaker];
    if (!src) return "";
    return `<div class="dlg-port"><img src="${src}" alt=""><div class="dlg-clip"></div></div>`;
  }

  function runLines(lines, npc, done) {
    const box = $("#dialogue");
    let typer = null;
    function next() {
      const line = lines.shift();
      if (!line) { done && done(); return; }
      const [speaker, text] = line;
      box.innerHTML = `<div class="dlg-row">${portraitHTML(speaker)}
        <div class="dlg-main"><div class="dlg-speaker">${speaker}</div>
        <div class="dlg-text"></div><div class="dlg-tap">TAP ▸</div></div></div>`;
      const t = box.querySelector(".dlg-text");
      let i = 0;
      AU.sfx.paper();
      typer = setInterval(() => {
        i += 2;
        t.textContent = text.slice(0, i);
        if (i >= text.length) { clearInterval(typer); typer = null; }
      }, 16);
      const adv = (e) => {
        e.stopPropagation();
        if (typer) { clearInterval(typer); typer = null; t.textContent = text; return; }
        box.removeEventListener("pointerdown", adv);
        next();
      };
      box.addEventListener("pointerdown", adv);
    }
    next();
  }

  function showHub(hubId, npc) {
    const hub = D.dialogue[hubId];
    const box = $("#dialogue");
    const opts = hub.options.filter(o => !o.needs || PF.flag(o.needs));
    const spk = hub.speaker || (npc && npc.name) || "";
    box.innerHTML = `<div class="dlg-row">${portraitHTML(spk)}
      <div class="dlg-main"><div class="dlg-speaker">${spk}</div>
      <div class="dlg-choices">${opts.map((o, i) =>
        `<button class="dlg-choice" data-i="${i}">${o.label}</button>`).join("")}</div></div></div>`;
    box.querySelectorAll(".dlg-choice").forEach(b => {
      b.addEventListener("click", (e) => {
        e.stopPropagation();
        const o = opts[+b.getAttribute("data-i")];
        if (!o.node) { closeDialogue(); return; }
        playNode(o.node, npc);
      });
    });
  }

  /* ---------------- scripted events ---------------- */
  function handleEvent(evt, npc) {
    if (evt === "world1_complete") {
      PF.setFlag("w1_match");
      PF.narrate("The Spoon. Every town has a room where the quiet business happens. Millhaven's serves pie.", checkExit);
    }
    if (evt === "give_ticket") {
      PF.addItem("ticket");
      PF.setFlag("got_h_spike");
      PF.toast("Taken: this morning's ticket — table six, 6:48 AM.");
      renderInventory(); checkExit();
    }
    if (evt === "give_gas") {
      PF.addItem("gasreceipt");
      PF.setFlag("got_h_booth6");
      PF.toast("Found: a gas receipt — Route 9 Fuel, 7:41 AM.");
      renderInventory(); checkExit();
    }
    if (evt === "give_slip") {
      PF.addItem("claimslip");
      PF.toast("Taken: claim slip — UNION TERMINAL, LOCKER 44.");
      renderInventory(); checkExit();
    }
    if (evt === "give_map") {
      PF.addItem("greasemap");
      PF.setFlag("got_h_map");
      PF.toast("Taken: county map — grease pencil. 'House line — 0114.'");
      renderInventory(); checkExit();
    }
    if (evt === "whitlocks_leave") {
      whitlocksLeaving = true;
      const g = svg.querySelector(`[data-npc="whitlocks"]`);
      if (g) {
        const [w, h] = A.NPC_SIZE.npc_whitlocks;
        g.style.transition = "transform 2.4s ease-in, opacity 2.4s";
        g.style.transform = `translate(${sceneW + 100}px, ${groundY - h}px)`;
        g.style.opacity = "0";
      }
      setTimeout(() => {
        if (g) g.style.display = "none";
        PF.setFlag("w3_gone");
        refreshHotspots();
        PF.narrate(D.narration.world3_gone);
      }, 2400);
    }
  }

  /* ---------------- haunts (once per visit, small and deniable) ---------------- */
  function scheduleHaunt() {
    clearTimeout(hauntTimer);
    if (!def.haunt) return;
    hauntTimer = setTimeout(() => runHaunt(def.haunt), 12000 + Math.random() * 9000);
  }
  function runHaunt(kind) {
    if (!svg) return;
    const el = (id) => svg.querySelector(id);
    if (kind === "storage") {
      const door = el("#hx-door");
      if (door) {
        door.style.animation = "none";
        let n = 0;
        const iv = setInterval(() => {
          door.style.opacity = (n % 2) ? "1" : ".1";
          if (++n > 5) { clearInterval(iv); door.style.opacity = ""; door.style.animation = ""; }
        }, 120);
      }
      AU.sfx.rattle();
    }
    if (kind === "diner") {
      const j = el("#hx-juke");
      if (j) { j.style.transition = "opacity .4s"; j.style.opacity = "1"; setTimeout(() => j.style.opacity = "0", 1600); }
      AU.sfx.jukebox();
    }
    if (kind === "motel") {
      const b = el("#hx-bath");
      if (b) { b.style.animation = "none"; b.style.opacity = "0"; setTimeout(() => { b.style.opacity = ".5"; b.style.animation = ""; }, 1100); }
      AU.sfx.thud();
    }
    if (kind === "annex") {
      const f = el("#hx-flor");
      if (f) {
        f.style.animation = "none";
        let n = 0;
        const iv = setInterval(() => {
          f.style.opacity = (n % 2) ? ".07" : ".01";
          if (++n > 3) { clearInterval(iv); f.style.opacity = ""; f.style.animation = ""; }
        }, 150);
      }
      AU.sfx.thud();
    }
    if (kind === "terminal") {
      const b = el("#hx-board");
      if (b) {
        AU.sfx.flap();
        b.style.transition = "opacity .3s"; b.style.opacity = "1";
        setTimeout(() => { AU.sfx.flap(); b.style.opacity = "0"; }, 2800);
      }
    }
    if (kind === "gas") {
      const p = el("#hx-pump"), t = el("#hx-pump-n");
      if (p && t) {
        p.style.transition = "opacity .3s"; p.style.opacity = "1";
        const seq = ["18.2","24.7","09.1","31.4","44.0","11.52"];
        let n = 0;
        const iv = setInterval(() => {
          t.textContent = seq[n]; AU.sfx.tick();
          if (++n >= seq.length) { clearInterval(iv); setTimeout(() => p.style.opacity = "0", 1400); }
        }, 260);
      }
    }
    if (kind === "lakehouse") {
      const l = el("#hx-lamp");
      if (l && !PF.flag("wall_read")) {
        l.style.transition = "opacity 2.2s"; l.style.opacity = ".12";
        AU.sfx.heartbeat();
        setTimeout(() => { l.style.opacity = ""; l.style.transition = ""; }, 4200);
      }
    }
  }

  /* ---------------- exit condition ---------------- */
  function exitReady() {
    if (sceneId === "storage")  return PF.flag("w1_match") && PF.flag("w1_boxes");
    if (sceneId === "diner")    return PF.hasItem("ticket") && PF.hasItem("gasreceipt");
    if (sceneId === "motel")    return PF.flag("note_read");
    if (sceneId === "annex")    return PF.hasItem("claimslip") && PF.flag("got_h_box31c");
    if (sceneId === "terminal") return PF.S.solved.vault && PF.flag("note2_read");
    if (sceneId === "gas")      return PF.flag("phone_done");
    if (sceneId === "lakehouse")return PF.flag("wall_read");
    return false;
  }
  function checkExit(silent) {
    const b = $("#w-return");
    if (!b) return;
    // Terminal/lakehouse normally auto-complete through their note flows; the button
    // only surfaces as a self-heal when a reload left the flag set but the scene un-exited.
    if (exitReady()) {
      const wasHidden = b.classList.contains("hidden");
      b.classList.remove("hidden");
      if (wasHidden && !silent) { AU.sfx.good(); PF.toast("Core evidence in hand. Back to the desk."); }
      b.onclick = () => { exitScene(); PF.completeWorld(sceneId); };
    }
  }

  /* ---------------- inventory ---------------- */
  function renderInventory() {
    const bar = $("#inv-bar");
    if (!bar) return;
    bar.innerHTML = `<div class="inv-label">EVIDENCE</div>` +
      PF.S.inventory.map(id => {
        const it = D.items[id];
        return `<div class="inv-item ${selItem === id ? "sel" : ""}" data-item="${id}">${A.INV_ICONS[it.icon]}</div>`;
      }).join("");
    bar.querySelectorAll(".inv-item").forEach(el => {
      el.addEventListener("pointerdown", (e) => {
        e.stopPropagation();
        const id = el.getAttribute("data-item");
        if (selItem === id) { selItem = null; }
        else {
          selItem = id;
          AU.sfx.pickup();
          PF.toast(`${D.items[id].name} — ${D.items[id].desc}  Tap someone to show it.`);
        }
        renderInventory();
      });
    });
  }

  /* ---------------- test hook (bypasses rAF-based walk; harness only) ----------------
     The preview tab runs hidden, which pauses requestAnimationFrame, so tap-to-walk
     can't be driven from automation. These helpers teleport Kessler and fire the same
     interaction handlers a real tap would, exercising all game logic without the loop. */
  function _warp(x) { kx = x; ktarget = x; placeKessler(); placeCamera(true); }
  function _hotspot(id) {
    const h = def.hotspots.find(x => x.id === id);
    if (!h) return "no hotspot " + id;
    _warp(h.x + (kx < h.x ? -95 : 95));
    interactHotspot(h);
    return "ok";
  }
  function _npc(id) {
    const n = def.npcs.find(x => x.id === id);
    if (!n) return "no npc " + id;
    const [w] = A.NPC_SIZE[n.art];
    _warp(n.x + (kx < n.x ? -(w/2 + 90) : (w/2 + 90)));
    interactNPC(n);
    return "ok";
  }
  function _selectItem(id) { selItem = id; renderInventory(); }

  return { enter, exitScene, _test: { warp:_warp, hotspot:_hotspot, npc:_npc, selectItem:_selectItem, haunt:(k)=>runHaunt(k) } };
})();
