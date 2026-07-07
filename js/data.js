/* THE PEYTON FILES — Episode 1: "The Closing Notice"
   All story content: documents, dialogue, puzzles, narration.
   Tone rule: Peyton is never funny. The comedy lives in the debris. */
"use strict";

const PF_DATA = {

  meta: {
    caseNo: "CASE 0114",
    title: "THE PEYTON FILES",
    episode: "EPISODE 1 — THE CLOSING NOTICE",
  },

  /* ---------------- CHAPTERS (linear spine) ----------------
     cold  → file1 (puzzles: photo, redact) → world1 (storage)
           → file2 (puzzles: crossref, cipher) → world2 (diner)
           → file3 (puzzles: timeline, string)  → world3 (motel)
           → epilogue */
  chapters: ["cold","file1","world1","file2","world2","file3","world3","epilogue"],

  objectives: {
    file1: "Read Odom's file.\nReassemble the torn photo.\nDecode the memo.",
    world1: "Search the storage facility.\nUnit 14.",
    file2: "Link the two documents\nthat mention the Spoon.\nDecode the matchbook code.",
    world2: "Talk to the waitress\nat the Copper Spoon.",
    file3: "Reconstruct his last 48 hours.\nRun the string on the board.",
    world3: "Presidio Motor Lodge.\nRoom 6.",
    epilogue: "—",
  },

  /* ---------------- DOCUMENTS ---------------- */
  docs: [
    {
      id: "d_odom", icon: "file", title: "Odom's Case File",
      sub: "Unfinished. Last entry: 3 years ago.",
      chapter: "file1",
      body: `
<h3>Millhaven P.D. — Case 0114</h3>
<div class="meta">SUBJECT: VOSS, PEYTON — no photo on record<br>
FILED BY: DET. F. ODOM &nbsp;·&nbsp; STATUS AT LAST ENTRY: ACTIVE</div>
<p>Nobody's seen his face. I have two blurry stills and a town full of people who each describe a different man. Taller. Shorter. Glasses. No glasses. The only thing they agree on is that they'd rather not talk about him.</p>
<p>Whatever he runs, it isn't muscle. It's paper. Debts, favors, signatures. People don't work for him because they're paid. They work for him because they owe.</p>
<p>They have a phrase in this town. You hear it at the bank, at the diner, at the storage place off Route 9. <b>"Closing the account."</b> Nobody will tell me what it means. Everybody knows what it means.</p>
<p>I'm close to the bookkeeping now. If the ledger is real, then somewhere out there is a man whose entire job is</p>
<p class="hand">— entry ends here. F.O.</p>
<p class="hand pencil">Paperclipped index card, Odom's handwriting:<br>"PRUITT, GERALD — bookkeeper(?) — rents storage off Rte 9"</p>
<div class="coffee" style="top:34%;right:8%"></div>`
    },
    {
      id: "d_photo", icon: "photo", title: "Torn Surveillance Photo",
      sub: "Recovered from Odom's desk. In pieces.",
      chapter: "file1", puzzle: "photo",
      body: `
<h3>Evidence — Photograph</h3>
<div class="meta">SOURCE: ODOM'S DESK DRAWER, TAPED ENVELOPE<br>CONDITION: TORN INTO NINE PIECES</div>
<p>A surveillance photo, torn up by hand and kept anyway. Somebody wanted it destroyed. Somebody else couldn't quite do it.</p>
<p class="hand pencil">On the envelope: "the storage place. LOOK AT THE DOOR." — F.O.</p>`
    },
    {
      id: "d_memo", icon: "memo", title: "Internal Memo",
      sub: "The Ledger. Redacted.",
      chapter: "file1", puzzle: "redact",
      body: "" /* built dynamically by the redaction puzzle */
    },
    {
      id: "d_gerald", icon: "file", title: "Interview — G. Pruitt",
      sub: "Statement taken at the storage facility.",
      chapter: "file2",
      body: `
<h3>Subject Interview — Pruitt, Gerald</h3>
<div class="meta">LOCATION: MILLHAVEN SELF-STORAGE, UNIT 14<br>SUBJECT FOUND: SHELTERING AMONG BOXES OF LEDGERS</div>
<p>Subject states he "just kept the books." Subject states he is "not stupid" and knows what closing an account means. Subject states, in his own defense, that he has a <span class="hl" data-link="x1">401k</span>, and that people with 401ks "don't do the things you're describing."</p>
<p>Subject surrendered one (1) matchbook, <span class="hl" data-link="spoon-a">THE COPPER SPOON</span>, after it fell out of his jacket. Subject became cooperative in the manner of a man who has just remembered he is flammable.</p>
<p>Per subject: the meetings that don't get written down happen at the Spoon.</p>
<p class="hand pencil">He asked me four times whether he was "written down." I told him I'd check. — M.K.</p>`
    },
    {
      id: "d_ledger", icon: "memo", title: "Ledger Sheet (Partial)",
      sub: "Disbursements. Taken from Unit 14.",
      chapter: "file2",
      body: `
<h3>Ledger — Disbursements (Partial)</h3>
<div class="meta">RECOVERED: UNIT 14, BOX 7 OF 31<br>HANDWRITING: NOT PRUITT'S</div>
<table>
<tr><td>04</td><td><span class="hl" data-link="spoon-b">C. SPN — table svc</span></td><td>20.00% — recurring</td></tr>
<tr><td>07</td><td><span class="hl" data-link="x2">storage, rte 9</span></td><td>paid, cash</td></tr>
<tr><td>11</td><td>account services</td><td>per L. — as needed</td></tr>
<tr><td>19</td><td><span class="hl" data-link="x3">flowers</span></td><td>discontinued</td></tr>
</table>
<p class="hand pencil">"C. SPN." Same twenty percent, every month, to the penny. — M.K.</p>`
    },
    {
      id: "d_matchbook", icon: "match", title: "Matchbook",
      sub: "The Copper Spoon. Writing inside the cover.",
      chapter: "file2", puzzle: "cipher",
      body: `
<h3>Evidence — Matchbook</h3>
<div class="meta">SOURCE: G. PRUITT (SURRENDERED)<br>EXTERIOR: "THE COPPER SPOON — FINE ENOUGH FOOD"</div>
<p>Inside the cover, in small, precise handwriting:</p>
<p class="hand" style="font-size:22px;text-align:center;color:#2a251d">6 — 6 &nbsp;/&nbsp; 3</p>
<p>Not Pruitt's handwriting either. Nobody who panics that much writes that straight.</p>`
    },
    {
      id: "d_key", icon: "key", title: "Shorthand Key",
      sub: "Ledger code. A copy of a copy.",
      chapter: "file2",
      body: `
<h3>Ledger Shorthand — Key</h3>
<div class="meta">RECOVERED: UNIT 14, TUCKED INSIDE BOX 7<br>HEADER READS: "DO NOT COPY." THIS IS A COPY.</div>
<table>
<tr><td><b>1</b> = RTE 9</td><td><b>2</b> = BANK</td><td><b>3</b> = WEDNESDAY</td></tr>
<tr><td><b>4</b> = SPOON</td><td><b>6</b> = TABLE / ROOM</td><td><b>7</b> = STORAGE</td></tr>
<tr><td><b>9</b> = CLOSE</td><td><b>0</b> = L.</td><td></td></tr>
</table>
<p class="hand pencil">Pruitt kept his own key to their code. For "his protection." It's protecting me instead. — M.K.</p>`
    },
    {
      id: "d_ticket", icon: "receipt", title: "Diner Guest Check",
      sub: "This morning. Table 6.",
      chapter: "file3",
      body: `
<h3>Guest Check — The Copper Spoon</h3>
<div class="meta">PULLED FROM THE TICKET SPIKE BY DENISE</div>
<p class="receipt">THE COPPER SPOON — MILLHAVEN<br>
WED &nbsp;6:48 AM &nbsp;—&nbsp; TBL 6 &nbsp;—&nbsp; GUESTS: 1<br>
────────────────────<br>
1 &nbsp;COFFEE, BLACK ........ 3.00<br>
&nbsp;&nbsp;&nbsp;TIP .................. 0.60<br>
────────────────────<br>
PAID CASH — NO CHANGE TAKEN</p>
<p class="hand pencil">Twenty percent. To the penny. Of a coffee he didn't finish. — M.K.</p>`
    },
    {
      id: "d_gas", icon: "receipt", title: "Gas Station Receipt",
      sub: "Route 9 Fuel. Found in booth six.",
      chapter: "file3",
      body: `
<h3>Receipt — Route 9 Fuel</h3>
<div class="meta">FOUND: WEDGED UNDER THE TABLE, BOOTH 6</div>
<p class="receipt">ROUTE 9 FUEL — PUMP 2<br>
WED &nbsp;7:41 AM<br>
PREMIUM ........ 18.2 GAL<br>
CASH<br>
THANK YOU DRIVE SAFE</p>
<p>Printed on the reverse, an advertisement:</p>
<p class="receipt" style="text-align:center"><b>STAY THE NIGHT — PRESIDIO MOTOR LODGE<br>4 MILES NORTH ON RTE 9 — WEEKLY RATES</b></p>
<p class="hand pencil">A full tank, four miles from a motel. He wasn't running. He was finishing. — M.K.</p>`
    },
    {
      id: "d_gatelog", icon: "memo", title: "Storage Gate Log",
      sub: "Subpoenaed. Camera conveniently offline.",
      chapter: "file3",
      body: `
<h3>Millhaven Self-Storage — Gate Log</h3>
<div class="meta">OBTAINED BY SUBPOENA — UNIT 14 ACCESS CODE</div>
<p class="receipt">TUE &nbsp;11:52 PM — CODE 4471 — IN<br>
WED &nbsp;12:37 AM — CODE 4471 — OUT<br>
WED &nbsp;&nbsp;5:55 AM — CAMERA OFFLINE ("MAINTENANCE")</p>
<p class="hand pencil">He gave himself forty-five minutes to empty three years of paper. It was enough. — M.K.</p>`
    },
    {
      id: "d_note", icon: "note", title: "The Note",
      sub: "Room 6. Addressed to me by name.",
      chapter: "epilogue",
      body: `
<h3>Evidence — Handwritten Note</h3>
<div class="meta">FOUND: NIGHTSTAND, ROOM 6, PRESIDIO MOTOR LODGE<br>HANDWRITING MATCHES THE MATCHBOOK.</div>
<p class="hand" style="color:#2a251d;font-size:18px">Detective —<br><br>
Three days too late, same as always. Tell whoever sent you that punctuality was never their strong suit either.</p>
<p class="hand pencil" style="margin-top:16px">No signature. He knew he didn't need one. — M.K.</p>`
    },
  ],

  /* ---------------- LOCATION CARDS ---------------- */
  locations: {
    storage: { key:"LOCATION UNLOCKED", name:"MILLHAVEN SELF-STORAGE", sub:"Unit 14 — off Route 9", scene:"storage" },
    diner:   { key:"LOCATION UNLOCKED", name:"THE COPPER SPOON", sub:"Table 6 — it's Wednesday", scene:"diner" },
    motel:   { key:"LOCATION UNLOCKED", name:"PRESIDIO MOTOR LODGE", sub:"Room 6 — 4 miles north, Rte 9", scene:"motel" },
  },

  /* ---------------- PUZZLES ---------------- */
  puzzles: {
    photo: {
      title: "REASSEMBLE THE PHOTO",
      hint: "Tap two pieces to swap them. Odom said: look at the door.",
      solvedNarration: "Unit fourteen. Odom circled the door three years ago. The door hadn't gone anywhere.",
      toast: "Photo reassembled — UNIT 14.",
    },
    redact: {
      title: "DECODE THE REDACTIONS",
      hint: "Tap a blacked-out section, then choose what belongs under it. The answers are already in the file.",
      intro: `INTERNAL — DO NOT DISTRIBUTE\nRE: ACCOUNT SERVICES`,
      lines: [
        { pre: "Per review, we will be closing the account of G. ", slot: 0, post: "" },
        { pre: "effective immediately. Contents of unit ", slot: 1, post: " are to be consolidated per standard process." },
        { pre: "Please handle promptly and without ceremony. Gratuities have been arranged at the usual rate.", slot: -1, post: "" },
        { pre: "— L.", slot: -1, post: "" },
      ],
      slots: [
        { answer: "PRUITT", options: ["ODOM","PRUITT","WHITLOCK","VOSS"] },
        { answer: "14", options: ["6","41","14","9"] },
      ],
      solvedNarration: "Closing the account of G. Pruitt. Unit fourteen. Filed in the same bored tone you'd use to cancel a magazine.",
      toast: "Memo decoded — G. PRUITT, UNIT 14.",
    },
    crossref: {
      title: "CROSS-REFERENCE",
      hint: "Two documents mention the same place under different names. Tap the matching detail in each one.",
      pair: ["spoon-a","spoon-b"],
      docA: "d_gerald", docB: "d_ledger",
      solvedNarration: "“The Copper Spoon.” “C. SPN — table svc.” The Ledger had been paying the diner's tab for years. Table service, twenty percent, recurring.",
      toast: "Documents linked — THE SPOON.",
    },
    cipher: {
      title: "DECODE THE MATCHBOOK",
      hint: "Use Pruitt's shorthand key. Tap the meaning of each symbol: 6 — 6 / 3.",
      code: ["6","6","3"],
      slotLabels: ["6","6","3"],
      answers: ["TABLE / ROOM","6","WEDNESDAY"],
      options: [
        ["RTE 9","TABLE / ROOM","CLOSE","BANK"],
        ["14","9","6","41"],
        ["WEDNESDAY","STORAGE","L.","SPOON"],
      ],
      note: "Second symbol reads literally — a number is a number.",
      solvedNarration: "Table six. Wednesdays. Today was Wednesday. For once in this case, I was early for something.",
      toast: "Code broken — TABLE 6, WEDNESDAYS.",
    },
    timeline: {
      title: "RECONSTRUCT THE 48 HOURS",
      hint: "Tap the records in order, earliest first. Follow the timestamps.",
      items: [
        { id:"t1", tag:"GATE LOG", text:"TUE 11:52 PM — storage gate IN, code 4471", order:0 },
        { id:"t2", tag:"GATE LOG", text:"WED 12:37 AM — storage gate OUT, code 4471", order:1 },
        { id:"t3", tag:"GATE LOG", text:"WED 5:55 AM — storage camera goes offline", order:2 },
        { id:"t4", tag:"GUEST CHECK", text:"WED 6:48 AM — black coffee, table 6, the Spoon", order:3 },
        { id:"t5", tag:"RECEIPT", text:"WED 7:41 AM — 18.2 gallons, Route 9 Fuel, heading north", order:4 },
      ],
      solvedNarration: "Empty the unit. Wipe the camera. One last coffee he didn't finish. Then a full tank, pointed north up Route 9 — straight past a motel with weekly rates.",
      toast: "Timeline reconstructed.",
    },
    string: {
      title: "RUN THE STRING",
      hint: "On the board: connect the storage unit to the diner, and the diner to Route 9. Tap one pin, then the other.",
      connections: [["p_storage","p_diner"],["p_diner","p_route9"]],
      solvedNarration: "Storage. The Spoon. Route 9 north. A man of habits — table six at the diner, and a motel four miles on. He'd take room six or no room at all.",
      toast: "Route deduced — PRESIDIO MOTOR LODGE, ROOM 6.",
    },
  },

  /* ---------------- BOARD PINS ---------------- */
  pins: [
    { id:"p_case",    label:"Case 0114 — Voss, P.", art:"pin_folder",  at:"file1",  x:.50, y:.08 },
    { id:"p_storage", label:"Millhaven Self-Storage — Unit 14", art:"pin_storage", at:"photo", x:.16, y:.30 },
    { id:"p_pruitt",  label:"G. Pruitt — bookkeeper", art:"pin_gerald", at:"redact", x:.80, y:.28 },
    { id:"p_diner",   label:"The Copper Spoon — table 6", art:"pin_diner", at:"crossref", x:.30, y:.56 },
    { id:"p_route9",  label:"Route 9 — north, full tank", art:"pin_route", at:"timeline", x:.72, y:.60 },
    { id:"p_motel",   label:"Presidio Motor Lodge — Rm 6", art:"pin_motel", at:"string", x:.50, y:.84, loc:true },
  ],

  /* ---------------- INVENTORY ITEMS ---------------- */
  items: {
    badge:     { name:"Badge", icon:"i_badge",  desc:"Detective M. Kessler, Millhaven P.D." },
    matchbook: { name:"Matchbook", icon:"i_match", desc:"The Copper Spoon. Writing inside the cover." },
    ticket:    { name:"Guest Check", icon:"i_ticket", desc:"Wed, 6:48 AM. Table 6. Black coffee." },
    gasreceipt:{ name:"Gas Receipt", icon:"i_gas", desc:"Route 9 Fuel, 7:41 AM. Motel ad on the back." },
  },

  /* ---------------- NARRATION (Kessler internal) ---------------- */
  narration: {
    file1_intro: "They handed me the file at 8 A.M. with the coffee still hot. Frank Odom's case. Frank Odom's handwriting. Frank Odom, three years missing, mid-sentence.",
    world1_arrive: "Millhaven Self-Storage. Forty units of things people couldn't keep and couldn't throw away. Unit fourteen was the one with the light on.",
    world1_done: "Pruitt would keep. He wasn't going anywhere he couldn't take his paperwork.",
    world2_arrive: "The Copper Spoon. Table six was wiped clean and empty, and the whole place was arranged so nobody had to look at it.",
    world2_done: "He'd sat here hours ago, rattled enough to leave a receipt behind. The numbers didn't lie. Someone here had been keeping score for a long, long time.",
    world3_arrive: "Presidio Motor Lodge, room six. The door was open. The smell of bleach reached the parking lot.",
    world3_gone: "They packed the van like movers and drove off under the limit. Nothing to hold them on. You can't book a mop.",
    world3_note: "He knew my name. He knew my timing. Three days — which meant he'd counted, which meant he'd watched.",
    epilogue_ring: "Lake City P.D. They'd found paper. A lot of paper. And a phrase they wanted me to hear in person.",
    stinger: "Old surveillance still, from Odom's file. I'd looked at it a hundred times. I'd never looked at the doorway.",
  },

  /* ---------------- DIALOGUE TREES ---------------- */
  dialogue: {
    /* ————— GERALD PRUITT — storage ————— */
    g_intro: {
      speaker: null,
      lines: [
        ["KESSLER","Gerald Pruitt?"],
        ["GERALD","No.  ...Okay, yes. Statistically, you were going to say a name eventually."],
        ["KESSLER","You're hiding in a storage unit, Mr. Pruitt."],
        ["GERALD","I am ORGANIZING a storage unit. There's a difference, and the difference is intent."],
      ],
      sets: "g_talked",
      choices: "g_hub",
    },
    g_hub: {
      speaker: "GERALD",
      prompt: null,
      options: [
        { label: "“You kept the books for Voss.”", node: "g_books" },
        { label: "“What's in the boxes?”", node: "g_boxes", flavor: true },
        { label: "“Where is he now?”", node: "g_voss" },
        { label: "[Step back]", node: null },
      ],
    },
    g_books: {
      lines: [
        ["GERALD","I just kept the books! I mean — obviously I knew what “closing the account” meant, I'm not stupid, I just — I have a 401k. People with 401ks don't do the things you're describing."],
        ["KESSLER","I haven't described anything yet."],
        ["GERALD","And I'd like it to stay that way!"],
      ],
      sets: "g_talked",
      choices: "g_hub",
    },
    g_boxes: {
      lines: [
        ["GERALD","These are MY copies. For MY protection. That is a normal thing an innocent bookkeeper has."],
        ["GERALD","Please don't touch the tabs. The tabs are load-bearing."],
      ],
      sets: "g_talked",
      choices: "g_hub",
    },
    g_voss: {
      lines: [
        ["GERALD","You don't find him. You get... found. Like an audit."],
        ["GERALD","...I'm going to stop talking now. Forever, ideally."],
      ],
      sets: "g_talked",
      choices: "g_hub",
    },
    g_match: {
      lines: [
        ["KESSLER","This fell out of your jacket."],
        ["GERALD","Where did— okay. Fine. The Spoon. The diner. The meetings that don't get written down happen at the Spoon."],
        ["GERALD","If he's in town, he's been there. Oh god. Am I written down? AM I WRITTEN DOWN?"],
        ["KESSLER","I'll check."],
      ],
      onEnd: "world1_complete",
    },

    /* ————— DENISE — diner ————— */
    d_intro: {
      lines: [
        ["DENISE","Sit anywhere, hon. Except booth six. Booth six is reserved."],
        ["KESSLER","Reserved for who?"],
        ["DENISE","That's booth-six business."],
      ],
      choices: "d_hub",
    },
    d_hub: {
      speaker: "DENISE",
      options: [
        { label: "Show the badge. Ask about the tall man.", node: "d_tall" },
        { label: "“People stop coming back?”", node: "d_gone", flavor: true, needs: "d_talked" },
        { label: "“Was he in recently?”", node: "d_today", needs: "d_talked" },
        { label: "“How's the pie?”", node: "d_pie", flavor: true },
        { label: "[Step back]", node: null },
      ],
    },
    d_tall: {
      lines: [
        ["DENISE","Oh, the tall fella with the ledger obsession? Comes in every few months. Black coffee. Tips exactly twenty percent, to the penny."],
        ["DENISE","Once a year, somebody who sat in his booth doesn't come back. Stopped asking. Pie's still good, though."],
        ["KESSLER","His booth."],
        ["DENISE","Six. Always six. Won't sit nowhere else."],
      ],
      sets: "d_talked",
      choices: "d_hub",
    },
    d_gone: {
      lines: [
        ["KESSLER","People don't come back, and you stopped asking."],
        ["DENISE","First time, I filed a report. Second time, they lost the report."],
        ["DENISE","Third time the officer stopped coming back too, so. Pie?"],
      ],
      choices: "d_hub",
    },
    d_pie: {
      lines: [
        ["DENISE","Cherry today. The pie outlives everybody, hon. That's not a saying, it's just arithmetic."],
      ],
      choices: "d_hub",
    },
    d_today: {
      lines: [
        ["DENISE","This morning, matter of fact. Quarter to seven. Never once seen him before ten."],
        ["DENISE","Didn't finish his coffee, neither."],
        ["KESSLER","Rattled?"],
        ["DENISE","Well. He tipped twenty percent."],
        ["KESSLER","So?"],
        ["DENISE","Of a coffee he didn't finish. That man doesn't round. Something's off with him."],
      ],
      sets: "d_told_today",
      choices: "d_hub",
    },
    d_spike: {
      lines: [
        ["KESSLER","I need this morning's ticket. Table six."],
        ["DENISE","Knock yourself out. Tell the spike I'm sorry."],
      ],
      onEnd: "give_ticket",
    },
    d_booth: {
      lines: [
        ["KESSLER","Something's wedged under the table."],
        ["DENISE","He dropped it, or he left it. With him, those are different things."],
      ],
      onEnd: "give_gas",
    },

    /* ————— ROY & DALE — motel ————— */
    r_ambient: [
      ["ROY","You said the account was closed before we tossed the room."],
      ["DALE","I said it was closing. There's a process, Roy."],
      ["ROY","There's no process. There's a guy. Now there's not a guy."],
      ["DALE","That's the process."],
    ],
    r_intro: {
      lines: [
        ["ROY","Ma'am, this is a routine deep clean."],
        ["DALE","Scheduled."],
        ["ROY","Pre-scheduled."],
        ["DALE","That's what scheduled means, Roy."],
      ],
      choices: "r_hub",
    },
    r_hub: {
      speaker: "ROY & DALE",
      options: [
        { label: "“You're cleaning a crime scene.”", node: "r_scene" },
        { label: "“Where's Voss?”", node: "r_voss" },
        { label: "“Who was in this room?”", node: "r_who", flavor: true },
        { label: "[Let them finish]", node: "r_leave" },
      ],
    },
    r_scene: {
      lines: [
        ["DALE","We're cleaning a room. Whether it's a scene is a question for after we're done."],
        ["DALE","And after we're done, it never is."],
        ["ROY","...That was pretty good, Dale."],
        ["DALE","Don't."],
      ],
      choices: "r_hub",
    },
    r_voss: {
      lines: [
        ["ROY","Who?"],
        ["DALE","We do floors."],
      ],
      choices: "r_hub",
    },
    r_who: {
      lines: [
        ["ROY","Room was empty when we got here. Room's emptier now."],
        ["DALE","That's the job. Emptier."],
      ],
      choices: "r_hub",
    },
    r_leave: {
      lines: [
        ["ROY","Ma'am."],
        ["DALE","Ma'am."],
      ],
      onEnd: "whitlocks_leave",
    },
  },

  /* ---------------- WORLD SCENES ---------------- */
  scenes: {
    storage: {
      title: "MILLHAVEN SELF-STORAGE — DUSK",
      width: 2000, spawnX: 130,
      arrive: "world1_arrive",
      hotspots: [
        { id:"h_units", x:520, y:470, label:"Storage units",
          examine: "Rolled steel doors, padlocked. Numbers eleven, twelve, thirteen. Nobody's business, twice over." },
        { id:"h_gate", x:150, y:460, label:"Gate keypad",
          examine: "A gate code keypad. The log for this thing is going to make somebody's week. Probably mine." },
        { id:"h_unit14", x:1075, y:460, label:"Unit 14 — door ajar", npcTrigger:"gerald" },
        { id:"h_matchbook", x:1160, y:600, label:"Something by his shoe", hidden:true,
          pickup:"matchbook", toastText:"Taken: matchbook — THE COPPER SPOON." },
        { id:"h_boxes", x:1460, y:520, label:"Boxes of ledgers", hidden:true,
          examine: "Thirty-one boxes, tabbed and cross-tabbed. One sheet comes loose in my hand — and a small card tucked behind it, marked DO NOT COPY.",
          gives: ["d_ledger","d_key"], toastText:"Evidence added: ledger sheet + shorthand key." },
      ],
      npcs: [
        { id:"gerald", x:1075, name:"GERALD", art:"npc_gerald", hiddenUntil:"h_unit14",
          dialogue:"g_intro", hub:"g_hub",
          itemResponses: { matchbook: "g_match",
            badge: { lines: [["GERALD","I know. I KNOW you're police. You have the posture."]] } },
        },
      ],
    },
    diner: {
      title: "THE COPPER SPOON — MORNING RUSH, POP. 3",
      width: 1800, spawnX: 120,
      arrive: "world2_arrive",
      hotspots: [
        { id:"h_pie", x:1030, y:430, label:"Pie case",
          examine: "Cherry, apple, and one labeled only “pie.” All three look outstanding. The pie outlives everybody." },
        { id:"h_booth6", x:1560, y:470, label:"Booth six",
          examineLocked: "Wiped clean. Reserved. I'll want a reason before I go through his booth.",
          needs: "d_told_today", npcTalk: "d_booth", givesItem:"gasreceipt",
          examineAfter: "Nothing else under there but gum and history." },
        { id:"h_spike", x:800, y:420, label:"Ticket spike",
          examineLocked: "This morning's tickets, impaled in order. Denise runs a tight spike.",
          needs: "d_told_today", npcTalk: "d_spike", givesItem:"ticket",
          examineAfter: "The spike keeps the rest of the morning. None of it is his." },
        { id:"h_jukebox", x:340, y:480, label:"Jukebox",
          examine: "Out of order since, judging by the playlist, the late nineties. Probably a mercy." },
      ],
      npcs: [
        { id:"denise", x:520, name:"DENISE", art:"npc_denise",
          dialogue:"d_intro", hub:"d_hub",
          itemResponses: {
            matchbook: { lines: [["DENISE","That's ours. We used to do matches. Then folks kept... lighting things."]] },
            badge: { lines: [["DENISE","Hon, I clocked you at the door. Coffee?"]] },
          },
        },
      ],
    },
    motel: {
      title: "PRESIDIO MOTOR LODGE — ROOM 6",
      width: 1700, spawnX: 110,
      arrive: "world3_arrive",
      hotspots: [
        { id:"h_bed", x:640, y:480, label:"Stripped bed",
          examine: "Stripped to the mattress. The linens are gone. Not in the trash — gone." },
        { id:"h_bathroom", x:1520, y:440, label:"Bathroom",
          examine: "Bleach. Enough that the mirror fogs with it. The drain cover is brand new." },
        { id:"h_window", x:270, y:420, label:"Window",
          examine: "A view of the lot, the sign, and four miles of Route 9 going north into the rain." },
        { id:"h_nightstand", x:1180, y:490, label:"Nightstand — a note", hidden:true,
          isNote: true },
      ],
      npcs: [
        { id:"whitlocks", x:900, name:"ROY & DALE", art:"npc_whitlocks", departFlag:"w3_gone",
          dialogue:"r_intro", hub:"r_hub",
          itemResponses: {
            badge: { lines: [["ROY","We know, ma'am."],["DALE","We cleaned for the last one of you."]] },
            matchbook: { lines: [["ROY","We don't smoke."],["DALE","Roy quit. I supervise."]] },
          },
        },
      ],
    },
  },

  /* ---------------- EPILOGUE TEXT ---------------- */
  epilogue: {
    ringCard: { k:"INCOMING — LAKE CITY P.D.", n:"“We've got paper. A lot of paper. And a phrase you're going to want to hear in person.”", s:"EPISODE 2 — THE TRANSFER" },
    endTitle: "THE PEYTON FILES",
    endLines: "Peyton Voss remains at large.\nThe case remains open.\n\nEpisode 2: THE TRANSFER — Lake City.",
  },
};
