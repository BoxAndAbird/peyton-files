/* THE PEYTON FILES — Episode 3: "The Keeper"
   Route 9 north. The lake. The house that keeps its own books.
   Merged into PF_DATA at load. This is the eerie one — the comedy thins out
   the closer you get to the water, and Abernathy is never quite joking. */
"use strict";

(() => {
  const D = PF_DATA;

  /* ---------------- DOCUMENTS ---------------- */
  D.docs.push(
    {
      id: "d_vol1", icon: "file", title: "Ledger Vol. 1 — 1931",
      sub: "The package. The first hand.",
      chapter: "file6",
      body: `
<h3>Ledger — Volume One (1931)</h3>
<div class="meta">DELIVERED: MILLHAVEN P.D. FRONT DESK, NO SENDER<br>BINDING: LEATHER. SMELLS OF LAMP OIL. PAGE 118 MISSING — I HAVE IT.</div>
<p>Account 0001. <b>WHITMORE, L.</b> Opened 1931. The first entries are house-keeping — literally. Oil, wicks, ledger paper, wages for a girl to dust. Then the accounts multiply. Debts bought. Favors entered. Whole families carried at interest.</p>
<p>Every page is balanced to the penny. Nothing is ever forgiven. Nothing is ever late. In ninety-five years of entries there is not one correction.</p>
<p class="hand pencil">Lenora Whitmore. The account that opened all the others. The keepers change — the hand never does. Almost never. — M.K.</p>`
    },
    {
      id: "d_photo31", icon: "photo", title: "Torn Photograph, 1931",
      sub: "Inside the front cover. In pieces. Again.",
      chapter: "file6", puzzle: "photo3",
      body: `
<h3>Evidence — Photograph (1931)</h3>
<div class="meta">SOURCE: TUCKED INSIDE VOL. 1'S FRONT COVER, TAPED ENVELOPE<br>CONDITION: TORN INTO NINE PIECES. DELIBERATELY. KEPT ANYWAY.</div>
<p>Old sepia stock, torn by hand. Somebody has been tearing up photographs and failing to throw them away for ninety-five years.</p>
<p class="hand pencil">On the envelope, in Odom's hand: "the house. LOOK AT THE WINDOW." — same habit, three years on. He's still leaving me trail markers. — M.K.</p>`
    },
    {
      id: "d_deed", icon: "memo", title: "County Deed — Whitmore Lake",
      sub: "The house. The margins are annotated.",
      chapter: "file6", puzzle: "cipher3",
      body: `
<h3>County Deed — Parcel 9-NORTH (Whitmore Lake)</h3>
<div class="meta">COUNTY ARCHIVE COPY. LAST TRANSFER OF TITLE: 1931.<br>OWNER OF RECORD: "THE HOUSE" (SIC — THE CLERK'S HAND SHOOK)</div>
<p>Title conveyed 1931 from WHITMORE, LENORA to — the line is left blank, notarized blank, stamped blank. The county has been taxing a blank line for ninety-five years. The blank line has never once paid late.</p>
<p>Margin, small precise hand: <b>8 — 0 / 9</b></p>
<p class="hand pencil">He wrote in a county archive copy. He wanted it read. Margins are how this man raises his voice. — M.K.</p>`
    },
    {
      id: "d_pumplog", icon: "receipt", title: "Pump Log — Route 9 Fuel",
      sub: "Two full tanks in three days.",
      chapter: "file7",
      body: `
<h3>Route 9 Fuel — Pump Log</h3>
<div class="meta">PROVIDED BY MERLE (ATTENDANT), UNDER MILD PROTEST</div>
<p class="receipt">WED &nbsp;7:41 AM — PUMP 2 — PREMIUM — 18.2 GAL — CASH<br>
THU &nbsp;6:12 PM — PUMP 2 — PREMIUM — 18.2 GAL — CASH<br>
&nbsp;<br>
TIP JAR: $3.64 &nbsp;(EXACT)</p>
<p class="hand pencil">Eighteen point two, twice, to the decimal. A man who refuels like bookkeeping. He isn't driving far — he's driving OFTEN. Circles, not escape. — M.K.</p>`
    },
    {
      id: "d_fisherman", icon: "memo", title: "Statement — R. Coble",
      sub: "Fisherman. The lamp at 11:52.",
      chapter: "file7",
      body: `
<h3>Witness Statement — Coble, Raymond</h3>
<div class="meta">TAKEN AT: ROUTE 9 FUEL, OVER COFFEE FROM A THERMOS OLDER THAN ME</div>
<p>Witness fishes Whitmore Lake at night. States the house has been dark "since before television." States that Thursday night the parlor lamp was lit.</p>
<p>Asked how he fixed the time, witness stated: <b>"That's when the fish quit. They always quit at eleven fifty-two. You get used to it."</b></p>
<p>Witness then reeled in, packed up, and stated he fishes the OTHER end of the lake now.</p>
<p class="hand pencil">Even the fish keep the hour. — M.K.</p>`
    },
    {
      id: "d_hardware", icon: "receipt", title: "Receipt — Millhaven Hardware",
      sub: "Thursday, 9:30 PM. Supplies.",
      chapter: "file7",
      body: `
<h3>Receipt — Millhaven Hardware Co.</h3>
<div class="meta">REGISTER COPY. CLERK REMEMBERS "A TALL MAN. POLITE. WRONG."</div>
<p class="receipt">THU &nbsp;9:30 PM<br>
LAMP OIL ............ 1 GAL<br>
LEDGER PAPER ...... 2 REAMS<br>
TYPEWRITER RIBBON, BLK ... 1<br>
CASH — EXACT</p>
<p class="hand pencil">Not rope. Not a shovel. Housekeeping. He's not going to the lake to end something — he's RESTOCKING it. Keepers keep. — M.K.</p>`
    },
    {
      id: "d_call", icon: "memo", title: "Payphone Transcript",
      sub: "House line 0114. She answered first.",
      chapter: "file7",
      body: `
<h3>Transcript — Payphone, Route 9 Fuel</h3>
<div class="meta">DIALED: HOUSE LINE 0114 (PER MAP MARGIN)<br>DURATION: 11 SECONDS. I DIDN'T SPEAK.</div>
<p>Line connects on the first ring. A woman's voice, dry as a ledger page, before I've said a word:</p>
<p class="hand" style="color:#2a251d;font-size:17px">"You're early, Detective. The house keeps its hours. Come while the lamp is lit."</p>
<p>Then the line remembered it was dead.</p>
<p class="hand pencil">The phone company says that number was disconnected in 1958. The phone company is wrong about the lake. — M.K.</p>`
    },
    {
      id: "d_wall", icon: "note", title: "The Parlor Ledger",
      sub: "Every keeper since 1931. And one pending.",
      chapter: "finale",
      body: `
<h3>Evidence — The Parlor Ledger (Current Volume)</h3>
<div class="meta">WHITMORE LAKE HOUSE, THE READING TABLE. OPEN TO TODAY.<br>I DID NOT TAKE IT. IT DOES NOT LEAVE. WE BOTH KNEW THAT.</div>
<p class="receipt">KEEPERS — ACCT 0001<br>
────────────────────<br>
WHITMORE, L. ....... 1931 — <s>1953</s><br>
<s>GARLAND, E.</s> ......... 1953 — <s>1977</s><br>
<s>MERCER, H.</s> .......... 1977 — <s>2001</s><br>
<s>VOSS, P.</s> ................ 2001 — <b>(the strike is wet)</b><br>
&nbsp;<br>
KESSLER, M. ........ &nbsp;—</p>
<p class="hand pencil">My name. No dates. Iron gall ink, still drying. Nobody in that house owns a pen I saw. — M.K.</p>`
    },
  );

  /* ---------------- LOCATION CARDS ---------------- */
  D.locations.gas       = { key:"LOCATION UNLOCKED", name:"ROUTE 9 FUEL — NORTH", sub:"He filled twice in three days. Ask why.", scene:"gas" };
  D.locations.lakehouse = { key:"LOCATION UNLOCKED", name:"WHITMORE LAKE HOUSE", sub:"The lamp is lit. Go before it isn't.", scene:"lakehouse" };

  /* ---------------- PUZZLES ---------------- */
  Object.assign(D.puzzles, {
    photo3: {
      title: "REASSEMBLE THE 1931 PHOTOGRAPH",
      hint: "Tap two pieces to swap them. Odom said: look at the window.",
      image: "photo1931",
      solvedNarration: "The lake house, ninety-five years younger and no friendlier. Every window dark except one, upstairs, lit warm for the camera. The lamp was already burning in 1931. Somebody has kept it in oil ever since.",
      toast: "Photo reassembled — THE LAMP WAS ALREADY LIT.",
    },
    cipher3: {
      title: "READ THE DEED MARGIN",
      hint: "The margin reads 8 — 0 / 9. Same key, Vol. 2. Read it out.",
      code: ["8","0","9"],
      slotLabels: ["8","0","9"],
      answers: ["KEEPER","L.","CLOSE"],
      options: [
        ["TRANSFER","KEEPER","STORAGE","SPOON"],
        ["WEDNESDAY","RTE 9","L.","BANK"],
        ["TABLE / ROOM","CLOSE","44","31"],
      ],
      note: "Read it any order you like. It comes out the same.",
      solvedNarration: "Keeper. L. Close. He isn't running from the ledger. He's finishing it — closing the account that opened all the others. The first account. Hers.",
      toast: "Margin read — HE'S CLOSING L.'S ACCOUNT.",
    },
    timeline3: {
      title: "RECONSTRUCT HIS THREE DAYS",
      hint: "Tap the records in order, earliest first. You've had one of these since Millhaven.",
      items: [
        { id:"v1", tag:"GAS RECEIPT", text:"WED 7:41 AM — 18.2 gallons, pump 2. The Millhaven tank", order:0 },
        { id:"v2", tag:"PUMP LOG", text:"THU 6:12 PM — 18.2 gallons, pump 2. Again. Exact", order:1 },
        { id:"v3", tag:"HARDWARE", text:"THU 9:30 PM — lamp oil, ledger paper, typewriter ribbon", order:2 },
        { id:"v4", tag:"WITNESS", text:"THU 11:52 PM — the parlor lamp lights. The fish quit", order:3 },
        { id:"v5", tag:"ATTENDANT", text:"FRI 4:05 AM — northbound past the pumps, headlights off", order:4 },
      ],
      solvedNarration: "Fuel. Fuel again. Oil, paper, ribbon. The lamp lights at eleven fifty-two and he drives past Merle in the dark with his headlights off, like a man who doesn't need to see the road anymore. Everything he bought was for the house.",
      toast: "Three days reconstructed.",
    },
    string2: {
      title: "RUN THE LAST STRING",
      hint: "On the board: connect the locker to the 1931 ledger, and the ledger to Route 9 Fuel. Tap one pin, then the other.",
      connections: [["p_locker","p_vol1"],["p_vol1","p_gas"]],
      solvedNarration: "The page from the locker. The volume on my desk. The map from the pump counter. Every string I ran ended at the same dark house over the same black water. The board had room for exactly one more pin. It had been saving the space.",
      toast: "Route deduced — WHITMORE LAKE HOUSE.",
    },
    phone: {
      title: "THE HOUSE LINE",
      hint: "The map margin says: house line — 0114. Dial it.",
      number: ["0","1","1","4"],
      solvedNarration: null, /* handled by the transcript beat */
      toast: "Connected — 11 seconds.",
    },
  });

  /* ---------------- NARRATION ---------------- */
  Object.assign(D.narration, {
    file6_intro: "The package sat on my desk like it had signed in. Volume One. 1931. The first account, the first keeper — and page one-eighteen missing, because page one-eighteen was already in my coat pocket. He wasn't hiding the story from me. He was assigning it in installments.",
    world6_arrive: "Route 9 Fuel, the last light before the lake. The fog took the road behind me as a favor, so I'd stop checking the mirror.",
    world6_done: "The phone knew my rank before I spoke. The map was marked before I asked. I was done being three days behind — which worried me more than the three days ever had. Nobody's early to a place like that unless they're on the schedule.",
    world7_arrive: "The parlor smelled of lamp oil and arithmetic. Every account in the county, bound in leather, and one reading chair without any dust on it.",
    world7_wall: "Keepers, 1931 to now. Every name struck through in its turn — and Voss's strike still wet. Under it, in ink that hadn't finished drying, in nobody's handwriting at all: KESSLER, M. No dates. The ledger wasn't threatening me. It was onboarding me.",
    finale_check: "I drove home with the windows down and stopped at the Spoon because it was open and human and loud enough. Denise brought coffee I didn't order. I left sixty cents on three dollars, and I was to the car before the arithmetic reached me.",
  });

  /* ---------------- DIALOGUE ---------------- */
  Object.assign(D.dialogue, {
    /* ————— MERLE — route 9 fuel ————— */
    m_intro: {
      lines: [
        ["MERLE","Pump two's slow. Pump one's honest."],
        ["KESSLER","I'm not buying gas."],
        ["MERLE","Everybody's buying something, hon. That's the whole economy."],
      ],
      sets: "m_talked",
      choices: "m_hub",
    },
    m_hub: {
      speaker: "MERLE",
      options: [
        { label: "“Tall man. Premium, cash.”", node: "m_voss" },
        { label: "“What's north of here?”", node: "m_north" },
        { label: "“How's the hot dog?”", node: "m_dog", flavor: true },
        { label: "[Step back]", node: null },
      ],
    },
    m_voss: {
      lines: [
        ["MERLE","Twice this week. Don't talk. Pays exact, tips exact. Twenty percent — on GASOLINE. Who tips on gasoline?"],
        ["KESSLER","To the penny?"],
        ["MERLE","To the penny. I keep it in a separate jar. Feels wrong to mix it with human money."],
      ],
      sets: "m_voss",
      choices: "m_hub",
    },
    m_north: {
      lines: [
        ["MERLE","The lake. The house. We don't deliver there. NOTHING delivers there — paperboy quit in fifty-five and the paper agreed with him."],
        ["MERLE","House gets its oil though. Always has. Ask me who buys it."],
        ["KESSLER","Who buys it?"],
        ["MERLE","Whoever's tall that decade, hon."],
      ],
      sets: "m_north",
      choices: "m_hub",
    },
    m_dog: {
      lines: [
        ["MERLE","That dog's been rolling since spring. Manager says it stays."],
        ["MERLE","I've named it. You don't eat things you've named."],
      ],
      choices: "m_hub",
    },
    m_map: {
      lines: [
        ["KESSLER","There's a county map on your counter with grease pencil on it."],
        ["MERLE","Take it. Fella marked it up himself last night — borrowed my pencil, real polite."],
        ["MERLE","Left the corner of it pointed at me the whole time. Maps don't point, hon. That one points."],
      ],
      onEnd: "give_map",
    },

    /* ————— MRS. ABERNATHY — lake house ————— */
    a_intro: {
      lines: [
        ["ABERNATHY","Wipe your feet, Detective. The rug is older than your department."],
        ["KESSLER","You were expecting me."],
        ["ABERNATHY","We entered you Tuesday, dear. The house doesn't do surprises. They unbalance the week."],
      ],
      sets: "a_talked",
      choices: "a_hub",
    },
    a_hub: {
      speaker: "ABERNATHY",
      options: [
        { label: "“Where is Voss?”", node: "a_voss" },
        { label: "“Who is L.?”", node: "a_L" },
        { label: "“And what are you?”", node: "a_self", flavor: true },
        { label: "[Step back]", node: null },
      ],
    },
    a_voss: {
      lines: [
        ["ABERNATHY","Mr. Voss is balancing. It takes as long as it takes."],
        ["ABERNATHY","The last keeper balanced for eleven days and came out weighing exactly the same, which everyone agreed was a mercy."],
        ["KESSLER","Came out of where?"],
        ["ABERNATHY","The house, dear. Do keep up."],
      ],
      choices: "a_hub",
    },
    a_L: {
      lines: [
        ["ABERNATHY","Miss Whitmore opened this account in 1931. She has been senior ever since."],
        ["ABERNATHY","You'll want the parlor ledger, on the reading table. It's open to today."],
        ["ABERNATHY","It's been open to today since Tuesday."],
      ],
      sets: "a_ledger",
      choices: "a_hub",
    },
    a_self: {
      lines: [
        ["ABERNATHY","Oh, I'm not the keeper, dear. I'm the duster."],
        ["ABERNATHY","The house keeps itself. I only see that nothing settles on it. Settling is how houses die."],
        ["ABERNATHY","...You needn't write that down. It's already written down."],
      ],
      choices: "a_hub",
    },
    a_end: {
      lines: [
        ["ABERNATHY","Mind the sill on your way out, Detective."],
        ["ABERNATHY","We'll see you Tuesday. We always do."],
      ],
    },
  });

  /* ---------------- WORLD SCENES ---------------- */
  D.scenes.gas = {
    title: "ROUTE 9 FUEL — 11:40 P.M.",
    width: 1707, spawnX: 140, ground: 655,
    art: "bg_gas",
    haunt: "gas",
    hotspots: [
      { id:"h_dog", x:790, y:380, label:"The hot dog",
        examine: "One hot dog in the kiosk window, rolling since spring, glowing faintly under the heat lamp. There's a name tag taped to the roller. It says GARY." },
      { id:"h_map", x:905, y:435, label:"County map — grease pencil", showFlag:"m_north", npcTalk:"m_map", needs:"m_north", givesItem:"greasemap",
        examineLocked: "A folded county map on the counter, marked in grease pencil. It's Merle's counter — ask first.",
        examineAfter: "The map's gone north with me. The counter keeps the outline of it in dust." },
      { id:"h_pumps", x:1180, y:430, label:"Pump 2",
        examine: "Pump two. The counter wheels rest at 18.2 like they're proud of it. Merle's taped a note to the glass: SLOW. Underneath, in other ink: IT'S NOT THE PUMP." },
      { id:"h_phone", x:1640, y:420, label:"Payphone", worldPuzzle:"phone", needsItem:"greasemap",
        examineLocked: "A glass booth, lit inside like a specimen jar. The phone book is gone. The cord isn't. I don't have a number to dial yet." },
    ],
    npcs: [
      { id:"merle", x:990, name:"MERLE", art:"npc_merle",
        dialogue:"m_intro", hub:"m_hub",
        itemResponses: {
          badge: { lines: [["MERLE","Ma'am, out here that's mostly a flashlight."]] },
          greasemap: { lines: [["MERLE","Yep. Still points."]] },
          matchbook: { lines: [["MERLE","The Spoon! Best pie in three counties."],["MERLE","...You didn't hear it beat out anybody local. Gary's not pie. GARY'S NOT PIE."]] },
        },
      },
    ],
  };

  D.scenes.lakehouse = {
    title: "WHITMORE LAKE HOUSE — THE PARLOR",
    width: 1707, spawnX: 130, ground: 650,
    art: "bg_lakehouse", dark: false,
    haunt: "lakehouse",
    hotspots: [
      { id:"h_window", x:170, y:380, label:"The tall windows",
        examine: "The lake, black and still, holding the moon. It doesn't hold the house. I checked twice." },
      { id:"h_portrait", x:668, y:300, label:"The portrait",
        examine: "A woman, 1931, painted mid-decision. The brass plaque below has been polished blank. Regularly. Recently." },
      { id:"h_sheets", x:1050, y:520, label:"Covered furniture",
        examine: "Shapes under dust sheets. I counted legs out of habit. One of the shapes was wrong, so I stopped counting." },
      { id:"h_wall", x:1285, y:480, label:"The parlor ledger", showFlag:"a_ledger", isFinale:true,
        examineLocked: "" },
    ],
    npcs: [
      { id:"abernathy", x:1450, name:"ABERNATHY", art:"npc_abernathy",
        dialogue:"a_intro", hub:"a_hub",
        itemResponses: {
          badge: { lines: [["ABERNATHY","We know, dear. We wrote you down Tuesday. Handsome photograph — it doesn't flatter you, it's simply accurate."]] },
          matchbook: { lines: [["ABERNATHY","No fire in this house since 1931."],["ABERNATHY","The house asked nicely. The fire agreed."]] },
          greasemap: { lines: [["ABERNATHY","He does lovely mapwork. Always has. You should see his 1977."]] },
          indexcard: { lines: [["ABERNATHY","Mr. Odom. A careful hand. He delivers Thursdays and takes his tea standing."],["KESSLER","He's been dead three years."],["ABERNATHY","He's been PUNCTUAL three years, dear. Words matter in this house."]] },
        },
      },
    ],
  };
})();
