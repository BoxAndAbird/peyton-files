/* THE PEYTON FILES — audio.
   One droning minimal cue under everything, wind for the world, a heartbeat
   for the lake. It never shifts into comedic register.
   All sounds synthesized with WebAudio (no assets). */
"use strict";

const PF_AUDIO = (() => {
  const lsGet = (k) => { try { return localStorage.getItem(k); } catch (e) { return null; } };
  const lsSet = (k, v) => { try { localStorage.setItem(k, v); } catch (e) {} };
  let ctx = null, master = null, droneNodes = null, windNodes = null;
  let muted = lsGet("pf.muted") === "1";
  let mood = "warm";

  function ensure() {
    if (ctx) return true;
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return false;
      ctx = new AC();
      master = ctx.createGain();
      master.gain.value = muted ? 0 : 1;
      master.connect(ctx.destination);
    } catch (e) { return false; }
    return true;
  }

  function resume() { if (ctx && ctx.state === "suspended") ctx.resume(); }

  /* --- the drone: two detuned low saws through a dark lowpass, breathing slowly.
     A high, very quiet shimmer sits on top; the mood tunes it. --- */
  function startDrone() {
    if (!ensure() || droneNodes) return;
    resume();
    const g = ctx.createGain(); g.gain.value = 0;
    const lp = ctx.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 220; lp.Q.value = 0.6;
    const o1 = ctx.createOscillator(); o1.type = "sawtooth"; o1.frequency.value = 55;
    const o2 = ctx.createOscillator(); o2.type = "sawtooth"; o2.frequency.value = 55.6;
    const o3 = ctx.createOscillator(); o3.type = "sine"; o3.frequency.value = 110.3;
    const g3 = ctx.createGain(); g3.gain.value = 0.12;
    // eerie shimmer: two barely-audible high sines beating against each other
    const s1 = ctx.createOscillator(); s1.type = "sine"; s1.frequency.value = 1244;
    const s2 = ctx.createOscillator(); s2.type = "sine"; s2.frequency.value = 1247.3;
    const sg = ctx.createGain(); sg.gain.value = 0.006;
    const lfo = ctx.createOscillator(); lfo.frequency.value = 0.05;
    const lfoG = ctx.createGain(); lfoG.gain.value = 60;
    lfo.connect(lfoG); lfoG.connect(lp.frequency);
    o1.connect(lp); o2.connect(lp); o3.connect(g3); g3.connect(lp);
    s1.connect(sg); s2.connect(sg); sg.connect(g);
    lp.connect(g); g.connect(master);
    o1.start(); o2.start(); o3.start(); lfo.start(); s1.start(); s2.start();
    g.gain.linearRampToValueAtTime(0.055, ctx.currentTime + 4);
    droneNodes = { g, lp, sg, o2,
      stop() { [o1,o2,o3,lfo,s1,s2].forEach(o=>{try{o.stop(ctx.currentTime+2.2);}catch(e){}});
      g.gain.linearRampToValueAtTime(0, ctx.currentTime + 2); } };
    applyMood();
  }
  function stopDrone() { if (droneNodes) { droneNodes.stop(); droneNodes = null; } }

  /* Mood shifts the drone rather than replacing it: warm (ep1), cold (ep2), lake (ep3). */
  function setMood(m) { mood = m || "warm"; applyMood(); }
  function applyMood() {
    if (!droneNodes || !ctx) return;
    const t = ctx.currentTime;
    const set = (p, v) => p.linearRampToValueAtTime(v, t + 3);
    if (mood === "warm") { set(droneNodes.lp.frequency, 220); set(droneNodes.sg.gain, 0.004); droneNodes.o2.frequency.value = 55.6; }
    if (mood === "cold") { set(droneNodes.lp.frequency, 160); set(droneNodes.sg.gain, 0.008); droneNodes.o2.frequency.value = 55.9; }
    if (mood === "lake") { set(droneNodes.lp.frequency, 120); set(droneNodes.sg.gain, 0.012); droneNodes.o2.frequency.value = 56.3; }
  }

  /* --- wind: filtered noise loop for world scenes (denser at the lake) --- */
  function startWind(heavy) {
    if (!ensure() || windNodes) return;
    resume();
    const n = ctx.sampleRate * 3;
    const buf = ctx.createBuffer(1, n, ctx.sampleRate);
    const d = buf.getChannelData(0);
    let last = 0;
    for (let i = 0; i < n; i++) { const w = Math.random()*2-1; last = (last + 0.02*w)/1.02; d[i] = last*3.2; }
    const src = ctx.createBufferSource(); src.buffer = buf; src.loop = true;
    const f = ctx.createBiquadFilter(); f.type = "bandpass"; f.frequency.value = heavy ? 240 : 380; f.Q.value = 0.4;
    const g = ctx.createGain(); g.gain.value = 0;
    const lfo = ctx.createOscillator(); lfo.frequency.value = 0.07;
    const lfoG = ctx.createGain(); lfoG.gain.value = heavy ? 0.012 : 0.008;
    lfo.connect(lfoG); lfoG.connect(g.gain);
    src.connect(f); f.connect(g); g.connect(master);
    src.start(); lfo.start();
    g.gain.linearRampToValueAtTime(heavy ? 0.028 : 0.018, ctx.currentTime + 3);
    windNodes = { stop() { g.gain.linearRampToValueAtTime(0, ctx.currentTime + 1.2);
      setTimeout(() => { try{src.stop();lfo.stop();}catch(e){} }, 1400); } };
  }
  function stopWind() { if (windNodes) { windNodes.stop(); windNodes = null; } }

  /* --- one-shot helpers --- */
  function noiseBurst(dur, freq, q, vol, type="bandpass") {
    if (!ensure()) return; resume();
    const n = ctx.sampleRate * dur;
    const buf = ctx.createBuffer(1, n, ctx.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < n; i++) d[i] = (Math.random()*2-1) * (1 - i/n);
    const src = ctx.createBufferSource(); src.buffer = buf;
    const f = ctx.createBiquadFilter(); f.type = type; f.frequency.value = freq; f.Q.value = q;
    const g = ctx.createGain(); g.gain.value = vol;
    src.connect(f); f.connect(g); g.connect(master); src.start();
  }
  function thump(freq, dur, vol) {
    if (!ensure()) return; resume();
    const o = ctx.createOscillator(); o.type = "sine";
    o.frequency.setValueAtTime(freq, ctx.currentTime);
    o.frequency.exponentialRampToValueAtTime(Math.max(30, freq*0.4), ctx.currentTime + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + dur);
    o.connect(g); g.connect(master); o.start(); o.stop(ctx.currentTime + dur + 0.05);
  }
  function blip(freq, dur, vol, type="triangle") {
    if (!ensure()) return; resume();
    const o = ctx.createOscillator(); o.type = type; o.frequency.value = freq;
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + dur);
    o.connect(g); g.connect(master); o.start(); o.stop(ctx.currentTime + dur + 0.05);
  }

  const sfx = {
    paper()  { noiseBurst(0.16, 2600, 0.7, 0.20, "highpass"); },
    paperBig(){ noiseBurst(0.30, 1800, 0.6, 0.26, "highpass"); },
    stamp()  { thump(120, 0.22, 0.5); noiseBurst(0.06, 900, 1.2, 0.18); },
    pin()    { blip(1450, 0.07, 0.16, "square"); thump(300, 0.05, 0.12); },
    string() { blip(520, 0.14, 0.10, "sawtooth"); },
    fold()   { noiseBurst(0.42, 1200, 0.5, 0.22, "bandpass"); },
    good()   { blip(392, 0.16, 0.12); setTimeout(()=>blip(523, 0.22, 0.12), 110); },
    bad()    { blip(140, 0.20, 0.16, "square"); },
    pickup() { blip(660, 0.10, 0.12); },
    step()   { noiseBurst(0.05, 500, 1.5, 0.05); },
    ring()   { let i=0; const t=setInterval(()=>{ blip(880,0.28,0.10,"sine"); blip(1108,0.28,0.07,"sine"); if(++i>=4) clearInterval(t); }, 520); },
    ring1()  { blip(880,0.34,0.10,"sine"); blip(1108,0.34,0.07,"sine"); },
    thunder(){ noiseBurst(1.6, 90, 0.4, 0.10, "lowpass"); setTimeout(()=>noiseBurst(1.1, 60, 0.4, 0.07, "lowpass"), 300); },
    rattle() { let i=0; const t=setInterval(()=>{ noiseBurst(0.05, 700, 2.5, 0.12); thump(90, 0.06, 0.10); if(++i>=6) clearInterval(t); }, 90); },
    jukebox(){ blip(392, 0.4, 0.05, "sine"); setTimeout(()=>blip(330, 0.6, 0.045, "sine"), 420); },
    thud()   { thump(58, 0.4, 0.22); },
    flap()   { let i=0; const t=setInterval(()=>{ noiseBurst(0.03, 2200, 2, 0.08); if(++i>=9) clearInterval(t); }, 45); },
    tick()   { blip(1900, 0.03, 0.07, "square"); },
    dialA()  { noiseBurst(0.09, 1600, 1.6, 0.07); },   // rotary pull
    dialB(n) { let i=0; const t=setInterval(()=>{ blip(2100, 0.02, 0.05, "square"); if(++i>=n) clearInterval(t); }, 60); }, // rotary return clicks
    clunk()  { thump(140, 0.14, 0.3); setTimeout(()=>thump(85, 0.2, 0.24), 90); },
    heartbeat(){ let i=0; const t=setInterval(()=>{ thump(48, 0.16, 0.20); setTimeout(()=>thump(44, 0.14, 0.14), 190); if(++i>=4) clearInterval(t); }, 950); },
  };

  function setMuted(m) {
    muted = m;
    lsSet("pf.muted", m ? "1" : "0");
    if (master) master.gain.value = m ? 0 : 1;
  }

  return { startDrone, stopDrone, startWind, stopWind, setMood, sfx, setMuted,
           get muted() { return muted; }, ensure, resume };
})();
