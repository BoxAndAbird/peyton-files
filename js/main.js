/* THE PEYTON FILES — core: state machine, save, transitions, cinematics. */
"use strict";

const PF = (() => {
  const D = PF_DATA, A = PF_ART, AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  /* ---------------- state ---------------- */
  const freshState = () => ({
    chapter: "cold",
    solved: { photo:false, redact:false, crossref:false, cipher:false, timeline:false, string:false },
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
    $("#title-screen").innerHTML = `
      <div class="folder">${A.folderSVG()}</div>
      <h1>The Peyton Files</h1>
      <div class="ep">${D.meta.episode}</div>
      <div class="sub">A point-and-click mystery.<br>The villain is real. The danger is real.<br>The world around him is not okay.</div>
      ${hasSave ? `<button class="big-btn" id="bt-continue">CONTINUE</button>
                   <button class="ghost-btn" id="bt-new">start a new case</button>`
                : `<button class="big-btn" id="bt-new">OPEN THE FILE</button>`}
      <button class="ghost-btn" id="bt-mute">${AU.muted ? "sound: off" : "sound: on"}</button>`;
    const start = (fresh) => {
      AU.ensure(); AU.resume(); AU.startDrone();
      if (fresh) { reset(); playColdOpen(); }
      else goto(S.chapter, true);
    };
    $("#bt-new").addEventListener("click", () => start(true));
    const bc = $("#bt-continue");
    bc && bc.addEventListener("click", () => start(false));
    $("#bt-mute").addEventListener("click", (e) => {
      AU.setMuted(!AU.muted);
      e.target.textContent = AU.muted ? "sound: off" : "sound: on";
    });
    showScreen("title-screen");
  }

  /* ---------------- cold open ---------------- */
  function playColdOpen() {
    S.chapter = "cold"; save();
    const c = $("#cinema");
    c.innerHTML = `${A.coldOpenSVG()}
      <div class="cine-caption" id="co-cap">MILLHAVEN &nbsp;·&nbsp; TUESDAY &nbsp;·&nbsp; 11:52 P.M.</div>
      <div class="case-stamp" id="co-stamp">CASE 0114 — VOSS, P.</div>
      <div class="tap-hint">TAP TO SKIP</div>`;
    showScreen("cinema");
    const timers = [];
    timers.push(setTimeout(() => $("#co-cap") && $("#co-cap").classList.add("show"), 700));
    timers.push(setTimeout(() => {
      const st = $("#co-stamp");
      if (st) { st.classList.add("slam"); AU.sfx.stamp(); }
    }, 8200));
    timers.push(setTimeout(finish, 10500));
    let done = false;
    function finish() {
      if (done) return; done = true;
      timers.forEach(clearTimeout);
      goto("file1");
    }
    c.addEventListener("pointerdown", finish, { once:false });
  }

  /* ---------------- chapter router ---------------- */
  const CH = D.chapters;
  function nextChapter(ch) { return CH[CH.indexOf(ch) + 1] || "epilogue"; }

  function goto(ch, resuming) {
    S.chapter = ch; save();
    if (ch === "cold") { playColdOpen(); return; }
    if (ch.startsWith("file") || ch === "epilogue") {
      grantChapterDocs(ch);
      foldTo(() => { showScreen("file-mode"); PF_FILE.render(); }, () => {
        if (ch === "file1" && !flag("nr_file1")) { setFlag("nr_file1"); narrate(D.narration.file1_intro); }
        // Always (re)run the epilogue when this chapter is entered — including on a
        // reload/resume — so the ending can never be permanently skipped.
        if (ch === "epilogue") { setFlag("ep_started"); runEpilogue(); }
      });
    } else if (ch.startsWith("world")) {
      const scene = { world1:"storage", world2:"diner", world3:"motel" }[ch];
      foldTo(() => { showScreen("world-mode"); PF_WORLD.enter(scene); }, () => {
        const key = "nr_" + ch + "_arrive";
        if (!flag(key)) { setFlag(key); narrate(D.narration[ch + "_arrive"]); }
      });
    }
  }

  /* Travel from file → world (location card GO button) */
  function travel(sceneId) {
    const ch = { storage:"world1", diner:"world2", motel:"world3" }[sceneId];
    goto(ch);
  }

  /* World scene finished → back to the file, next chapter */
  function completeWorld(sceneId) {
    const doneNr = { storage:"world1_done", diner:"world2_done", motel:null }[sceneId];
    const nxt = { storage:"file2", diner:"file3", motel:"epilogue" }[sceneId];
    if (doneNr && !flag("nr_" + doneNr)) {
      setFlag("nr_" + doneNr);
      narrate(D.narration[doneNr], () => goto(nxt));
    } else goto(nxt);
  }

  /* ---------------- epilogue ---------------- */
  function runEpilogue() {
    // 1. the stamp turns
    setTimeout(() => {
      AU.sfx.stamp();
      PF_FILE.setStamp("unresolved");
      toast("CASE STATUS: ACTIVE → UNRESOLVED");
      // 2. the phone rings
      setTimeout(() => {
        AU.sfx.ring();
        narrate(D.narration.epilogue_ring, () => {
          const ov = $("#overlay");
          ov.classList.remove("hidden");
          ov.innerHTML = `<div class="ov-scroll">
            <div class="paper" style="text-align:center">
              <h3>${D.epilogue.ringCard.k}</h3>
              <p style="font-style:italic">${D.epilogue.ringCard.n}</p>
              <p class="hand pencil">${D.epilogue.ringCard.s}</p>
            </div></div>
            <div class="ov-bar"><button class="action-btn" id="ep-next">ONE LAST LOOK AT THE DESK</button></div>`;
          $("#ep-next").addEventListener("click", playStinger);
        });
      }, 1700);
    }, 900);
  }

  function playStinger() {
    narrate(D.narration.stinger, () => {
      const ov = $("#overlay");
      ov.classList.remove("hidden");
      ov.innerHTML = `<div class="ov-scroll" style="justify-content:center">
        <div class="polaroid" style="overflow:hidden">
          <div id="sting-zoom" style="transition:transform 4.5s ease-in-out;transform-origin:79% 50%">${A.stingerSVG()}</div>
          <div class="ph-cap" id="sting-cap">surveillance still — Odom's file, undated</div>
        </div></div>
        <div class="ov-bar"><button class="action-btn hidden" id="ep-end">CLOSE THE FILE</button></div>`;
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
        const b = $("#ep-end");
        if (b) b.classList.remove("hidden");
        b && b.addEventListener("click", showEndCard);
      }, 4400);
    });
  }

  function showEndCard() {
    AU.stopDrone();
    const c = $("#cinema");
    c.innerHTML = `<div class="end-card">
      <div class="st">UNRESOLVED</div>
      <h2>${D.epilogue.endTitle}</h2>
      <p style="white-space:pre-line">${D.epilogue.endLines}</p>
      <button class="big-btn" id="end-again">PLAY AGAIN</button>
      <button class="ghost-btn" id="end-title">back to the title</button>
    </div>`;
    showScreen("cinema");
    $("#end-again").addEventListener("click", () => { reset(); AU.startDrone(); playColdOpen(); });
    $("#end-title").addEventListener("click", () => { reset(); renderTitle(); });
  }

  /* ---------------- debug / test API ---------------- */
  function skipTo(ch) {
    reset();
    const order = CH;
    const idx = order.indexOf(ch);
    const st = S;
    const mark = (c) => order.indexOf(c) <= idx;
    if (mark("world1")) { st.solved.photo = st.solved.redact = true; }
    if (mark("file2"))  { st.flags.g_talked = true; st.flags.w1_match = true; st.flags.w1_boxes = true;
                          st.inventory.push("matchbook"); }
    if (mark("world2")) { st.solved.crossref = st.solved.cipher = true; }
    if (mark("file3"))  { st.flags.d_talked = true; st.flags.d_told_today = true;
                          st.inventory.push("ticket","gasreceipt"); }
    if (mark("world3")) { st.solved.timeline = st.solved.string = true;
                          st.connections.push(["p_storage","p_diner"],["p_diner","p_route9"]); }
    if (mark("epilogue")) { st.flags.w3_gone = true; st.flags.note_read = true; }
    ["file1","file2","file3"].forEach(c => { if (mark(c) || c === ch) grantChapterDocs(c); });
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
    renderTitle, skipTo, nextChapter,
  };
})();

window.PF_DEBUG = {
  state: () => PF.S,
  skipTo: (ch) => PF.skipTo(ch),
  goto: (ch) => PF.goto(ch),
};
