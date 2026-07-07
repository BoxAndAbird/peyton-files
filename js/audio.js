/* THE PEYTON FILES — audio.
   One droning minimal cue under everything. It never shifts into comedic register.
   All sounds synthesized with WebAudio (no assets). */
"use strict";

const PF_AUDIO = (() => {
  const lsGet = (k) => { try { return localStorage.getItem(k); } catch (e) { return null; } };
  const lsSet = (k, v) => { try { localStorage.setItem(k, v); } catch (e) {} };
  let ctx = null, master = null, droneNodes = null;
  let muted = lsGet("pf.muted") === "1";

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

  /* --- the drone: two detuned low saws through a dark lowpass, breathing slowly --- */
  function startDrone() {
    if (!ensure() || droneNodes) return;
    resume();
    const g = ctx.createGain(); g.gain.value = 0;
    const lp = ctx.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 220; lp.Q.value = 0.6;
    const o1 = ctx.createOscillator(); o1.type = "sawtooth"; o1.frequency.value = 55;
    const o2 = ctx.createOscillator(); o2.type = "sawtooth"; o2.frequency.value = 55.6;
    const o3 = ctx.createOscillator(); o3.type = "sine"; o3.frequency.value = 110.3;
    const g3 = ctx.createGain(); g3.gain.value = 0.12;
    const lfo = ctx.createOscillator(); lfo.frequency.value = 0.05;
    const lfoG = ctx.createGain(); lfoG.gain.value = 60;
    lfo.connect(lfoG); lfoG.connect(lp.frequency);
    o1.connect(lp); o2.connect(lp); o3.connect(g3); g3.connect(lp);
    lp.connect(g); g.connect(master);
    o1.start(); o2.start(); o3.start(); lfo.start();
    g.gain.linearRampToValueAtTime(0.055, ctx.currentTime + 4);
    droneNodes = { g, stop() { [o1,o2,o3,lfo].forEach(o=>{try{o.stop(ctx.currentTime+2.2);}catch(e){}});
      g.gain.linearRampToValueAtTime(0, ctx.currentTime + 2); } };
  }
  function stopDrone() { if (droneNodes) { droneNodes.stop(); droneNodes = null; } }

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
  };

  function setMuted(m) {
    muted = m;
    lsSet("pf.muted", m ? "1" : "0");
    if (master) master.gain.value = m ? 0 : 1;
  }

  return { startDrone, stopDrone, sfx, setMuted, get muted() { return muted; }, ensure, resume };
})();
