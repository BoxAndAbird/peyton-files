/* THE PEYTON FILES — art layer.
   Painted Higgsfield backdrops with hand-drawn silhouette actors on top.
   Warm light is still the only saturated color; the paintings agree. */
"use strict";

const PF_ART = (() => {

  /* Inject character-animation CSS (kept here so all art concerns live together) */
  const style = document.createElement("style");
  style.textContent = `
    .leg{transform-box:fill-box;transform-origin:50% 6%;}
    #kessler.walking .l1{animation:pfLegA .42s linear infinite;}
    #kessler.walking .l2{animation:pfLegB .42s linear infinite;}
    @keyframes pfLegA{0%,100%{transform:rotate(16deg)}50%{transform:rotate(-16deg)}}
    @keyframes pfLegB{0%,100%{transform:rotate(-16deg)}50%{transform:rotate(16deg)}}
    .fidget{transform-box:fill-box;transform-origin:50% 90%;animation:pfFidget 2.8s ease-in-out infinite;}
    @keyframes pfFidget{0%,100%{transform:rotate(0deg)}30%{transform:rotate(1.6deg) translateY(-1px)}60%{transform:rotate(-1.2deg)}}
    .sway1{transform-box:fill-box;transform-origin:50% 95%;animation:pfSway 3.4s ease-in-out infinite;}
    .sway2{transform-box:fill-box;transform-origin:50% 95%;animation:pfSway 3.4s ease-in-out infinite reverse;}
    .breathe{transform-box:fill-box;transform-origin:50% 100%;animation:pfBreathe 4.2s ease-in-out infinite;}
    @keyframes pfBreathe{0%,100%{transform:scaleY(1)}50%{transform:scaleY(1.012)}}
    .neon-flick{animation:pfNeon 4.5s infinite;}
    @keyframes pfNeon{0%,86%,90%,100%{opacity:1}87%,89%{opacity:.45}}
    .neon-flick2{animation:pfNeon2 7s infinite;}
    @keyframes pfNeon2{0%,71%,75%,79%,100%{opacity:1}72%,74%,76%,78%{opacity:.3}}
    .glow-warm{filter:url(#pfGlow);}
    .lamp-breathe{animation:pfLamp 6s ease-in-out infinite;}
    @keyframes pfLamp{0%,100%{opacity:.85}50%{opacity:1}}
    .flor-buzz{animation:pfFlor 9s infinite;}
    @keyframes pfFlor{0%,53%,57%,100%{opacity:.5}54%,56%{opacity:.14}}
  `;
  document.head.appendChild(style);

  const SIL = "#0d0f14";          // character silhouette
  const WARM = "#ffb35c";         // the warm light

  const DEFS = `<defs>
    <filter id="pfGlow" x="-60%" y="-60%" width="220%" height="220%">
      <feGaussianBlur stdDeviation="6" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <linearGradient id="skyDusk" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1d2230"/><stop offset=".62" stop-color="#2c3140"/>
      <stop offset=".82" stop-color="#4a4038"/><stop offset="1" stop-color="#5c4a38"/>
    </linearGradient>
    <linearGradient id="skyNight" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0e1119"/><stop offset="1" stop-color="#1b2130"/>
    </linearGradient>
    <linearGradient id="fogG" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#9aa4b8" stop-opacity="0"/>
      <stop offset="1" stop-color="#9aa4b8" stop-opacity=".16"/>
    </linearGradient>
    <radialGradient id="warmPool" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${WARM}" stop-opacity=".32"/>
      <stop offset="1" stop-color="${WARM}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="coldPool" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="#b8e0d8" stop-opacity=".25"/>
      <stop offset="1" stop-color="#b8e0d8" stop-opacity="0"/>
    </radialGradient>
  </defs>`;

  /* =================================================================
     PAINTED BACKDROPS
     All world paintings are 2560x1080 → 1707 wide at the 720 stage.
     Overlay positions live here so they can be tuned in one place.
     ================================================================= */
  const ART_W = 1707;
  const IMG = {
    bg_storage: "art/bg_storage.webp",
    bg_diner: "art/bg_diner.webp",
    bg_motel: "art/bg_motel.webp",
    bg_annex: "art/bg_annex.webp",
    bg_terminal: "art/bg_terminal.webp",
    bg_gas: "art/bg_gas.webp",
    bg_lakehouse: "art/bg_lakehouse.webp",
    cut_lakecity: "art/cut_lakecity.webp",
    cut_road: "art/cut_road.webp",
    cut_lakehouse: "art/cut_lakehouse.webp",
    prop_unit14: "art/prop_unit14.webp",
    prop_odom: "art/prop_odom.webp",
    title: "art/title.webp",
  };

  /* Scene overlays: signage, glows, and the haunt elements (ids hx-*).
     Positions tuned against the paintings (1707x720 stage space). */
  const OVERLAYS = {
    storage: (W) => `
      <text x="850" y="180" text-anchor="middle" font-family="Arial Black,Arial" font-size="24"
        letter-spacing="8" fill="#7f8798" opacity=".5">MILLHAVEN SELF-STORAGE</text>
      <text x="713" y="264" text-anchor="middle" font-family="Arial Black,Arial" font-size="15" fill="#7f8798" opacity=".65">13</text>
      <text x="947" y="252" text-anchor="middle" font-family="Arial Black,Arial" font-size="16" fill="#d8b98a" opacity=".8">14</text>
      <text x="1187" y="264" text-anchor="middle" font-family="Arial Black,Arial" font-size="15" fill="#7f8798" opacity=".65">15</text>
      <ellipse id="hx-door" cx="947" cy="555" rx="165" ry="75" fill="url(#warmPool)" class="lamp-breathe"/>
      <rect x="0" y="430" width="${W}" height="290" fill="url(#fogG)"/>`,
    diner: (W) => `
      <g class="neon-flick" transform="rotate(-3 452 226)">
        <text x="452" y="212" text-anchor="middle" font-family="Georgia,serif" font-size="29" fill="#ff8d5c" class="glow-warm">THE COPPER</text>
        <text x="452" y="250" text-anchor="middle" font-family="Georgia,serif" font-size="31" fill="#c2543f" class="glow-warm">SPOON</text>
      </g>
      <ellipse id="hx-juke" cx="307" cy="445" rx="85" ry="60" fill="url(#warmPool)" opacity="0"/>
      <rect x="1620" y="360" width="42" height="27" rx="2" fill="#efe6cd" opacity=".78"/>
      <text x="1641" y="381" text-anchor="middle" font-family="Arial Black,Arial" font-size="18" fill="#2a251d" opacity=".9">6</text>`,
    motel: (W) => `
      <g class="neon-flick2">
        <text x="627" y="242" text-anchor="middle" font-family="Georgia,serif" font-size="24" letter-spacing="6"
          fill="#e05c5c" class="glow-warm" opacity=".7" transform="rotate(-2 627 242)">VACANCY</text>
      </g>
      <ellipse id="hx-bath" cx="1290" cy="430" rx="125" ry="145" fill="url(#coldPool)" class="flor-buzz" style="opacity:.5"/>
      <text x="1385" y="302" text-anchor="middle" font-family="Georgia,serif" font-size="22" fill="#c9b895" opacity=".5">6</text>`,
    annex: (W) => `
      <rect id="hx-flor" x="70" y="40" width="430" height="170" fill="#cfe8e0" opacity=".07" class="flor-buzz"/>
      <ellipse cx="95" cy="505" rx="95" ry="55" fill="url(#coldPool)" opacity=".8"/>`,
    terminal: (W) => `
      <g opacity=".8" stroke="#cfd8ea" stroke-width="2" stroke-linecap="round">
        <line x1="388" y1="142" x2="387" y2="127"/>
        <line x1="388" y1="142" x2="378" y2="132"/>
      </g>
      <rect x="1568" y="340" width="46" height="24" rx="2" fill="#20242e" opacity=".8"/>
      <text x="1591" y="358" text-anchor="middle" font-family="Arial Black,Arial" font-size="15" fill="#c9b895" opacity=".9">44</text>
      <ellipse cx="303" cy="385" rx="85" ry="60" fill="url(#warmPool)" opacity=".8"/>
      <g id="hx-board" opacity="0">
        <rect x="730" y="205" width="360" height="56" fill="#0a0c10" opacity=".9"/>
        <text x="910" y="243" text-anchor="middle" font-family="Courier New,monospace" font-size="26"
          letter-spacing="5" fill="#e8c987">MILLHAVEN&nbsp;&nbsp;11:52</text>
      </g>`,
    gas: (W) => `
      <g class="neon-flick">
        <text x="840" y="270" text-anchor="middle" font-family="Arial Black,Arial" font-size="21"
          letter-spacing="3" fill="${WARM}" class="glow-warm" opacity=".85" transform="rotate(-1 840 270)">ROUTE 9 FUEL</text>
      </g>
      <g id="hx-pump" opacity="0">
        <rect x="1210" y="383" width="92" height="28" fill="#0a0c10" opacity=".9"/>
        <text id="hx-pump-n" x="1256" y="404" text-anchor="middle" font-family="Courier New,monospace" font-size="19" fill="#ffd9a0">18.2</text>
      </g>
      <ellipse cx="1640" cy="430" rx="80" ry="120" fill="url(#coldPool)" opacity=".5"/>
      <rect x="0" y="430" width="${W}" height="290" fill="url(#fogG)"/>`,
    lakehouse: (W) => `
      <rect x="640" y="398" width="58" height="12" rx="1.5" fill="#6e5a2e" opacity=".45"/>
      <ellipse id="hx-lamp" cx="1254" cy="420" rx="150" ry="115" fill="url(#warmPool)" class="lamp-breathe"/>`,
  };

  /* Build a painted world scene: image + graded floor strip + overlays. */
  function sceneArt(id, def) {
    const W = ART_W;
    const ov = OVERLAYS[id] ? OVERLAYS[id](W) : "";
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} 720" preserveAspectRatio="xMidYMax meet">${DEFS}
      <image href="${IMG[def.art]}" x="0" y="0" width="${W}" height="720" preserveAspectRatio="xMidYMid slice"/>
      <rect x="0" y="0" width="${W}" height="720" fill="#0b0e14" opacity=".14"/>
      <linearGradient id="floorFade" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#06070a" stop-opacity="0"/><stop offset="1" stop-color="#06070a" stop-opacity=".55"/>
      </linearGradient>
      <rect x="0" y="${(def.ground || 640) - 30}" width="${W}" height="${720 - (def.ground || 640) + 30}" fill="url(#floorFade)"/>
      ${ov}`.trim() + `</svg>`;
  }

  /* ---------- characters ---------- */

  // Kessler: upright trench coat, hands in pockets. Local box 120x190, feet at y=190.
  function kesslerSVG() {
    return `<ellipse cx="60" cy="186" rx="34" ry="7" fill="#000" opacity=".4"/>
    <g class="walk-bob">
      <circle cx="60" cy="26" r="15" fill="${SIL}"/>
      <path d="M46,20 Q60,4 76,22 L74,34 Q60,26 48,32 Z" fill="${SIL}"/>
      <rect x="55" y="38" width="10" height="10" fill="${SIL}"/>
      <path d="M44,46 L76,46 L83,58 L86,132 L80,148 L40,148 L34,132 L37,58 Z" fill="${SIL}"/>
      <path d="M44,46 L54,60 L60,48 L66,60 L76,46 L60,42 Z" fill="#161a22"/>
      <path d="M40,148 L80,148 L84,162 L36,162 Z" fill="${SIL}"/>
    </g>
    <g class="leg l1"><rect x="46" y="158" width="11" height="26" fill="${SIL}"/><rect x="42" y="182" width="17" height="8" rx="2" fill="${SIL}"/></g>
    <g class="leg l2"><rect x="63" y="158" width="11" height="26" fill="${SIL}"/><rect x="61" y="182" width="17" height="8" rx="2" fill="${SIL}"/></g>`;
  }

  // Gerald: hunched, clutching a cardboard box. 140x170, feet at 170.
  function geraldSVG() {
    return `<ellipse cx="72" cy="167" rx="40" ry="7" fill="#000" opacity=".4"/>
    <g class="fidget">
      <path d="M40,70 Q38,30 72,26 Q100,24 104,52 L108,120 Q110,150 92,152 L52,152 Q34,148 36,116 Z" fill="${SIL}"/>
      <circle cx="96" cy="34" r="14" fill="${SIL}"/>
      <path d="M84,26 Q96,14 110,28 L106,38 Q96,30 86,34 Z" fill="${SIL}"/>
      <rect x="58" y="78" width="52" height="38" rx="2" fill="#7a6244"/>
      <path d="M58,78 L84,88 L110,78 L110,84 L84,94 L58,84 Z" fill="#63503a"/>
      <rect x="50" y="150" width="12" height="14" fill="${SIL}"/>
      <rect x="80" y="150" width="12" height="14" fill="${SIL}"/>
      <rect x="46" y="162" width="18" height="7" rx="2" fill="${SIL}"/>
      <rect x="78" y="162" width="18" height="7" rx="2" fill="${SIL}"/>
    </g>`;
  }

  // Denise: perfectly still, coffee pot at her side. 120x180, feet at 180.
  function deniseSVG() {
    return `<ellipse cx="60" cy="176" rx="34" ry="7" fill="#000" opacity=".4"/>
    <g>
      <circle cx="60" cy="22" r="14" fill="${SIL}"/>
      <circle cx="60" cy="8" r="8" fill="${SIL}"/>
      <rect x="55" y="34" width="10" height="8" fill="${SIL}"/>
      <path d="M46,42 L74,42 L80,66 L78,140 L42,140 L40,66 Z" fill="${SIL}"/>
      <path d="M48,78 L72,78 L74,136 L46,136 Z" fill="#3c414d"/>
      <rect x="49" y="138" width="9" height="30" fill="${SIL}"/>
      <rect x="62" y="138" width="9" height="30" fill="${SIL}"/>
      <rect x="46" y="166" width="15" height="7" rx="2" fill="${SIL}"/>
      <rect x="60" y="166" width="15" height="7" rx="2" fill="${SIL}"/>
      <rect x="76" y="60" width="7" height="42" fill="${SIL}"/>
      <path d="M74,100 L94,100 L91,124 L77,124 Z" fill="#2a2f3a" stroke="${SIL}" stroke-width="3"/>
      <path d="M94,104 L101,108 L94,116 Z" fill="${SIL}"/>
    </g>`;
  }

  // Roy & Dale: mirrored pair, one cap + mop, one bag. 240x185, feet at 185.
  function whitlocksSVG() {
    const bro = (cap) => `
      <circle cx="60" cy="30" r="16" fill="${SIL}"/>
      ${cap ? `<path d="M44,26 L76,26 L76,18 Q60,8 46,20 Z" fill="${SIL}"/><rect x="70" y="24" width="16" height="5" rx="2" fill="${SIL}"/>` :
              `<path d="M46,22 Q60,8 74,22 L72,30 Q60,24 48,30 Z" fill="${SIL}"/>`}
      <rect x="54" y="44" width="12" height="8" fill="${SIL}"/>
      <path d="M38,52 L82,52 L90,74 L88,142 L32,142 L30,74 Z" fill="${SIL}"/>
      <rect x="42" y="140" width="13" height="30" fill="${SIL}"/>
      <rect x="65" y="140" width="13" height="30" fill="${SIL}"/>
      <rect x="38" y="168" width="19" height="8" rx="2" fill="${SIL}"/>
      <rect x="63" y="168" width="19" height="8" rx="2" fill="${SIL}"/>`;
    return `<ellipse cx="120" cy="181" rx="86" ry="8" fill="#000" opacity=".4"/>
      <g class="sway1">${bro(true)}
        <rect x="92" y="30" width="5" height="140" fill="#4a4030"/>
        <path d="M84,168 L110,168 L106,180 L88,180 Z" fill="#8d94a3"/>
      </g>
      <g class="sway2" transform="translate(130,0)">${bro(false)}
        <path d="M86,120 Q106,116 104,146 Q102,168 84,164 L82,132 Z" fill="#171a21"/>
      </g>`;
  }

  // Sgt. Reyes: squared shoulders, cardigan over uniform, clipboard held like scripture. 120x180.
  function reyesSVG() {
    return `<ellipse cx="60" cy="176" rx="34" ry="7" fill="#000" opacity=".4"/>
    <g class="breathe">
      <circle cx="60" cy="22" r="14" fill="${SIL}"/>
      <path d="M47,14 Q60,2 73,14 L73,26 Q60,20 47,26 Z" fill="${SIL}"/>
      <circle cx="60" cy="7" r="6" fill="${SIL}"/>
      <rect x="55" y="34" width="10" height="8" fill="${SIL}"/>
      <path d="M42,42 L78,42 L86,70 L84,144 L36,144 L34,70 Z" fill="${SIL}"/>
      <path d="M42,42 L50,54 L60,44 L70,54 L78,42 L60,40 Z" fill="#1b202b"/>
      <rect x="44" y="88" width="34" height="24" rx="2" fill="#8d8060"/>
      <rect x="48" y="92" width="26" height="3" fill="#3b3327"/>
      <rect x="48" y="99" width="20" height="3" fill="#3b3327"/>
      <rect x="47" y="142" width="10" height="28" fill="${SIL}"/>
      <rect x="63" y="142" width="10" height="28" fill="${SIL}"/>
      <rect x="43" y="168" width="17" height="7" rx="2" fill="${SIL}"/>
      <rect x="61" y="168" width="17" height="7" rx="2" fill="${SIL}"/>
    </g>`;
  }

  // Wes: lanky, leaning, visor cap, headphones around the neck. 110x185.
  function wesSVG() {
    return `<ellipse cx="55" cy="181" rx="30" ry="7" fill="#000" opacity=".4"/>
    <g class="fidget">
      <circle cx="58" cy="24" r="13" fill="${SIL}"/>
      <path d="M45,20 L74,20 L80,14 L48,10 Z" fill="${SIL}"/>
      <path d="M46,36 Q58,46 70,36 L70,44 Q58,52 46,44 Z" fill="#2b3140"/>
      <rect x="53" y="34" width="9" height="9" fill="${SIL}"/>
      <path d="M45,43 L70,43 L74,60 L72,130 L44,130 L40,60 Z" fill="${SIL}"/>
      <path d="M48,72 L68,72 L67,126 L47,126 Z" fill="#232837"/>
      <rect x="46" y="128" width="9" height="42" fill="${SIL}"/>
      <rect x="60" y="128" width="9" height="42" fill="${SIL}"/>
      <rect x="42" y="168" width="16" height="7" rx="2" fill="${SIL}"/>
      <rect x="58" y="168" width="16" height="7" rx="2" fill="${SIL}"/>
    </g>`;
  }

  // Merle: stocky, cap, squeegee held like a halberd. 130x175.
  function merleSVG() {
    return `<ellipse cx="65" cy="171" rx="40" ry="7" fill="#000" opacity=".4"/>
    <g class="sway1">
      <circle cx="62" cy="28" r="15" fill="${SIL}"/>
      <path d="M46,24 L78,24 L78,16 Q62,6 48,18 Z" fill="${SIL}"/>
      <rect x="72" y="22" width="15" height="5" rx="2" fill="${SIL}"/>
      <rect x="56" y="42" width="12" height="8" fill="${SIL}"/>
      <path d="M40,50 L84,50 L92,76 L90,138 L34,138 L32,76 Z" fill="${SIL}"/>
      <path d="M52,50 L72,50 L72,136 L52,136 Z" fill="#20252f"/>
      <rect x="44" y="136" width="13" height="28" fill="${SIL}"/>
      <rect x="67" y="136" width="13" height="28" fill="${SIL}"/>
      <rect x="40" y="162" width="19" height="8" rx="2" fill="${SIL}"/>
      <rect x="65" y="162" width="19" height="8" rx="2" fill="${SIL}"/>
      <rect x="98" y="34" width="5" height="132" fill="#4a4030"/>
      <rect x="88" y="28" width="25" height="7" rx="2" fill="#8d94a3"/>
    </g>`;
  }

  // Mrs. Abernathy: bell-silhouette dress, bun, oil lamp at her side. The stillest thing alive. 110x175.
  function abernathySVG() {
    return `<ellipse cx="55" cy="171" rx="34" ry="7" fill="#000" opacity=".4"/>
    <g>
      <circle cx="55" cy="20" r="12" fill="${SIL}"/>
      <circle cx="55" cy="7" r="6" fill="${SIL}"/>
      <rect x="50" y="30" width="10" height="8" fill="${SIL}"/>
      <path d="M44,36 L66,36 L72,64 L82,166 L28,166 L38,64 Z" fill="${SIL}"/>
      <path d="M49,44 L61,44 L61,58 L49,58 Z" fill="#1a1e28"/>
      <circle cx="55" cy="47" r="3.4" fill="#c9b895"/>
      <rect x="76" y="82" width="6" height="34" fill="${SIL}"/>
      <g class="lamp-breathe">
        <path d="M74,116 L90,116 L87,140 L77,140 Z" fill="#2a2f3a" stroke="${SIL}" stroke-width="2.5"/>
        <ellipse cx="82" cy="128" rx="6" ry="9" fill="${WARM}" class="glow-warm"/>
      </g>
    </g>`;
  }

  const NPC_ART = {
    npc_gerald: geraldSVG, npc_denise: deniseSVG, npc_whitlocks: whitlocksSVG,
    npc_reyes: reyesSVG, npc_wes: wesSVG, npc_merle: merleSVG, npc_abernathy: abernathySVG,
  };
  const NPC_SIZE = {
    npc_gerald: [140,170], npc_denise: [120,180], npc_whitlocks: [240,185],
    npc_reyes: [120,180], npc_wes: [110,185], npc_merle: [130,175], npc_abernathy: [110,175],
  };

  /* ---------- dialogue portraits (case-file photographs) ---------- */
  const PORTRAITS = {
    "KESSLER": "art/pt_kessler.webp",
    "GERALD": "art/pt_gerald.webp",
    "DENISE": "art/pt_denise.webp",
    "ROY": "art/pt_whitlocks.webp",
    "DALE": "art/pt_whitlocks.webp",
    "ROY & DALE": "art/pt_whitlocks.webp",
    "REYES": "art/pt_reyes.webp",
    "WES": "art/pt_wes.webp",
    "MERLE": "art/pt_merle.webp",
    "ABERNATHY": "art/pt_abernathy.webp",
  };

  /* ---------- shared scene bits (procedural fallback) ---------- */

  const ground = (w, c1="#1e222a", c2="#171a20") =>
    `<rect x="0" y="640" width="${w}" height="80" fill="${c1}"/>
     <rect x="0" y="640" width="${w}" height="6" fill="${c2}"/>`;

  const puddle = (x, w, tint=WARM, op=.10) =>
    `<ellipse cx="${x}" cy="678" rx="${w}" ry="8" fill="#2c3547" opacity=".55"/>
     <ellipse cx="${x}" cy="678" rx="${w*0.6}" ry="5" fill="${tint}" opacity="${op}"/>`;

  const lampCone = (x, topY, groundY, spread, op=.10) =>
    `<path d="M${x-6},${topY} L${x+6},${topY} L${x+spread},${groundY} L${x-spread},${groundY} Z" fill="${WARM}" opacity="${op}"/>`;

  const fog = (w) => `<rect x="0" y="430" width="${w}" height="290" fill="url(#fogG)"/>`;

  /* Minimal procedural fallbacks (used only if a painting is missing). */
  function fallbackScene(W, label) {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} 720" preserveAspectRatio="xMidYMax meet">${DEFS}
      <rect width="${W}" height="720" fill="url(#skyNight)"/>
      <text x="${W/2}" y="330" text-anchor="middle" font-family="Arial Black,Arial" font-size="30" letter-spacing="8" fill="#39404f">${label}</text>
      ${ground(W)}${fog(W)}
    </svg>`;
  }
  const SCENES = {
    storage: () => fallbackScene(1707, "MILLHAVEN SELF-STORAGE"),
    diner:   () => fallbackScene(1707, "THE COPPER SPOON"),
    motel:   () => fallbackScene(1707, "PRESIDIO MOTOR LODGE"),
    annex:   () => fallbackScene(1707, "RECORDS ANNEX"),
    terminal:() => fallbackScene(1707, "UNION TERMINAL"),
    gas:     () => fallbackScene(1707, "ROUTE 9 FUEL"),
    lakehouse:() => fallbackScene(1707, "WHITMORE LAKE HOUSE"),
  };

  /* ---------- surveillance photo (photo puzzle + reveal) ---------- */
  function photoSVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" preserveAspectRatio="none">
      <image href="${IMG.prop_unit14}" x="0" y="0" width="600" height="600" preserveAspectRatio="xMidYMid slice"/>
      <rect width="600" height="600" fill="#1a2030" opacity=".12"/>
      <text x="24" y="46" font-family="Courier New" font-size="24" fill="#e6e9f0" opacity=".9">CAM 02</text>
      <text x="408" y="580" font-family="Courier New" font-size="24" fill="#e6e9f0" opacity=".9">03:12 AM</text>
      <text x="299" y="180" text-anchor="middle" font-family="Arial Black,Arial" font-size="42" fill="#dfe3ea" opacity=".8">14</text>
      <ellipse cx="299" cy="268" rx="132" ry="158" fill="none" stroke="#c22b26" stroke-width="7" opacity=".9" stroke-dasharray="4 14" stroke-linecap="round"/>
    </svg>`;
  }

  /* ---------- 1931 photograph (episode 3 photo puzzle) ---------- */
  function photo1931SVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" preserveAspectRatio="none">
      <defs><filter id="pfSepia"><feColorMatrix type="matrix"
        values="0.45 0.35 0.15 0 0.06  0.35 0.32 0.12 0 0.03  0.22 0.20 0.10 0 0.0  0 0 0 1 0"/></filter></defs>
      <g filter="url(#pfSepia)">
        <image href="${IMG.cut_lakehouse}" x="0" y="0" width="600" height="600" preserveAspectRatio="xMidYMid slice"/>
      </g>
      <rect width="600" height="600" fill="#3a2c14" opacity=".14"/>
      <text x="466" y="578" font-family="Courier New" font-size="26" fill="#efe0c0" opacity=".8">1931</text>
      <ellipse cx="359" cy="183" rx="72" ry="72" fill="none" stroke="#c22b26" stroke-width="6" opacity=".9" stroke-dasharray="4 13" stroke-linecap="round"/>
    </svg>`;
  }

  /* ---------- stinger photo (Odom in the doorway) ---------- */
  function stingerSVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid slice">
      <image href="${IMG.prop_odom}" x="0" y="0" width="600" height="400" preserveAspectRatio="xMidYMid slice"/>
      <text x="20" y="30" font-family="Courier New" font-size="17" fill="#e6e9f0" opacity=".8">SURV. 88-C — MAIN ST</text>
      <circle id="odom-ring" cx="298" cy="228" r="62" fill="none" stroke="#c22b26" stroke-width="4" opacity="0"/>
    </svg>`;
  }

  /* ---------- small icons ---------- */
  const ICONS = {
    file:   `<svg viewBox="0 0 40 40"><path d="M4,10 L14,10 L17,14 L36,14 L36,34 L4,34 Z" fill="#b3925c"/><rect x="8" y="6" width="18" height="8" rx="1" fill="#c9a86a"/></svg>`,
    photo:  `<svg viewBox="0 0 40 40"><rect x="4" y="6" width="32" height="28" fill="#e8e2d2"/><rect x="7" y="9" width="26" height="18" fill="#39404d"/><path d="M9,25 L16,16 L21,22 L26,14 L31,25 Z" fill="#232833"/><circle cx="13" cy="14" r="2.4" fill="#aab2c2"/></svg>`,
    memo:   `<svg viewBox="0 0 40 40"><rect x="7" y="4" width="26" height="32" fill="#efe6cd"/><rect x="11" y="10" width="18" height="2.6" fill="#2a251d"/><rect x="11" y="16" width="18" height="2.6" fill="#151310"/><rect x="11" y="22" width="12" height="2.6" fill="#2a251d"/><rect x="11" y="28" width="16" height="2.6" fill="#151310"/></svg>`,
    match:  `<svg viewBox="0 0 40 40"><path d="M8,12 L32,12 L32,34 L8,34 Z" fill="#a3231f"/><path d="M8,12 L32,12 L30,4 L10,4 Z" fill="#7d1a17"/><circle cx="20" cy="23" r="6" fill="#efe6cd"/><rect x="18" y="26" width="4" height="8" fill="#efe6cd"/></svg>`,
    key:    `<svg viewBox="0 0 40 40"><rect x="5" y="6" width="30" height="28" fill="#efe6cd"/><line x1="5" y1="15" x2="35" y2="15" stroke="#2a251d" stroke-width="2"/><line x1="5" y1="24" x2="35" y2="24" stroke="#2a251d" stroke-width="2"/><line x1="15" y1="6" x2="15" y2="34" stroke="#2a251d" stroke-width="2"/><line x1="25" y1="6" x2="25" y2="34" stroke="#2a251d" stroke-width="2"/></svg>`,
    receipt:`<svg viewBox="0 0 40 40"><path d="M9,4 L31,4 L31,32 L27,36 L23,32 L19,36 L15,32 L11,36 L9,32 Z" fill="#f4f0e2"/><rect x="13" y="10" width="14" height="2.4" fill="#4a4234"/><rect x="13" y="15" width="14" height="2.4" fill="#4a4234"/><rect x="13" y="20" width="9" height="2.4" fill="#4a4234"/></svg>`,
    note:   `<svg viewBox="0 0 40 40"><rect x="6" y="8" width="28" height="24" fill="#f4f0e2" transform="rotate(-4 20 20)"/><path d="M12,16 Q20,12 28,16 M12,22 Q20,18 28,22" stroke="#2a251d" stroke-width="1.6" fill="none" transform="rotate(-4 20 20)"/></svg>`,
  };

  const INV_ICONS = {
    i_badge: `<svg viewBox="0 0 40 40"><path d="M20,3 L33,8 L33,20 Q33,32 20,37 Q7,32 7,20 L7,8 Z" fill="#c9a86a"/><path d="M20,10 L23,17 L30,17 L24.5,21.5 L26.5,29 L20,24.5 L13.5,29 L15.5,21.5 L10,17 L17,17 Z" fill="#3b3129"/></svg>`,
    i_match: ICONS.match,
    i_ticket: ICONS.receipt,
    i_gas: `<svg viewBox="0 0 40 40"><path d="M9,4 L31,4 L31,32 L27,36 L23,32 L19,36 L15,32 L11,36 L9,32 Z" fill="#f4f0e2"/><rect x="13" y="9" width="14" height="2.4" fill="#4a4234"/><path d="M16,18 Q20,24 20,27 A4,4 0 0 1 12,27 Q12,24 16,18 Z" fill="#a3231f" transform="translate(4,-2)"/></svg>`,
    i_card: `<svg viewBox="0 0 40 40"><rect x="4" y="10" width="32" height="21" rx="1.5" fill="#f4f0e2" transform="rotate(-3 20 20)"/><line x1="8" y1="17" x2="32" y2="16" stroke="#8a2320" stroke-width="2"/><line x1="8" y1="22" x2="28" y2="21" stroke="#4a4234" stroke-width="1.8"/><line x1="8" y1="26" x2="30" y2="25" stroke="#4a4234" stroke-width="1.8"/></svg>`,
    i_slip: `<svg viewBox="0 0 40 40"><rect x="7" y="6" width="26" height="28" fill="#e8d8a8"/><rect x="7" y="6" width="26" height="8" fill="#a3231f" opacity=".8"/><text x="20" y="27" text-anchor="middle" font-family="Arial Black" font-size="11" fill="#2a251d">44</text></svg>`,
    i_map: `<svg viewBox="0 0 40 40"><path d="M6,8 L16,5 L26,9 L34,6 L34,32 L24,35 L14,31 L6,34 Z" fill="#e8e0c8"/><path d="M16,5 L16,31 M26,9 L26,35" stroke="#b9ad8a" stroke-width="1.4" fill="none"/><path d="M10,24 Q18,18 26,22 T33,14" stroke="#3b3327" stroke-width="2" fill="none"/><circle cx="30" cy="12" r="3" fill="none" stroke="#a3231f" stroke-width="2"/></svg>`,
  };

  /* ---------- corkboard pin thumbnails ---------- */
  const PIN_ART = {
    pin_folder: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#2c2620"/><path d="M22,20 L42,20 L47,26 L78,26 L78,46 L22,46 Z" fill="#c9a86a"/><text x="50" y="16" text-anchor="middle" font-family="Courier New" font-size="9" fill="#c8cbd4">0114</text></svg>`,
    pin_storage: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#232833"/><rect x="30" y="14" width="40" height="38" fill="#3a4150"/><line x1="30" y1="24" x2="70" y2="24" stroke="#2c313c" stroke-width="3"/><line x1="30" y1="34" x2="70" y2="34" stroke="#2c313c" stroke-width="3"/><text x="50" y="12" text-anchor="middle" font-family="Arial Black" font-size="9" fill="#aab2c2">14</text></svg>`,
    pin_gerald: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#232833"/><g transform="translate(32,6) scale(.3)"><path d="M40,70 Q38,30 72,26 Q100,24 104,52 L108,120 Q110,150 92,152 L52,152 Q34,148 36,116 Z" fill="#0d0f14"/><circle cx="96" cy="34" r="14" fill="#0d0f14"/><rect x="58" y="78" width="52" height="38" fill="#7a6244"/></g></svg>`,
    pin_diner: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#1c202a"/><text x="50" y="26" text-anchor="middle" font-family="Georgia" font-size="13" fill="#ff8d5c">COPPER</text><text x="50" y="42" text-anchor="middle" font-family="Georgia" font-size="13" fill="#c2543f">SPOON</text><rect x="20" y="48" width="60" height="3" fill="#ffb35c" opacity=".5"/></svg>`,
    pin_route: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#22262e"/><path d="M42,60 L48,0 L52,0 L58,60 Z" fill="#33383f"/><path d="M49,50 L51,50 L51,38 L49,38 Z M49,30 L51,30 L51,18 L49,18 Z" fill="#c8cbd4"/><path d="M50,4 L44,14 L56,14 Z" fill="#ffb35c"/><text x="76" y="34" font-family="Arial Black" font-size="10" fill="#8d94a3">9</text></svg>`,
    pin_motel: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#10131a"/><text x="50" y="26" text-anchor="middle" font-family="Georgia" font-size="14" fill="#ffb35c">PRESIDIO</text><rect x="40" y="34" width="20" height="18" fill="#efe6cd"/><text x="50" y="48" text-anchor="middle" font-family="Arial Black" font-size="12" fill="#2a251d">6</text></svg>`,
    pin_annex: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#1a1e26"/><rect x="12" y="12" width="18" height="40" fill="#2c313c"/><rect x="36" y="12" width="18" height="40" fill="#2c313c"/><rect x="60" y="12" width="18" height="40" fill="#12151c"/><text x="50" y="10" text-anchor="middle" font-family="Arial Black" font-size="8" fill="#8d94a3">AISLE 31</text><rect x="60" y="12" width="18" height="40" fill="#000" opacity=".5"/></svg>`,
    pin_locker: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#20242c"/><rect x="30" y="8" width="40" height="46" rx="2" fill="#39404f"/><circle cx="60" cy="30" r="3" fill="#c9a86a"/><text x="50" y="24" text-anchor="middle" font-family="Arial Black" font-size="12" fill="#c8cbd4">44</text></svg>`,
    pin_vol1: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#241f19"/><rect x="30" y="8" width="40" height="46" rx="2" fill="#4a2e28"/><rect x="34" y="12" width="32" height="38" fill="none" stroke="#c9a86a" stroke-width="1.5"/><text x="50" y="35" text-anchor="middle" font-family="Georgia" font-size="12" fill="#c9a86a">1931</text></svg>`,
    pin_gas: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#171b22"/><rect x="34" y="16" width="14" height="34" rx="2" fill="#3a4150"/><rect x="52" y="16" width="14" height="34" rx="2" fill="#3a4150"/><rect x="37" y="20" width="8" height="8" fill="#ffd9a0" opacity=".8"/><rect x="55" y="20" width="8" height="8" fill="#ffd9a0" opacity=".8"/><text x="50" y="12" text-anchor="middle" font-family="Arial Black" font-size="8" fill="#8d94a3">RTE 9</text></svg>`,
    pin_lake: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#0c1017"/><path d="M30,36 L50,18 L70,36 Z" fill="#161b26"/><rect x="36" y="36" width="28" height="14" fill="#161b26"/><rect x="55" y="24" width="7" height="8" fill="#ffb35c" opacity=".95"/><path d="M0,52 Q25,48 50,52 T100,52 L100,60 L0,60 Z" fill="#101725"/></svg>`,
  };

  /* ---------- title folder ---------- */
  function folderSVG() {
    return `<svg viewBox="0 0 300 210" xmlns="http://www.w3.org/2000/svg">
      <rect x="18" y="34" width="264" height="160" rx="4" fill="#a9884e"/>
      <path d="M18,50 L18,38 Q18,30 26,30 L96,30 L110,44 L282,44 L282,50 Z" fill="#b3925c"/>
      <rect x="14" y="46" width="272" height="152" rx="4" fill="#c9a86a"/>
      <rect x="34" y="74" width="150" height="12" fill="#8a6c38" opacity=".55"/>
      <rect x="34" y="94" width="110" height="12" fill="#8a6c38" opacity=".4"/>
      <g transform="rotate(-8 210 150)">
        <rect x="150" y="126" width="120" height="44" fill="none" stroke="#a3231f" stroke-width="5"/>
        <text x="210" y="156" text-anchor="middle" font-family="Arial Black,Arial" font-size="19" fill="#a3231f">CASE 0114</text>
      </g>
      <circle cx="44" cy="180" r="9" fill="none" stroke="#8a2320" stroke-width="3"/>
      <path d="M44,180 Q100,206 150,186 T262,176" stroke="#8a2320" stroke-width="3" fill="none"/>
    </svg>`;
  }

  return {
    kesslerSVG, NPC_ART, NPC_SIZE, SCENES, sceneArt, ART_W, IMG, PORTRAITS,
    photoSVG, photo1931SVG, stingerSVG, folderSVG,
    ICONS, INV_ICONS, PIN_ART, WARM, SIL,
  };
})();
