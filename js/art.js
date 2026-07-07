/* THE PEYTON FILES — procedural SVG art.
   Flat, silhouette-driven noir. Warm light sources are the only saturated color. */
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
    @keyframes pfSway{0%,100%{transform:rotate(.8deg)}50%{transform:rotate(-.8deg)}}
    .neon-flick{animation:pfNeon 4.5s infinite;}
    @keyframes pfNeon{0%,86%,90%,100%{opacity:1}87%,89%{opacity:.45}}
    .glow-warm{filter:url(#pfGlow);}
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
  </defs>`;

  /* ---------- characters ---------- */

  // Kessler: upright trench coat, hands in pockets. Local box 120x190, feet at y=190.
  function kesslerSVG() {
    return `<g class="walk-bob">
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
    return `<g class="fidget">
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
    return `<g>
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
    return `<g class="sway1">${bro(true)}
        <rect x="92" y="30" width="5" height="140" fill="#4a4030"/>
        <path d="M84,168 L110,168 L106,180 L88,180 Z" fill="#8d94a3"/>
      </g>
      <g class="sway2" transform="translate(130,0)">${bro(false)}
        <path d="M86,120 Q106,116 104,146 Q102,168 84,164 L82,132 Z" fill="#171a21"/>
      </g>`;
  }

  const NPC_ART = { npc_gerald: geraldSVG, npc_denise: deniseSVG, npc_whitlocks: whitlocksSVG };
  const NPC_SIZE = { npc_gerald: [140,170], npc_denise: [120,180], npc_whitlocks: [240,185] };

  /* ---------- shared scene bits ---------- */

  const ground = (w, c1="#1e222a", c2="#171a20") =>
    `<rect x="0" y="640" width="${w}" height="80" fill="${c1}"/>
     <rect x="0" y="640" width="${w}" height="6" fill="${c2}"/>`;

  const puddle = (x, w, tint=WARM, op=.10) =>
    `<ellipse cx="${x}" cy="678" rx="${w}" ry="8" fill="#2c3547" opacity=".55"/>
     <ellipse cx="${x}" cy="678" rx="${w*0.6}" ry="5" fill="${tint}" opacity="${op}"/>`;

  const lampCone = (x, topY, groundY, spread, op=.10) =>
    `<path d="M${x-6},${topY} L${x+6},${topY} L${x+spread},${groundY} L${x-spread},${groundY} Z" fill="${WARM}" opacity="${op}"/>`;

  const fog = (w) => `<rect x="0" y="430" width="${w}" height="290" fill="url(#fogG)"/>`;

  /* ---------- SCENE: storage facility (dusk) ---------- */
  function sceneStorage() {
    const W = 2000;
    let units = "";
    // one long building, roll-door units. Unit 14's door is ajar.
    const numbers = [11,12,13,14,15,16,17];
    for (let i = 0; i < numbers.length; i++) {
      const n = numbers[i], x = 420 + i*190;
      const ajar = n === 14;
      let door = "";
      if (ajar) {
        door = `<rect x="${x+10}" y="452" width="150" height="188" fill="#08090c"/>
          <rect x="${x+10}" y="452" width="150" height="188" fill="${WARM}" opacity=".07"/>
          <rect x="${x+10}" y="452" width="150" height="42" fill="#3a4150"/>
          <line x1="${x+10}" y1="466" x2="${x+160}" y2="466" stroke="#2f3542" stroke-width="3"/>
          <line x1="${x+10}" y1="480" x2="${x+160}" y2="480" stroke="#2f3542" stroke-width="3"/>`;
      } else {
        door = `<rect x="${x+10}" y="452" width="150" height="188" fill="#39404f"/>` +
          Array.from({length:9},(_,k)=>`<line x1="${x+10}" y1="${472+k*19}" x2="${x+160}" y2="${472+k*19}" stroke="#30364a" stroke-width="3"/>`).join("") +
          `<rect x="${x+72}" y="612" width="26" height="10" rx="2" fill="#262b38"/>`;
      }
      units += `<g>${door}
        <rect x="${x}" y="430" width="170" height="22" fill="#262b36"/>
        <text x="${x+85}" y="447" text-anchor="middle" font-family="Arial Black,Arial" font-size="15" fill="#8d94a3">${n}</text></g>`;
    }
    // boxes spilling near unit 15 front (Gerald's paperwork)
    const box = (x,y,w,h,c)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="${c}"/><line x1="${x}" y1="${y+h/2}" x2="${x+w}" y2="${y+h/2}" stroke="#4d3f2c" stroke-width="2"/>`;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} 720" preserveAspectRatio="xMidYMax meet">${DEFS}
      <rect width="${W}" height="720" fill="url(#skyDusk)"/>
      <rect x="0" y="560" width="${W}" height="80" fill="#171b24"/>
      <path d="M0,568 L120,540 L260,566 L420,548 L560,568 L${W},560 L${W},640 L0,640 Z" fill="#12151d"/>
      <rect x="380" y="360" width="1400" height="280" fill="#2c313c"/>
      <rect x="380" y="348" width="1400" height="18" fill="#20242e"/>
      <text x="1080" y="336" text-anchor="middle" font-family="Arial Black,Arial" font-size="34" letter-spacing="10" fill="#5b6270">MILLHAVEN SELF-STORAGE</text>
      ${units}
      <rect x="96" y="430" width="10" height="210" fill="#20242e"/>
      <rect x="80" y="470" width="44" height="60" rx="4" fill="#262b36"/>
      <circle cx="102" cy="488" r="4" fill="${WARM}" opacity=".8"/>
      ${Array.from({length:9},(_,k)=>`<line x1="130" y1="${440+k*22}" x2="360" y2="${440+k*22}" stroke="#242936" stroke-width="2"/>`).join("")}
      ${Array.from({length:8},(_,k)=>`<line x1="${140+k*28}" y1="436" x2="${140+k*28}" y2="638" stroke="#242936" stroke-width="2"/>`).join("")}
      <rect x="1840" y="380" width="12" height="260" fill="#20242e"/>
      <rect x="1832" y="368" width="60" height="14" rx="4" fill="#20242e"/>
      <circle cx="1880" cy="382" r="7" fill="${WARM}" class="glow-warm"/>
      ${lampCone(1880, 386, 640, 130, .08)}
      ${box(1400,560,70,50,"#6d573c")}${box(1478,548,80,62,"#7a6244")}${box(1420,510,74,48,"#63503a")}${box(1500,498,60,48,"#6d573c")}
      ${ground(W)}
      ${puddle(700,90)}${puddle(1250,120)}${puddle(1830,80,WARM,.16)}
      ${fog(W)}
    </svg>`;
  }

  /* ---------- SCENE: The Copper Spoon (interior, morning) ---------- */
  function sceneDiner() {
    const W = 1800;
    const stool = (x)=>`<rect x="${x}" y="540" width="10" height="100" fill="#232834"/><ellipse cx="${x+5}" cy="538" rx="26" ry="10" fill="#513c2a"/>`;
    const lamp = (x)=>`<rect x="${x-2}" y="120" width="4" height="90" fill="#12151c"/>
      <path d="M${x-26},210 L${x+26},210 L${x+14},178 L${x-14},178 Z" fill="#1c212c"/>
      <ellipse cx="${x}" cy="212" rx="20" ry="6" fill="${WARM}" class="glow-warm" opacity=".9"/>
      ${lampCone(x, 214, 560, 110, .07)}`;
    const boothWin = (x)=>`<rect x="${x}" y="200" width="200" height="220" rx="4" fill="#10141d"/>
      ${Array.from({length:6},(_,k)=>`<line x1="${x+18+k*32}" y1="206" x2="${x+8+k*32}" y2="414" stroke="#26304a" stroke-width="2"/>`).join("")}`;
    const booth = (x,n)=>`
      <path d="M${x},640 L${x},470 Q${x},452 ${x+16},452 L${x+28},452 L${x+28},640 Z" fill="#4a2e28"/>
      <path d="M${x+196},640 L${x+196},470 Q${x+196},452 ${x+180},452 L${x+168},452 L${x+168},640 Z" fill="#4a2e28"/>
      <rect x="${x+52}" y="520" width="92" height="12" fill="#71513a"/>
      <rect x="${x+90}" y="532" width="14" height="108" fill="#3a2c22"/>
      <rect x="${x+60}" y="472" width="30" height="38" rx="3" fill="#efe6cd" opacity=".9"/>
      <text x="${x+75}" y="498" text-anchor="middle" font-family="Arial Black,Arial" font-size="20" fill="#2a251d">${n}</text>`;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} 720" preserveAspectRatio="xMidYMax meet">${DEFS}
      <rect width="${W}" height="720" fill="#23272f"/>
      <rect x="0" y="0" width="${W}" height="120" fill="#1c202a"/>
      <rect x="0" y="612" width="${W}" height="108" fill="#20242c"/>
      ${Array.from({length:23},(_,k)=>`<rect x="${k*80+(k%2?0:40)-40}" y="612" width="78" height="108" fill="${k%2?"#262a33":"#1d2129"}"/>`).join("")}
      <rect x="0" y="604" width="${W}" height="10" fill="#12151c"/>
      ${boothWin(60)}
      <g class="neon-flick">
        <text x="160" y="290" text-anchor="middle" font-family="Georgia,serif" font-size="34" fill="#ff8d5c" class="glow-warm" transform="scale(-1,1) translate(-320,0)">COPPER</text>
        <text x="160" y="336" text-anchor="middle" font-family="Georgia,serif" font-size="34" fill="#c2543f" class="glow-warm" transform="scale(-1,1) translate(-320,0)">SPOON</text>
      </g>
      <rect x="300" y="440" width="90" height="180" rx="6" fill="#3a2f3f"/>
      <rect x="312" y="456" width="66" height="44" rx="22" fill="#191420"/>
      <rect x="318" y="510" width="54" height="70" fill="#241c30"/>
      <text x="345" y="606" text-anchor="middle" font-family="Arial" font-size="11" fill="#6b5f78">OUT OF ORDER</text>
      ${lamp(700)}${lamp(950)}${lamp(1200)}
      <rect x="560" y="250" width="700" height="150" fill="#1c202a"/>
      <rect x="580" y="270" width="180" height="110" fill="#262b36"/>
      <rect x="600" y="286" width="60" height="80" rx="4" fill="#3a4150"/>
      <rect x="700" y="300" width="26" height="50" fill="#2f3542"/>
      <ellipse cx="713" cy="298" rx="16" ry="5" fill="#12151c"/>
      <text x="910" y="320" font-family="Arial" font-size="18" letter-spacing="3" fill="#5b6270">TODAY: PIE</text>
      <text x="910" y="348" font-family="Arial" font-size="13" letter-spacing="2" fill="#454c5c">EVERYTHING ELSE: ASK</text>
      <rect x="560" y="430" width="700" height="24" fill="#4a5262"/>
      <rect x="570" y="454" width="680" height="150" fill="#343a46"/>
      <rect x="570" y="454" width="680" height="10" fill="#2a2f3a"/>
      <rect x="790" y="404" width="4" height="28" fill="#8d94a3"/>
      <ellipse cx="792" cy="432" rx="16" ry="4" fill="#262b36"/>
      <rect x="782" y="408" width="22" height="18" fill="#efe6cd" opacity=".85" transform="rotate(-6 793 417)"/>
      <rect x="1000" y="330" width="120" height="100" fill="#20242e"/>
      <rect x="1008" y="338" width="104" height="84" fill="#0f1218"/>
      <ellipse cx="1035" cy="392" rx="20" ry="9" fill="#8a4a2e"/>
      <ellipse cx="1080" cy="392" rx="20" ry="9" fill="#a3763c"/>
      <ellipse cx="1058" cy="366" rx="20" ry="9" fill="#7a5c34"/>
      <text x="1060" y="446" text-anchor="middle" font-family="Arial" font-size="12" letter-spacing="2" fill="#6b7280">PIE</text>
      ${stool(620)}${stool(730)}${stool(840)}${stool(1080)}${stool(1190)}
      <g transform="translate(1160,388) scale(.86)">
        <circle cx="60" cy="30" r="15" fill="${SIL}"/>
        <path d="M42,48 L78,48 L86,80 L82,150 L38,150 L34,80 Z" fill="${SIL}"/>
        <rect x="40" y="148" width="40" height="60" fill="${SIL}"/>
      </g>
      ${booth(1470,6)}
      ${ground(W,"#20242c","#12151c")}
    </svg>`;
  }

  /* ---------- SCENE: Presidio Motor Lodge, room 6 (interior) ---------- */
  function sceneMotel() {
    const W = 1700;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} 720" preserveAspectRatio="xMidYMax meet">${DEFS}
      <rect width="${W}" height="720" fill="#262a33"/>
      ${Array.from({length:28},(_,k)=>`<rect x="${k*64}" y="120" width="30" height="500" fill="#2a2e38" opacity=".5"/>`).join("")}
      <rect x="0" y="0" width="${W}" height="120" fill="#20242c"/>
      <rect x="0" y="596" width="${W}" height="124" fill="#2c2e33"/>
      <rect x="0" y="590" width="${W}" height="8" fill="#191b20"/>
      <g>
        <rect x="60" y="220" width="180" height="420" fill="#0e1119"/>
        <rect x="60" y="220" width="180" height="420" fill="url(#skyNight)" opacity=".7"/>
        <rect x="96" y="420" width="110" height="12" fill="#12151c"/>
        <text x="150" y="404" text-anchor="middle" font-family="Georgia,serif" font-size="22" fill="${WARM}" class="glow-warm neon-flick">PRESIDIO</text>
        <text x="150" y="430" text-anchor="middle" font-family="Georgia,serif" font-size="11" fill="#c98b45">MOTOR LODGE — VACANCY</text>
        ${Array.from({length:5},(_,k)=>`<line x1="${84+k*34}" y1="226" x2="${72+k*34}" y2="634" stroke="#26304a" stroke-width="2"/>`).join("")}
        <rect x="52" y="204" width="196" height="16" fill="#1b1e26"/>
        <rect x="52" y="640" width="196" height="10" fill="#1b1e26"/>
      </g>
      <g>
        <rect x="330" y="180" width="20" height="460" fill="#1b1e26"/>
        <rect x="350" y="196" width="150" height="444" fill="#10131a"/>
        <rect x="350" y="196" width="150" height="444" fill="${WARM}" opacity=".05"/>
        <rect x="352" y="200" width="26" height="440" fill="#332c26"/>
        <circle cx="372" cy="430" r="6" fill="#8d94a3"/>
        <rect x="404" y="330" width="52" height="70" rx="4" fill="#efe6cd" opacity=".82"/>
        <text x="430" y="372" text-anchor="middle" font-family="Arial Black,Arial" font-size="34" fill="#2a251d">6</text>
      </g>
      <g>
        <rect x="560" y="470" width="240" height="60" fill="#6a6f7c"/>
        <rect x="560" y="530" width="240" height="70" fill="#3a3f4a"/>
        <rect x="548" y="440" width="24" height="160" fill="#2c2620"/>
        <rect x="788" y="440" width="24" height="160" fill="#2c2620"/>
        <rect x="560" y="470" width="240" height="12" fill="#7c828f"/>
        <path d="M600,492 L760,492 M580,510 L740,510" stroke="#575c68" stroke-width="4" fill="none"/>
      </g>
      <g>
        <rect x="1130" y="490" width="110" height="110" fill="#3a332c"/>
        <rect x="1130" y="490" width="110" height="14" fill="#4a4238"/>
        <rect x="1176" y="540" width="40" height="10" fill="#2a251e"/>
        <rect x="1146" y="418" width="10" height="72" fill="#191b20"/>
        <path d="M1122,430 L1180,430 L1168,394 L1134,394 Z" fill="#1c212c"/>
        <ellipse cx="1151" cy="432" rx="24" ry="7" fill="${WARM}" class="glow-warm" opacity=".95"/>
        ${lampCone(1151, 436, 600, 120, .10)}
        <rect x="1196" y="478" width="34" height="24" fill="#efe6cd" transform="rotate(-4 1213 490)"/>
      </g>
      <g>
        <rect x="1450" y="190" width="160" height="450" fill="#171b23"/>
        <rect x="1450" y="190" width="160" height="450" fill="#bcd0d8" opacity=".05"/>
        <rect x="1444" y="176" width="172" height="16" fill="#1b1e26"/>
        <rect x="1520" y="380" width="8" height="60" fill="#3a4150"/>
        <rect x="1460" y="620" width="140" height="20" fill="#10131a"/>
      </g>
      <rect x="880" y="560" width="90" height="60" rx="4" fill="#171a21"/>
      <rect x="990" y="574" width="70" height="46" rx="4" fill="#171a21"/>
      <text x="850" y="160" font-family="Arial" font-size="15" letter-spacing="6" fill="#454c5c">ROOM 6</text>
      ${ground(W,"#2c2e33","#191b20")}
    </svg>`;
  }

  const SCENES = { storage: sceneStorage, diner: sceneDiner, motel: sceneMotel };

  /* ---------- surveillance photo (photo puzzle + reveal) ---------- */
  function photoSVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" preserveAspectRatio="none">
      <defs><filter id="pfGrain"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" result="n"/>
      <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.5 0 0 0 0 0.5 0 0 0 0 0.55 0 0 0 .08 0"/>
      <feComposite operator="over" in2="SourceGraphic"/></filter></defs>
      <g filter="url(#pfGrain)">
      <rect width="600" height="600" fill="#39404d"/>
      <rect y="0" width="600" height="150" fill="#2c313d"/>
      <rect x="30" y="150" width="540" height="330" fill="#232833"/>
      <rect x="30" y="140" width="540" height="16" fill="#1b1f28"/>
      <rect x="90" y="200" width="180" height="270" fill="#2f3644"/>
      ${Array.from({length:9},(_,k)=>`<line x1="90" y1="${226+k*26}" x2="270" y2="${226+k*26}" stroke="#272d3a" stroke-width="4"/>`).join("")}
      <rect x="330" y="200" width="180" height="270" fill="#12151d"/>
      <rect x="330" y="200" width="180" height="30" fill="#2f3644"/>
      <text x="420" y="300" text-anchor="middle" font-family="Arial Black,Arial" font-size="86" fill="#aab2c2" opacity=".92">14</text>
      <rect x="322" y="188" width="196" height="10" fill="#1b1f28"/>
      <path d="M508,470 L560,470 L560,200 L540,200 L540,450 L508,450 Z" fill="#1b1f28"/>
      <rect y="470" width="600" height="130" fill="#1d212b"/>
      <ellipse cx="300" cy="520" rx="140" ry="14" fill="#242c3c" opacity=".8"/>
      <text x="24" y="46" font-family="Courier New" font-size="24" fill="#c8cbd4" opacity=".85">CAM 02</text>
      <text x="420" y="580" font-family="Courier New" font-size="24" fill="#c8cbd4" opacity=".85">03:12 AM</text>
      <circle cx="420" cy="215" r="0" fill="none"/>
      </g>
      <ellipse cx="420" cy="300" rx="120" ry="120" fill="none" stroke="#a3231f" stroke-width="7" opacity=".9" stroke-dasharray="4 14" stroke-linecap="round"/>
    </svg>`;
  }

  /* ---------- stinger photo (Odom in the doorway) ---------- */
  function stingerSVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid slice">
      <rect width="600" height="400" fill="#3a4150"/>
      <rect y="280" width="600" height="120" fill="#232833"/>
      <rect x="40" y="60" width="240" height="230" fill="#2c313d"/>
      <rect x="330" y="40" width="230" height="250" fill="#272d38"/>
      <rect x="470" y="120" width="70" height="170" fill="#12151d"/>
      <g transform="translate(120,180) scale(.62)"><circle cx="60" cy="26" r="15" fill="#141821"/><path d="M44,46 L76,46 L84,140 L36,140 Z" fill="#141821"/><rect x="44" y="140" width="12" height="40" fill="#141821"/><rect x="64" y="140" width="12" height="40" fill="#141821"/></g>
      <g transform="translate(190,184) scale(.6)"><circle cx="60" cy="26" r="15" fill="#141821"/><path d="M44,46 L76,46 L84,140 L36,140 Z" fill="#141821"/><rect x="44" y="140" width="12" height="40" fill="#141821"/><rect x="64" y="140" width="12" height="40" fill="#141821"/></g>
      <g id="odom-figure" transform="translate(475,168) scale(.5)" opacity=".55">
        <circle cx="60" cy="26" r="15" fill="#0d0f14"/>
        <path d="M40,46 L80,46 L88,150 L32,150 Z" fill="#0d0f14"/>
        <rect x="44" y="150" width="13" height="46" fill="#0d0f14"/><rect x="63" y="150" width="13" height="46" fill="#0d0f14"/>
        <path d="M44,20 L76,20 L80,10 Q60,0 40,12 Z" fill="#0d0f14"/>
      </g>
      <text x="20" y="30" font-family="Courier New" font-size="17" fill="#c8cbd4" opacity=".7">SURV. 88-C — MAIN ST</text>
      <circle id="odom-ring" cx="505" cy="210" r="52" fill="none" stroke="#a3231f" stroke-width="4" opacity="0"/>
    </svg>`;
  }

  /* ---------- cold open (animated) ---------- */
  function coldOpenSVG() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 720" preserveAspectRatio="xMidYMax slice">${DEFS}
      <style>
        #co-door{transform-box:fill-box;transform-origin:left center;animation:coDoor 1.6s ease-in 1.2s forwards;}
        @keyframes coDoor{from{transform:scaleX(1)}to{transform:scaleX(.06)}}
        #co-fig{animation:coWalk 5.5s linear 2.2s both;}
        @keyframes coWalk{from{transform:translate(430px,640px) scale(.9)}to{transform:translate(820px,640px) scale(.9)}}
        @keyframes coFade{0%{opacity:0}10%{opacity:1}80%{opacity:1}100%{opacity:0}}
        #co-fig-inner{animation:coFade 5.5s linear 2.2s both;opacity:0;}
      </style>
      <rect width="800" height="720" fill="url(#skyDusk)"/>
      <rect x="60" y="360" width="680" height="280" fill="#2c313c"/>
      <rect x="60" y="348" width="680" height="18" fill="#20242e"/>
      <text x="400" y="334" text-anchor="middle" font-family="Arial Black,Arial" font-size="22" letter-spacing="7" fill="#4b515e">MILLHAVEN SELF-STORAGE</text>
      <rect x="120" y="452" width="150" height="188" fill="#39404f"/>
      ${Array.from({length:9},(_,k)=>`<line x1="120" y1="${472+k*19}" x2="270" y2="${472+k*19}" stroke="#30364a" stroke-width="3"/>`).join("")}
      <rect x="330" y="452" width="150" height="188" fill="#08090c"/>
      <g id="co-door"><rect x="330" y="452" width="150" height="188" fill="#3a4150"/>
      ${Array.from({length:9},(_,k)=>`<line x1="330" y1="${472+k*19}" x2="480" y2="${472+k*19}" stroke="#333947" stroke-width="3"/>`).join("")}</g>
      <rect x="540" y="452" width="150" height="188" fill="#39404f"/>
      ${Array.from({length:9},(_,k)=>`<line x1="540" y1="${472+k*19}" x2="690" y2="${472+k*19}" stroke="#30364a" stroke-width="3"/>`).join("")}
      <g id="co-fig"><g id="co-fig-inner">
        <circle cx="0" cy="-158" r="16" fill="#0d0f14"/>
        <path d="M-18,-138 L18,-138 L26,-30 L-26,-30 Z" fill="#0d0f14"/>
        <rect x="-16" y="-32" width="13" height="32" fill="#0d0f14"/><rect x="4" y="-32" width="13" height="32" fill="#0d0f14"/>
      </g></g>
      <rect x="0" y="640" width="800" height="80" fill="#1e222a"/>
      ${puddle(240,70)}${puddle(600,90)}
      <rect x="0" y="380" width="800" height="340" fill="url(#fogG)"/>
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
  };

  /* ---------- corkboard pin thumbnails ---------- */
  const PIN_ART = {
    pin_folder: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#2c2620"/><path d="M22,20 L42,20 L47,26 L78,26 L78,46 L22,46 Z" fill="#c9a86a"/><text x="50" y="16" text-anchor="middle" font-family="Courier New" font-size="9" fill="#c8cbd4">0114</text></svg>`,
    pin_storage: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#232833"/><rect x="30" y="14" width="40" height="38" fill="#3a4150"/><line x1="30" y1="24" x2="70" y2="24" stroke="#2c313c" stroke-width="3"/><line x1="30" y1="34" x2="70" y2="34" stroke="#2c313c" stroke-width="3"/><text x="50" y="12" text-anchor="middle" font-family="Arial Black" font-size="9" fill="#aab2c2">14</text></svg>`,
    pin_gerald: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#232833"/><g transform="translate(32,6) scale(.3)"><path d="M40,70 Q38,30 72,26 Q100,24 104,52 L108,120 Q110,150 92,152 L52,152 Q34,148 36,116 Z" fill="#0d0f14"/><circle cx="96" cy="34" r="14" fill="#0d0f14"/><rect x="58" y="78" width="52" height="38" fill="#7a6244"/></g></svg>`,
    pin_diner: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#1c202a"/><text x="50" y="26" text-anchor="middle" font-family="Georgia" font-size="13" fill="#ff8d5c">COPPER</text><text x="50" y="42" text-anchor="middle" font-family="Georgia" font-size="13" fill="#c2543f">SPOON</text><rect x="20" y="48" width="60" height="3" fill="#ffb35c" opacity=".5"/></svg>`,
    pin_route: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#22262e"/><path d="M42,60 L48,0 L52,0 L58,60 Z" fill="#33383f"/><path d="M49,50 L51,50 L51,38 L49,38 Z M49,30 L51,30 L51,18 L49,18 Z" fill="#c8cbd4"/><path d="M50,4 L44,14 L56,14 Z" fill="#ffb35c"/><text x="76" y="34" font-family="Arial Black" font-size="10" fill="#8d94a3">9</text></svg>`,
    pin_motel: `<svg viewBox="0 0 100 60"><rect width="100" height="60" fill="#10131a"/><text x="50" y="26" text-anchor="middle" font-family="Georgia" font-size="14" fill="#ffb35c">PRESIDIO</text><rect x="40" y="34" width="20" height="18" fill="#efe6cd"/><text x="50" y="48" text-anchor="middle" font-family="Arial Black" font-size="12" fill="#2a251d">6</text></svg>`,
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
    kesslerSVG, NPC_ART, NPC_SIZE, SCENES,
    photoSVG, stingerSVG, coldOpenSVG, folderSVG,
    ICONS, INV_ICONS, PIN_ART, WARM, SIL,
  };
})();
