/* The Peyton Files — offline cache.
   Network-first so updates always arrive; cache is the offline fallback. */
const CACHE = "peyton-files-v3";
const ASSETS = [
  ".", "index.html", "css/style.css",
  "js/data.js", "js/data2.js", "js/data3.js",
  "js/art.js", "js/audio.js", "js/cinema.js", "js/board.js",
  "js/file.js", "js/world.js", "js/main.js",
  "art/bg_storage.webp", "art/bg_diner.webp", "art/bg_motel.webp",
  "art/bg_annex.webp", "art/bg_terminal.webp", "art/bg_gas.webp", "art/bg_lakehouse.webp",
  "art/cut_lakecity.webp", "art/cut_road.webp", "art/cut_lakehouse.webp",
  "art/prop_unit14.webp", "art/prop_odom.webp", "art/title.webp",
  "art/pt_kessler.webp", "art/pt_gerald.webp", "art/pt_denise.webp", "art/pt_whitlocks.webp",
  "art/pt_reyes.webp", "art/pt_wes.webp", "art/pt_merle.webp", "art/pt_abernathy.webp",
  "manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    fetch(e.request).then((res) => {
      if (res.ok && new URL(e.request.url).origin === location.origin) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(e.request, copy));
      }
      return res;
    }).catch(() =>
      caches.match(e.request, { ignoreSearch: true }).then((hit) => hit || caches.match("index.html"))
    )
  );
});
