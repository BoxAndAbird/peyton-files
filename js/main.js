/* THE PEYTON FILES — core: state machine, save, transitions, interludes.
   Three episodes, one spine. The router is data-driven off PF_DATA.chapterMeta. */
"use strict";

const PF = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  /* ---------------- state ---------------- */
  const SOLVED_KEYS = ["photo","redact","crossref","cipher","timeline","string",
                       "redact2","crossref2","cipher2","timeline2","vault",
                       "photo3","cipher3","timeline3","string2","phone"];
  const freshState = () => ({
    chapter: "cold",
    solved: SOLVED_KEYS.reduce((o,k)=>(o[k]=false,o),{}),
    flags: {},
    inventory: ["badge"],
    docs: [],
    seen: [],
    connections: [],          // board red string, pairs of pin ids
    kx: {},                   // remembered Kessler x per scene
  });
  let S = freshState();

  const lsGet = (k) => { try { return localStorage.getItem(k); } catch(e) { return null; } };
  function save() { try { localStorage.setItem("pf.save", JSON.stringify(S)); } catch(e){} }
  function load() {
    try {
      const raw = lsGet("pf.save");
      if (!raw) return false;
      const s = JSON.parse(raw);
      if (!s || !s.chapter) return false;
      S = Object.assign(freshState(), s);
      S.solved = Object.assign(freshState().solved, s.solved || {});
      if (S.chapter === "epilogue") S.chapter = "ep1end";   // v1 save migration
      if (!D.chapterMeta[S.chapter]) S.chapter = "cold";
      return true;
    } catch(e) { return false; }
  }
  function reset() { S = freshState(); save(); }

  const flag = (k) => !!S.flags[k];
  function setFlag(k) { S.flags[k] = true; save(); }
  const hasItem = (id) => S.inventory.includes(id);
  function addItem(id) { if (!hasItem(id)) { S.inventory.push(id); save(); AU.sfx.pickup(); } }
  const hasDoc = (id) => S.docs.includes(id);
  function addDoc(id) { if (!hasDoc(id)) { S.docs.push(id); save(); } }

  /* Grant every doc belonging to a file chapter when we arrive there. */
  function grantChapterDocs(ch) {
    D.docs.filter(d => d.chapter === ch).forEach(d => addDoc(d.id));
  }

  /* Highest episode the player has reached (for the title's case rack). */
  function epReached() {
    let m = 1;
    for (let e = 2; e <= 3; e++) if (flag("ep" + e + "_reached")) m = e;
    return m;
  }

  /* ---------------- screens ---------------- */
  const SCREENS = ["title-screen","cinema","file-mode","board-mode","world-mode"];
  function showScreen(id) {
    SCREENS.forEach(s => $("#"+s).classList.toggle("hidden", s !== id));
    $("#overlay").classList.add("hidden");
  }

  /* ---------------- fold transition (identical every time) ---------------- */
  let folding = false;
  function foldTo(swap, done) {
    if (folding) return;
    folding = true;
    const f = $("#fold");
    f.classList.remove("hidden","opening");
    f.classList.add("closing");
    AU.sfx.fold();
    setTimeout(() => {
      swap && swap();
      f.classList.remove("closing");
      f.classList.add("opening");
      AU.sfx.fold();
      setTimeout(() => {
        f.classList.add("hidden");
        f.classList.remove("opening");
        folding = false;
        done && done();
      }, 470);
    }, 490);
  }

  /* ---------------- narration (Kessler internal voice) ---------------- */
  const nrQueue = [];
  let nrBusy = false, nrTimer = null, nrFull = "", nrCb = null;
  function narrate(text, cb) {
    if (!text) { cb && cb(); return; }
    nrQueue.push({ text, cb });
    if (!nrBusy) nextNarration();
  }
  function nextNarration() {
    const item = nrQueue.shift();
    if (!item) { nrBusy = false; return; }
    nrBusy = true;
    nrFull = item.text; nrCb = item.cb || null;
    const n = $("#narration");
    n.innerHTML = `<div class="nr-text"></div><div class="nr-tag">— KESSLER &nbsp;·&nbsp; TAP</div>`;
    n.classList.remove("hidden");
    const t = n.querySelector(".nr-text");
    let i = 0;
    AU.sfx.paper();
    nrTimer = setInterval(() => {
      i += 2;
      t.textContent = nrFull.slice(0, i);
      if (i >= nrFull.length) { clearInterval(nrTimer); nrTimer = null; }
    }, 24);
  }
  $("#narration") && $("#narration").addEventListener("pointerdown", (e) => {
    e.stopPropagation();
    const t = $("#narration .nr-text");
    if (nrTimer) { clearInterval(nrTimer); nrTimer = null; t.textContent = nrFull; return; }
    $("#narration").classList.add("hidden");
    const cb = nrCb; nrCb = null;
    cb && cb();
    nextNarration();
  });

  /* ---------------- toast ---------------- */
  let toastTimer = null;
  function toast(text) {
    const el = $("#toast");
    el.textContent = text;
    el.classList.remove("hidden");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.add("hidden"), 2600);
  }

  /* ---------------- title screen ---------------- */
  function renderTitle() {
    const hasSave = !!lsGet("pf.save") && S.chapter !== "cold";
    const reach = epReached();
    const curEp = (D.chapterMeta[S.chapter] || { ep: 1 }).ep;
    const rack = [1,2,3].map(e => {
      const meta = D.episodes[e];
      const locked = e > reach;
      return `<button class="case-tab ${locked ? "locked" : ""} ${e === curEp && hasSave ? "cur" : ""}" data-ep="${e}" ${locked ? "disabled" : ""}>
        <span class="ct-no">${meta.caseNo}</span>
        <span class="ct-t">${meta.num} — ${locked ? "SEALED" : meta.title}</span>
      </button>`;
    }).join("");
    $("#title-screen").innerHTML = `
      <div class="title-bg"><div class="title-rain"></div><div class="title-flash" id="t-flash"></div></div>
      <div class="title-inner">
        <div class="t-case">CASE 0114 — VOSS, P.</div>
        <h1>The Peyton<br>Files</h1>
        <div class="sub">A point-and-click mystery in three episodes.<br>The villain is real. The danger is real.<br>The world around him is not okay.</div>
        ${hasSave ? `<button class="big-btn" id="bt-continue">CONTINUE</button>` :
                    `<button class="big-btn" id="bt-new">OPEN THE FILE</button>`}
        <div class="case-rack">${rack}</div>
        <div class="t-foot">
          ${hasSave ? `<button class="ghost-btn" id="bt-new">start over</button>` : ``}
          <button class="ghost-btn" id="bt-mute">${AU.muted ? "sound: off" : "sound: on"}</button>
        </div>
      </div>`;
    showScreen("title-screen");

    // occasional far-off lightning
    const flash = $("#t-flash");
    let alive = true;
    (function storm() {
      if (!alive || !document.body.contains(flash)) { alive = false; return; }
      setTimeout(() => {
        if (!document.body.contains(flash)) return;
        flash.classList.remove("go"); void flash.offsetWidth; flash.classList.add("go");
        AU.sfx.thunder();
        storm();
      }, 7000 + Math.random() * 9000);
    })();

    const begin = (fn) => { AU.ensure(); AU.resume(); AU.startDrone(); fn(); };
    const bn = $("#bt-new");
    bn && bn.addEventListener("click", () => begin(() => { reset(); goto("cold"); }));
    const bc = $("#bt-continue");
    bc && bc.addEventListener("click", () => begin(() => goto(S.chapter, true)));
    document.querySelectorAll(".case-tab:not(.locked)").forEach(b => {
      b.addEventListener("click", () => begin(() => {
        const ep = +b.getAttribute("data-ep");
        const start = D.episodes[ep].start;
        if ((D.chapterMeta[S.chapter] || {}).ep === ep && lsGet("pf.save")) { goto(S.chapter, true); return; }
        skipTo(start);
      }));
    });
    $("#bt-mute").addEventListener("click", (e) => {
      AU.setMuted(!AU.muted);
      e.target.textContent = AU.muted ? "sound: off" : "sound: on";
    });
  }

  /* ---------------- chapter router ---------------- */
  const CH = D.chapters;
  function nextChapter(ch) { return CH[CH.indexOf(ch) + 1] || "finale"; }

  function goto(ch, resuming) {
    const meta = D.chapterMeta[ch];
    if (!meta) return;
    S.chapter = ch; save();
    if (meta.ep >= 2 && !flag("ep" + meta.ep + "_reached")) setFlag("ep" + meta.ep + "_reached");
    AU.setMood(meta.ep === 3 ? "lake" : meta.ep === 2 ? "cold" : "warm");

    if (meta.type === "cut") {
      PF_CINEMA.play(meta.cut, () => goto(meta.next));
      return;
    }
    if (meta.type === "file" || meta.type === "inter") {
      grantChapterDocs(ch);
      foldTo(() => { showScreen("file-mode"); PF_FILE.render(); }, () => {
        const nk = "nr_" + ch + "_intro";
        if (D.narration[ch + "_intro"] && !flag(nk)) { setFlag(nk); narrate(D.narration[ch + "_intro"]); }
        // Interludes always (re)run on entry — including reload/resume — so an
        // episode ending can never be permanently skipped.
        if (meta.type === "inter") runInterlude(ch);
      });
      return;
    }
    if (meta.type === "world") {
      foldTo(() => { showScreen("world-mode"); PF_WORLD.enter(meta.scene); }, () => {
        const key = "nr_" + ch + "_arrive";
        if (!flag(key)) { setFlag(key); narrate(D.narration[ch + "_arrive"]); }
      });
    }
  }

  /* Travel from file → world (location card GO button) */
  function travel(sceneId) {
    const ch = CH.find(c => (D.chapterMeta[c] || {}).scene === sceneId);
    if (ch) goto(ch);
  }

  /* World scene finished → back to the file, next chapter */
  function completeWorld(sceneId) {
    const ch = CH.find(c => (D.chapterMeta[c] || {}).scene === sceneId);
    const meta = D.chapterMeta[ch];
    const nxt = meta.next;
    if (meta.doneNr && !flag("nr_" + meta.doneNr)) {
      setFlag("nr_" + meta.doneNr);
      narrate(D.narration[meta.doneNr], () => goto(nxt));
    } else goto(nxt);
  }

  /* ---------------- interludes (episode endings) ---------------- */
  function runInterlude(ch) {
    const it = D.interludes[ch];
    if (!it) return;
    setFlag(ch + "_started");
    const afterStamp = () => {
      setTimeout(() => {
        if (it.ringCard) AU.sfx.ring();
        narrate(D.narration[it.ringNr], () => {
          if (it.ringCard) showRingCard(it);
          else runStinger(it);
        });
      }, it.ringCard ? 1500 : 500);
    };
    if (it.stampTo) {
      setTimeout(() => {
        AU.sfx.stamp();
        PF_FILE.setStamp(it.stampTo);
        toast(it.stampToast);
        afterStamp();
      }, 900);
    } else afterStamp();
  }

  function showRingCard(it) {
    const ov = $("#overlay");
    ov.classList.remove("hidden");
    ov.innerHTML = `<div class="ov-scroll">
      <div class="paper" style="text-align:center">
        <h3>${it.ringCard.k}</h3>
        <p style="font-style:italic">${it.ringCard.n}</p>
        <p class="hand pencil">${it.ringCard.s}</p>
      </div></div>
      <div class="ov-bar"><button class="action-btn" id="it-next">ONE LAST LOOK AT THE DESK</button></div>`;
    $("#it-next").addEventListener("click", () => runStinger(it));
  }

  /* ---------------- stingers ---------------- */
  function runStinger(it) {
    const kind = it.stinger;
    if (kind === "odom") stingerOdom(it);
    else if (kind === "page") stingerPage(it);
    else if (kind === "check") stingerCheck(it);
    else finishInterlude(it);
  }

  function stingerOdom(it) {
    narrate(D.narration.stinger, () => {
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll" style="justify-content:center">
        <div class="polaroid" style="overflow:hidden">
          <div id="sting-zoom" style="transition:transform 4.5s ease-in-out;transform-origin:50% 56%">${A.stingerSVG()}</div>
          <div class="ph-cap" id="sting-cap">surveillance still — Odom's file, undated</div>
        </div></div>
        <div class="ov-bar"><button class="action-btn hidden" id="it-end"></button></div>`;
      AU.sfx.paperBig();
      setTimeout(() => {
        const z = $("#sting-zoom");
        if (z) z.style.transform = "scale(2.6)";
      }, 600);
      setTimeout(() => {
        const ring = document.getElementById("odom-ring");
        if (ring) { ring.style.transition = "opacity .6s"; ring.style.opacity = "1"; }
        AU.sfx.stamp();
        const cap = $("#sting-cap");
        if (cap) { cap.innerHTML = "…Odom?"; cap.style.fontSize = "20px"; }
        armFinishButton(it);
      }, 4400);
    });
  }

  function stingerPage(it) {
    narrate(D.narration.ep2_stinger, () => {
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll" style="justify-content:center">
        <div class="paper ledger-sting">
          <h3>Ledger — Vol. 1, p. 118</h3>
          <p class="receipt">ACCT 0001 — WHITMORE, L. · OPENED 1931<br>STATUS ....... SENIOR<br>────────────────────</p>
          <p class="hand" style="font-size:20px;color:#2a251d">NEXT KEEPER: PENDING.</p>
          <p class="hand sting-reveal" id="pg-reveal" style="font-size:20px;color:#7d1a17">SEE: WHITMORE.</p>
          <p class="hand pencil" id="pg-cap" style="opacity:0;transition:opacity .8s">…the ink hadn't dried. It still hasn't. — M.K.</p>
        </div></div>
        <div class="ov-bar"><button class="action-btn hidden" id="it-end"></button></div>`;
      AU.sfx.paperBig();
      setTimeout(() => { const r = $("#pg-reveal"); if (r) r.classList.add("show"); AU.sfx.stamp(); }, 2400);
      setTimeout(() => { const c = $("#pg-cap"); if (c) c.style.opacity = "1"; armFinishButton(it); }, 3600);
    });
  }

  function stingerCheck(it) {
    narrate(D.narration.finale_check, () => {
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll" style="justify-content:center">
        <div class="paper" style="max-width:340px">
          <p class="receipt" style="text-align:center">THE COPPER SPOON — MILLHAVEN<br>
          FRI &nbsp;8:02 AM &nbsp;—&nbsp; TBL 2 &nbsp;—&nbsp; GUESTS: 1<br>
          ────────────────────<br>
          1 &nbsp;COFFEE, BLACK ........ 3.00<br>
          <span id="ck-tip" class="sting-reveal">&nbsp;&nbsp;&nbsp;TIP .................. 0.60</span><br>
          ────────────────────<br>
          PAID CASH — NO CHANGE TAKEN</p>
          <p class="hand pencil" id="ck-cap" style="opacity:0;transition:opacity .8s">Twenty percent. To the penny.<br>When did I stop rounding? — M.K.</p>
        </div></div>
        <div class="ov-bar"><button class="action-btn hidden" id="it-end"></button></div>`;
      AU.sfx.paperBig();
      setTimeout(() => { const r = $("#ck-tip"); if (r) r.classList.add("show"); AU.sfx.pin(); }, 2000);
      setTimeout(() => { const c = $("#ck-cap"); if (c) c.style.opacity = "1"; AU.sfx.stamp(); armFinishButton(it); }, 3200);
    });
  }

  function armFinishButton(it) {
    const b = $("#it-end");
    if (!b) return;
    b.textContent = it.next ? "CLOSE THE FILE" : "CLOSE THE CASE";
    b.classList.remove("hidden");
    b.addEventListener("click", () => finishInterlude(it));
  }

  function finishInterlude(it) {
    $("#overlay").classList.add("hidden");
    $("#overlay").innerHTML = "";
    if (it.next) episodeCard(it);
    else showEndCard(it);
  }

  /* Next-episode title card */
  function episodeCard(it) {
    const ep = D.episodes[it.nextEp];
    setFlag("ep" + it.nextEp + "_reached");
    const c = $("#cinema");
    c.innerHTML = `<div class="end-card ep-card">
      <div class="ec-case">${ep.caseNo}</div>
      <div class="st slam-in">${ep.num}</div>
      <h2>${ep.title}</h2>
      <p>${ep.city}</p>
      <button class="big-btn" id="ep-go">${it.nextLabel}</button>
      <button class="ghost-btn" id="ep-later">back to the title</button>
    </div>`;
    showScreen("cinema");
    AU.sfx.stamp();
    $("#ep-go").addEventListener("click", () => goto(it.next));
    $("#ep-later").addEventListener("click", () => renderTitle());
  }

  function showEndCard(it) {
    AU.stopDrone();
    const e = it.endCard;
    const c = $("#cinema");
    c.innerHTML = `<div class="end-card">
      <div class="st">${e.st}</div>
      <h2>${e.title}</h2>
      <p style="white-space:pre-line">${e.lines}</p>
      <button class="big-btn" id="end-again">PLAY AGAIN</button>
      <button class="ghost-btn" id="end-title">back to the title</button>
    </div>`;
    showScreen("cinema");
    $("#end-again").addEventListener("click", () => { reset(); AU.startDrone(); goto("cold"); });
    $("#end-title").addEventListener("click", () => renderTitle());
  }

  /* ---------------- debug / test API ---------------- */
  function skipTo(ch) {
    const order = CH;
    const idx = order.indexOf(ch);
    if (idx < 0) return;
    reset();
    const st = S;
    const mark = (c) => order.indexOf(c) <= idx && order.indexOf(c) >= 0;
    if (mark("world1")) { st.solved.photo = st.solved.redact = true; }
    if (mark("file2"))  { st.flags.g_talked = true; st.flags.w1_match = true; st.flags.w1_boxes = true;
                          st.flags.npcvis_gerald = true; st.flags.met_gerald = true;
                          st.inventory.push("matchbook"); }
    if (mark("world2")) { st.solved.crossref = st.solved.cipher = true; }
    if (mark("file3"))  { st.flags.d_talked = true; st.flags.d_told_today = true; st.flags.met_denise = true;
                          st.inventory.push("ticket","gasreceipt"); st.flags.got_h_spike = st.flags.got_h_booth6 = true; }
    if (mark("world3")) { st.solved.timeline = st.solved.string = true;
                          st.connections.push(["p_storage","p_diner"],["p_diner","p_route9"]); }
    if (mark("ep1end")) { st.flags.w3_gone = true; st.flags.w3_heard = true; st.flags.met_whitlocks = true; st.flags.note_read = true; }
    if (mark("cut2"))   { st.flags.ep2_reached = true; }
    if (mark("world4")) { st.solved.redact2 = st.solved.crossref2 = true; }
    if (mark("file5"))  { st.flags.y_talked = st.flags.y_boxes = st.flags.y_courier = true; st.flags.met_reyes = true;
                          st.flags.got_h_box31c = true; st.inventory.push("indexcard","claimslip"); }
    if (mark("world5")) { st.solved.cipher2 = st.solved.timeline2 = true; }
    if (mark("ep2end")) { st.solved.vault = true; st.flags.w_talked = true; st.flags.met_wes = true; st.flags.note2_read = true; }
    if (mark("cut3"))   { st.flags.ep3_reached = true; }
    if (mark("world6")) { st.solved.photo3 = st.solved.cipher3 = true; }
    if (mark("file7"))  { st.flags.m_talked = st.flags.m_voss = st.flags.m_north = true; st.flags.met_merle = true;
                          st.inventory.push("greasemap"); st.solved.phone = true; st.flags.phone_done = true; }
    if (mark("world7")) { st.solved.timeline3 = st.solved.string2 = true;
                          st.connections.push(["p_locker","p_vol1"],["p_vol1","p_gas"]); }
    if (mark("finale")) { st.flags.a_talked = st.flags.a_ledger = true; st.flags.met_abernathy = true; st.flags.wall_read = true; }
    const m = D.chapterMeta[ch];
    if (m && m.ep >= 2) st.flags.ep2_reached = true;
    if (m && m.ep >= 3) st.flags.ep3_reached = true;
    CH.filter(c => (D.chapterMeta[c] || {}).type === "file" || (D.chapterMeta[c] || {}).type === "inter")
      .forEach(c => { if (mark(c) || c === ch) grantChapterDocs(c); });
    st.chapter = ch; save();
    goto(ch);
  }

  /* ---------------- boot ---------------- */
  function boot() {
    load();
    renderTitle();
    if ("serviceWorker" in navigator && location.protocol !== "file:") {
      navigator.serviceWorker.register("sw.js").catch(()=>{});
    }
    document.addEventListener("pointerdown", () => AU.resume(), { passive:true });
  }
  document.readyState === "loading"
    ? document.addEventListener("DOMContentLoaded", boot)
    : boot();

  return {
    get S() { return S; },
    save, reset, flag, setFlag, hasItem, addItem, hasDoc, addDoc,
    showScreen, foldTo, narrate, toast, goto, travel, completeWorld,
    renderTitle, skipTo, nextChapter, epReached,
  };
})();

window.PF_DEBUG = {
  state: () => PF.S,
  skipTo: (ch) => PF.skipTo(ch),
  goto: (ch) => PF.goto(ch),
};
