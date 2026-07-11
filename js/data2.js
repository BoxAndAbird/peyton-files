/* THE PEYTON FILES — Episode 2: "The Transfer"
   Lake City. The paper moves. The courier signs nothing.
   Merged into PF_DATA at load. Tone rule unchanged: Peyton is never funny.
   The comedy lives in the debris. The dread lives in the margins. */
"use strict";

(() => {
  const D = PF_DATA;

  /* ---------------- DOCUMENTS ---------------- */
  D.docs.push(
    {
      id: "d_lccall", icon: "memo", title: "Teletype — Lake City P.D.",
      sub: "The call. Thirty-one boxes.",
      chapter: "file4",
      body: `
<h3>Teletype — Lake City P.D.</h3>
<div class="meta">TO: MILLHAVEN P.D., ATTN DET. KESSLER<br>RE: RECOVERED RECORDS — UNRENTED ANNEX SPACE</div>
<p>Pulled thirty-one (31) boxes of financial records from a municipal annex aisle that, per the city, does not exist. No renter. No paperwork. The boxes are indexed in a hand our examiner calls "institutional."</p>
<p>Sampled contents reference accounts in Millhaven, Harlow, and here. One phrase recurs in the disbursement columns. Your desk sergeant says you know the phrase.</p>
<p>Come see the phrase.</p>
<p class="hand pencil">Three towns. One bookkeeping. The Spoon was a branch office. — M.K.</p>`
    },
    {
      id: "d_memo2", icon: "memo", title: "Routing Memo",
      sub: "Found taped inside box 1 of 31. Redacted.",
      chapter: "file4", puzzle: "redact2",
      body: "" /* built dynamically by the redaction puzzle */
    },
    {
      id: "d_odom_lc", icon: "file", title: "Odom's Lake City Report",
      sub: "Filed 3 years ago. Two weeks before he vanished.",
      chapter: "file4",
      body: `
<h3>Field Report — Det. F. Odom (Copy)</h3>
<div class="meta">JURISDICTION: LAKE CITY (COURTESY)<br>SUBJECT: RECORDS MOVEMENT, UNKNOWN PRINCIPAL</div>
<p>The ledger doesn't stay anywhere. It circulates. Every few years the paper moves cities, and every move has <span class="hl" data-link="courier-a">a courier who signs nothing</span>. Desk staff describe a man who "was already leaving." Nobody remembers his face. Everybody remembers the dolly.</p>
<p>I have been three days behind him for two weeks. The number doesn't change. I've started to think the number is the point.</p>
<p class="hand">If the paper is moving again, follow the intake logs. Follow the blank line. — F.O.</p>
<p class="hand pencil">Three days. His phrase before it was mine. — M.K.</p>`
    },
    {
      id: "d_intake", icon: "memo", title: "Annex Intake Log",
      sub: "Thursday night. The receiving line is blank.",
      chapter: "file4",
      body: `
<h3>Records Annex — Intake Log (Excerpt)</h3>
<div class="meta">PROVIDED BY SGT. A. REYES, NIGHT CUSTODIAN<br>PAGE STAMPED: FORM 11-C ATTACHED (IT WASN'T)</div>
<table>
<tr><td>THU 9:12 PM</td><td>31 boxes, financial</td><td><span class="hl" data-link="courier-b">RECEIVED FROM: — (no signature)</span></td></tr>
<tr><td>THU 9:31 PM</td><td>aisle assignment: 31</td><td>per standing order (nobody's)</td></tr>
<tr><td>THU 11:52 PM</td><td>side door — "MAINTENANCE"</td><td>no maintenance scheduled</td></tr>
</table>
<p class="hand pencil">Nine years of Thursdays in this log. Same blank. The blank has tenure. — M.K.</p>`
    },
    {
      id: "d_manifest", icon: "file", title: "Transfer Manifest — Box 31-C",
      sub: "One volume withdrawn. Wax seal, no name.",
      chapter: "file5",
      body: `
<h3>Manifest — Box 31-C</h3>
<div class="meta">RECOVERED: AISLE 31, THE DARK END<br>SEALED: BLACK WAX, NO SIGNET — PRESSED WITH A THUMB</div>
<table>
<tr><td>VOL. 2 — VOL. 19</td><td>account histories</td><td>PRESENT</td></tr>
<tr><td>VOL. 1</td><td>1931 — origin</td><td><b>WITHDRAWN</b></td></tr>
<tr><td>KEY, VOL. 2</td><td>shorthand</td><td>PRESENT — "DO NOT COPY"</td></tr>
</table>
<p>Margin, small precise hand: <b>5 — 44 / 8</b></p>
<p class="hand pencil">He took the first volume and left the rest like a tip. — M.K.</p>`
    },
    {
      id: "d_key2", icon: "key", title: "Shorthand Key — Vol. 2",
      sub: "The code grew. In one direction.",
      chapter: "file5",
      body: `
<h3>Ledger Shorthand — Key, Vol. 2</h3>
<div class="meta">RECOVERED: BOX 31-C<br>HEADER READS: "DO NOT COPY." THIS ONE ISN'T A COPY. IT'S AN ORIGINAL.</div>
<table>
<tr><td><b>1</b> = RTE 9</td><td><b>2</b> = BANK</td><td><b>3</b> = WEDNESDAY</td></tr>
<tr><td><b>4</b> = SPOON</td><td><b>5</b> = TRANSFER</td><td><b>6</b> = TABLE / ROOM</td></tr>
<tr><td><b>7</b> = STORAGE</td><td><b>8</b> = KEEPER</td><td><b>9</b> = CLOSE</td></tr>
<tr><td><b>0</b> = L.</td><td></td><td></td></tr>
</table>
<p class="hand pencil">Same code as Pruitt's. Two new words: TRANSFER and KEEPER. Vocabularies grow toward what people need to say. — M.K.</p>`
    },
    {
      id: "d_page", icon: "note", title: "Ledger Page — Vol. 1, p. 118",
      sub: "From locker 44. The last line is recent.",
      chapter: "ep2end",
      body: `
<h3>Evidence — Ledger Page (Removed From Vol. 1)</h3>
<div class="meta">FOUND: UNION TERMINAL, LOCKER 44<br>PAPER: 1931 STOCK. INK: TWO KINDS.</div>
<p class="receipt">ACCT 0001 — WHITMORE, L. &nbsp;·&nbsp; OPENED 1931<br>
STATUS ....... SENIOR<br>
KEEPER ....... (rotates — see appendix)<br>
────────────────────</p>
<p>Beneath the old entries, in ballpoint, in a hand I'd been reading for a week off yellowed police reports:</p>
<p class="hand" style="color:#2a251d;font-size:18px">NEXT KEEPER: PENDING.<br>SEE: WHITMORE.</p>
<p class="hand pencil">Iron gall ink for 1931. Ballpoint for the last line. The last line is NEW. Odom didn't stop writing three years ago. He stopped writing to us. — M.K.</p>`
    },
    {
      id: "d_note2", icon: "note", title: "The Second Note",
      sub: "Locker 44. He's stopped apologizing.",
      chapter: "ep2end",
      body: `
<h3>Evidence — Handwritten Note</h3>
<div class="meta">FOUND: LOCKER 44, FOLDED INSIDE THE LEDGER PAGE<br>HANDWRITING MATCHES THE MATCHBOOK. AND THE MOTEL.</div>
<p class="hand" style="color:#2a251d;font-size:18px">Detective —<br><br>
You found the slip because it was left for you. You're not behind anymore.<br><br>
You're expected.</p>
<p class="hand pencil">No signature. The blank where one should be is starting to feel like a name. — M.K.</p>`
    },
  );

  /* ---------------- LOCATION CARDS ---------------- */
  D.locations.annex    = { key:"LOCATION UNLOCKED", name:"LAKE CITY RECORDS ANNEX", sub:"Aisle 31 — night intake only", scene:"annex" };
  D.locations.terminal = { key:"LOCATION UNLOCKED", name:"UNION TERMINAL", sub:"Locker 44 — the dead bank", scene:"terminal" };

  /* ---------------- PUZZLES ---------------- */
  Object.assign(D.puzzles, {
    redact2: {
      title: "DECODE THE ROUTING MEMO",
      hint: "Tap a blacked-out section, then choose what belongs under it. The teletype already told you most of it.",
      intro: `INTERNAL — DO NOT DISTRIBUTE\nRE: CONSIGNMENT`,
      lines: [
        { pre: "Consignment received per standard process. Route the account histories to the ", slot: 0, post: "," },
        { pre: "aisle ", slot: 1, post: ", night intake only. No names on the receiving line." },
        { pre: "The keeper will withdraw what the keeper requires. Do not assist. Do not observe. Gratuities at the usual rate.", slot: -1, post: "" },
        { pre: "— L.", slot: -1, post: "" },
      ],
      slots: [
        { answer: "ANNEX", options: ["BANK","TERMINAL","ANNEX","LAKE"] },
        { answer: "31", options: ["14","31","44","9"] },
      ],
      solvedNarration: "The annex. Aisle thirty-one. 'The keeper will withdraw what the keeper requires.' Filed under L., same bored tone. Cancel a magazine, close a man, route a city's memory. Standard process.",
      toast: "Memo decoded — THE ANNEX, AISLE 31.",
    },
    crossref2: {
      title: "CROSS-REFERENCE",
      hint: "Two documents, three years apart, describe the same nobody. Tap the matching detail in each one.",
      pair: ["courier-a","courier-b"],
      docA: "d_odom_lc", docB: "d_intake",
      solvedNarration: "A courier who signs nothing, in Odom's report. A blank receiving line, Thursday night, nine years running. The same empty space — still making deliveries.",
      toast: "Documents linked — THE COURIER.",
    },
    cipher2: {
      title: "DECODE THE CLAIM SLIP",
      hint: "The manifest margin reads 5 — 44 / 8. Use the Vol. 2 key. A number is still a number.",
      code: ["5","44","8"],
      slotLabels: ["5","44","8"],
      answers: ["TRANSFER","44","KEEPER"],
      options: [
        ["CLOSE","TRANSFER","STORAGE","BANK"],
        ["31","9","44","6"],
        ["L.","WEDNESDAY","KEEPER","RTE 9"],
      ],
      note: "Second symbol reads literally — a number is a number.",
      solvedNarration: "Transfer. Forty-four. Keeper. The claim slip wasn't a lead I found. It was a delivery I signed for. He's moving the first volume through the terminal — locker forty-four — keeper to keeper.",
      toast: "Code broken — TRANSFER, LOCKER 44, THE KEEPER.",
    },
    timeline2: {
      title: "REBUILD THURSDAY NIGHT",
      hint: "Tap the records in order, earliest first. Follow the timestamps.",
      items: [
        { id:"u1", tag:"INTAKE LOG", text:"THU 9:12 PM — 31 boxes arrive. Receiving line: blank", order:0 },
        { id:"u2", tag:"INTAKE LOG", text:"THU 11:52 PM — side door opens. Log says MAINTENANCE", order:1 },
        { id:"u3", tag:"SCALE RECORD", text:"FRI 12:31 AM — box 31-C reweighed. Four pounds lighter", order:2 },
        { id:"u4", tag:"CAB SHEET", text:"FRI 1:15 AM — one fare, annex to Union Terminal. No talker", order:3 },
        { id:"u5", tag:"CAMERA LOG", text:"FRI 1:44 AM — locker hall camera loops the same empty minute", order:4 },
      ],
      solvedNarration: "Deliver a city's memory at nine. Come back through the side door at eleven fifty-two — always eleven fifty-two. Lift one volume, four pounds of 1931, and check it into a dead locker like luggage. The camera looped. Cameras around this man develop habits.",
      toast: "Thursday night reconstructed.",
    },
    vault: {
      title: "LOCKER 44 — COMBINATION",
      hint: "Three numbers, left to right. His own paperwork: the aisle, the locker, the close.",
      combo: [31, 44, 9],
      comboLabels: ["AISLE","LOCKER","CLOSE"],
      max: 49,
      solvedNarration: "Thirty-one, forty-four, nine. He sets his combinations out of his own ledger — a man so certain nobody's reading that he files his secrets under their own names.",
      toast: "Locker 44 — OPEN.",
    },
  });

  /* ---------------- NARRATION ---------------- */
  Object.assign(D.narration, {
    file4_intro: "Lake City kept its rain colder. They walked me past thirty-one boxes to a phrase written in a disbursement column, and the room went quiet while I read it. CLOSING THE ACCOUNT. Same hand. Same bored little letters. Millhaven wasn't the business. Millhaven was a branch.",
    world4_arrive: "The annex. A city's whole memory in cardboard, one bulb in three burned out. The lights ended at aisle thirty. Thirty-one kept its own dark.",
    world4_done: "Odom's name, filed under nine years of Thursdays. A courier nobody sees, delivering paper nobody rented, to an aisle nobody lit. I signed Reyes' sheet on the way out. Somebody should get to keep one honest record in that building.",
    world5_arrive: "Union Terminal, past midnight. Four hundred feet of marble built for crowds that stopped coming, and a clock with an opinion about eleven fifty-two.",
    ep2_ring: "Millhaven front desk, patched through twice. A package, no sender, ledger paper, lamp oil. My name on it in iron gall ink. People had stopped mailing me things I wanted.",
    ep2_stinger: "The page from the locker. I'd read it forty times on the drive home. I'd only just noticed what the paper under the ballpoint said.",
  });

  /* ---------------- DIALOGUE ---------------- */
  Object.assign(D.dialogue, {
    /* ————— SGT. ALMA REYES — records annex ————— */
    y_intro: {
      lines: [
        ["REYES","Stop. Sign the sheet."],
        ["KESSLER","Detective Kessler. Millhaven."],
        ["REYES","And I'm the only reason this building has a memory. Sign the sheet."],
        ["KESSLER","...You use iron gall ink?"],
        ["REYES","It outlives ballpoint. I plan ahead."],
      ],
      sets: "y_talked",
      choices: "y_hub",
    },
    y_hub: {
      speaker: "REYES",
      options: [
        { label: "“The thirty-one boxes.”", node: "y_boxes" },
        { label: "“Who delivered them?”", node: "y_courier" },
        { label: "“What's down the dark aisle?”", node: "y_dark", flavor: true },
        { label: "[Step back]", node: null },
      ],
    },
    y_boxes: {
      lines: [
        ["REYES","Aisle thirty-one. And before you ask — the lights end at thirty. I filed a work order on that in March."],
        ["REYES","It came back stamped DISCONTINUED. Not denied. Not deferred. Discontinued. Like the aisle canceled its own subscription."],
      ],
      sets: "y_boxes",
      choices: "y_hub",
    },
    y_courier: {
      lines: [
        ["REYES","Nobody. I mean — somebody, obviously. Nine years of Thursdays, same blank line."],
        ["REYES","I hear the dolly. Every time, I hear the dolly. I have never once heard footsteps."],
        ["KESSLER","You've listened for them."],
        ["REYES","I'm a records custodian, Detective. Listening for what's missing is the whole job."],
      ],
      sets: "y_courier",
      choices: "y_hub",
    },
    y_dark: {
      lines: [
        ["REYES","Paper. Paper doesn't scare me."],
        ["REYES","Filing errors scare me. That aisle has never produced one. Nine years, not one misfile. Nothing human files that clean."],
      ],
      choices: "y_hub",
    },
    y_card: {
      lines: [
        ["KESSLER","This was in box 31-C. Property of F. Odom."],
        ["REYES","...That name is on my intake ledger. The old pages. He used to sign."],
        ["REYES","Then one Thursday he stopped signing, and the line went blank, and the blank never missed a week since."],
        ["REYES","Here. This was clipped to Thursday's sheet. It has your name on it, and I want it out of my building."],
        ["KESSLER","A claim slip."],
        ["REYES","Union Terminal. Locker bank's been dead since before me. Sign for it. — Please."],
      ],
      onEnd: "give_slip",
    },

    /* ————— WES — union terminal, lost & found ————— */
    w_intro: {
      lines: [
        ["WES","Lost and found's closed."],
        ["KESSLER","The sign says open."],
        ["WES","The sign's lost too. It's a whole thing."],
      ],
      choices: "w_hub",
    },
    w_hub: {
      speaker: "WES",
      options: [
        { label: "“Locker forty-four.”", node: "w_44" },
        { label: "“What's platform nine?”", node: "w_nine", flavor: true },
        { label: "“What's in your book?”", node: "w_book", flavor: true },
        { label: "[Step back]", node: null },
      ],
    },
    w_44: {
      lines: [
        ["WES","That bank's out of service. Since before me. Since before the guy before me, and that guy's retirement party was in black and white."],
        ["WES","Tall fella still comes, though. Monthly. Doesn't rattle the door like normal people. It's just... open, for him. Doors do that around him. I stopped saying hi."],
        ["KESSLER","Why'd you stop?"],
        ["WES","He said hi back once. My headphones were in. I heard it anyway."],
      ],
      sets: "w_talked",
      choices: "w_hub",
    },
    w_nine: {
      lines: [
        ["WES","Ghost platform. No trains since the war. Best acoustics in the building though."],
        ["WES","Sometimes I eat lunch down there and the echo finishes chewing after I do."],
      ],
      choices: "w_hub",
    },
    w_book: {
      lines: [
        ["WES","Unclaimed property ledger. One hundred and nine umbrellas. Four wedding rings. A prosthetic leg, left, size ten."],
        ["WES","People only lose the good stuff once. The umbrellas are a lifestyle."],
      ],
      choices: "w_hub",
    },

    /* item responses live on the NPC defs below */
  });

  /* ---------------- WORLD SCENES ----------------
     Coordinates are tuned to the painted backdrops (art/bg_annex, art/bg_terminal). */
  D.scenes.annex = {
    title: "LAKE CITY RECORDS ANNEX — NIGHT",
    width: 1707, spawnX: 150, ground: 650,
    art: "bg_annex", dark: true, darkFrom: 730,
    haunt: "annex",
    hotspots: [
      { id:"h_desk", x:105, y:530, label:"Intake desk",
        examine: "Reyes' desk. The intake ledger sits square to the blotter, which sits square to the world. One pen. Iron gall ink. A person holding a line." },
      { id:"h_lights", x:740, y:300, label:"Where the lights end",
        examine: "The fixtures keep going. The light doesn't. Work order DISCONTINUED — the aisle put a stop to its own maintenance." },
      { id:"h_dolly", x:1090, y:520, label:"Evidence dolly",
        examine: "A hand dolly, parked mid-aisle in the dark, facing out. The handle is warm. Dollies aren't warm." },
      { id:"h_box31c", x:1480, y:470, label:"Box 31-C — the dark end", showFlag:"y_boxes",
        examine: "Box 31-C, lid loose. Inside: eighteen volumes, a shorthand key marked DO NOT COPY — and an index card in a fast, tired hand. PROPERTY OF F. ODOM.",
        gives: ["d_manifest","d_key2"], givesItem2:"indexcard",
        toastText:"Evidence added: manifest + Vol. 2 key. Taken: Odom's index card." },
    ],
    npcs: [
      { id:"reyes", x:280, name:"REYES", art:"npc_reyes",
        dialogue:"y_intro", hub:"y_hub",
        itemResponses: {
          badge: { lines: [["REYES","That works on doors. In here it's still not form 11-C."]] },
          indexcard: "y_card",
          matchbook: { lines: [["REYES","The Copper Spoon. Millhaven. That's a four-county drive, Detective."],["KESSLER","It's on the same books."],["REYES","...Sign the sheet on your way out."]] },
        },
      },
    ],
  };

  D.scenes.terminal = {
    title: "UNION TERMINAL — 1:40 A.M.",
    width: 1707, spawnX: 140, ground: 655,
    haunt: "terminal",
    art: "bg_terminal",
    hotspots: [
      { id:"h_clock", x:388, y:195, label:"The clock",
        examine: "Stopped at eleven fifty-two. I was starting to hate that number the way you hate a song you can't put down." },
      { id:"h_bench", x:478, y:470, label:"Waiting benches",
        examine: "One glove, one bench, forty years. Wes has it in the book: GLOVE, LEFT, UNCLAIMED. Underneath he's written 'still waiting' — filed under W." },
      { id:"h_board", x:909, y:270, label:"Departures board",
        examine: "Blank since the last timetable mattered. The dust on it is thinner than it should be. Something keeps touching it." },
      { id:"h_locker44", x:1590, y:400, label:"Locker 44", worldPuzzle:"vault", needsFlag:"w_talked",
        examineLocked: "A wall of dead lockers, keyed shut since the war. Forty-four doesn't look special. That's its job. Wes might know its habits." },
    ],
    npcs: [
      { id:"wes", x:330, name:"WES", art:"npc_wes",
        dialogue:"w_intro", hub:"w_hub",
        itemResponses: {
          badge: { lines: [["WES","Cool. We can't take badges. Policy. People kept losing them on purpose."]] },
          claimslip: { lines: [["WES","Locker 44... yeah. That's the tall fella's bank."],["WES","If your name's on a slip for it, either you won something or you ARE something. Around here it's usually the second one."]] },
          greasemap: { lines: [["WES","That's not ours. We only do lost stuff."],["WES","...That map doesn't look lost. That map looks sent."]] },
        },
      },
    ],
  };
})();
