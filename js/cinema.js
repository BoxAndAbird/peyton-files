/* THE PEYTON FILES — cinematics.
   Little letterboxed cutscenes: painted stills, a slow creep of the camera,
   typewriter captions, and a case stamp at the end. Tap advances. */
"use strict";

const PF_CINEMA = (() => {
  const AU = PF_AUDIO;
  const $ = (s) => document.querySelector(s);

  /* Each still: img, caption, optional sub-caption, Ken Burns from/to transforms,
     transform-origin, duration, optional CSS filter grade. */
  const CUTS = {
    ep1_open: {
      stills: [
        { img: "art/bg_storage.webp", cap: "MILLHAVEN · TUESDAY · 11:52 P.M.",
          grade: "brightness(.5) saturate(.75) hue-rotate(-8deg)",
          from: "scale(1.22) translate(6%,2%)", to: "scale(1.32) translate(-6%,0%)", origin: "60% 55%", dur: 7500 },
        { img: "art/prop_unit14.webp", cap: "SOMEBODY LEFT THE DOOR OPEN.", sub: "cam 02 · 03:12 a.m.",
          grade: "contrast(1.1)",
          from: "scale(1.05)", to: "scale(1.38)", origin: "50% 44%", dur: 7000 },
      ],
      stamp: "CASE 0114 — VOSS, P.",
    },
    ep2_open: {
      stills: [
        { img: "art/cut_lakecity.webp", cap: "LAKE CITY · THURSDAY · 9:12 A.M.", sub: "they found paper.",
          from: "scale(1.18) translate(-4%,0)", to: "scale(1.28) translate(4%,-2%)", origin: "45% 50%", dur: 7500 },
        { img: "art/bg_annex.webp", cap: "THE RECORDS ANNEX — NIGHT INTAKE.", sub: "nine years of thursdays.",
          grade: "brightness(.8)",
          from: "scale(1.24) translate(6%,0)", to: "scale(1.3) translate(-7%,-1%)", origin: "55% 50%", dur: 7500 },
      ],
      stamp: "CASE 0114-B — THE TRANSFER",
    },
    ep3_open: {
      stills: [
        { img: "art/cut_road.webp", cap: "ROUTE 9 NORTH · FRIDAY NIGHT.", sub: "the fog took the road behind me.",
          from: "scale(1.15)", to: "scale(1.35) translate(0,-4%)", origin: "50% 45%", dur: 7500 },
        { img: "art/cut_lakehouse.webp", cap: "WHITMORE LAKE.", sub: "one lamp, ninety-five years of oil.",
          from: "scale(1.1)", to: "scale(1.45)", origin: "56% 31%", dur: 8000 },
      ],
      stamp: "CASE 0114-C — THE KEEPER",
    },
  };

  let active = false;

  function play(cutId, done) {
    const def = CUTS[cutId];
    const c = $("#cinema");
    if (!def || !c) { done && done(); return; }
    active = true;
    PF.showScreen("cinema");

    let i = -1, timer = null, typeTimer = null, finished = false;

    function finishAll() {
      if (finished) return;
      finished = true;
      clearTimeout(timer); clearInterval(typeTimer);
      active = false;
      c.innerHTML = "";
      done && done();
    }

    function showStamp() {
      clearTimeout(timer);
      c.innerHTML = `
        <div class="cine-letterbox"></div>
        <div class="case-stamp" id="cine-stamp">${def.stamp}</div>
        <div class="tap-hint">TAP ▸</div>`;
      requestAnimationFrame(() => requestAnimationFrame(() => {
        const st = $("#cine-stamp");
        if (st) { st.classList.add("slam"); AU.sfx.stamp(); }
      }));
      timer = setTimeout(finishAll, 2600);
    }

    function next() {
      clearTimeout(timer); clearInterval(typeTimer);
      i++;
      if (i >= def.stills.length) { showStamp(); return; }
      const s = def.stills[i];
      c.innerHTML = `
        <div class="cine-frame">
          <img class="cine-img" src="${s.img}" alt=""
               style="transform:${s.from};transform-origin:${s.origin || "50% 50%"};${s.grade ? `filter:${s.grade};` : ""}">
          <div class="cine-grain"></div>
        </div>
        <div class="cine-letterbox"></div>
        <div class="cine-caption"><span class="cc-main"></span><span class="cc-sub"></span></div>
        <div class="tap-hint">TAP ▸</div>`;
      const img = c.querySelector(".cine-img");
      // kick the Ken Burns drift on the next frame
      requestAnimationFrame(() => requestAnimationFrame(() => {
        img.style.transition = `transform ${s.dur}ms linear`;
        img.style.transform = s.to;
      }));
      // typewriter caption
      const capEl = c.querySelector(".cc-main");
      const subEl = c.querySelector(".cc-sub");
      let ci = 0;
      AU.sfx.paper();
      typeTimer = setInterval(() => {
        ci += 1;
        capEl.textContent = s.cap.slice(0, ci);
        if (ci >= s.cap.length) {
          clearInterval(typeTimer); typeTimer = null;
          if (s.sub) subEl.textContent = s.sub;
        }
      }, 34);
      timer = setTimeout(next, s.dur);
    }

    c.onpointerdown = (e) => {
      e.stopPropagation();
      if (finished) return;
      if (i >= def.stills.length) { finishAll(); return; }  // on the stamp
      next();
    };

    next();
  }

  return { play, get active() { return active; } };
})();
