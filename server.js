/* Tiny static server for The Peyton Files (mobile PWA).
   Run: node server.js  → http://localhost:8078  (phone: http://<PC-IP>:8078) */
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const PORT = 8078;
const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".webmanifest": "application/manifest+json",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

http.createServer((req, res) => {
  let p;
  try { p = decodeURIComponent(req.url.split("?")[0]); }
  catch (e) { res.writeHead(400); res.end("bad request"); return; }
  if (p.indexOf("\0") !== -1) { res.writeHead(400); res.end("bad request"); return; }
  if (p === "/") p = "/index.html";
  const file = path.join(ROOT, path.normalize(p).replace(/^([.][.][\\/])+/, ""));
  if (!file.startsWith(ROOT)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end("not found"); return; }
    res.writeHead(200, {
      "Content-Type": MIME[path.extname(file).toLowerCase()] || "application/octet-stream",
      "Cache-Control": "no-cache",
    });
    res.end(data);
  });
}).listen(PORT, () => console.log("The Peyton Files → http://localhost:" + PORT));
