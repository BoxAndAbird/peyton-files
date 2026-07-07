/* Generates icon-192.png and icon-512.png — a manila case folder on a dark field
   with a red stamp band. Raw PNG encoding, no dependencies. */
const fs = require("fs");
const zlib = require("zlib");
const path = require("path");

function crc32(buf) {
  let c, table = [];
  for (let n = 0; n < 256; n++) {
    c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}
function png(size, pixels) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6; // 8-bit RGBA
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0;
    pixels.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
  }
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

function draw(size) {
  const px = Buffer.alloc(size * size * 4);
  const set = (x, y, r, g, b) => {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    const i = (y * size + x) * 4;
    px[i] = r; px[i + 1] = g; px[i + 2] = b; px[i + 3] = 255;
  };
  const rect = (x0, y0, x1, y1, r, g, b) => {
    x0 = Math.round(x0); y0 = Math.round(y0); x1 = Math.round(x1); y1 = Math.round(y1);
    for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) set(x, y, r, g, b);
  };
  const u = size / 100; // unit
  rect(0, 0, size, size, 0x14, 0x16, 0x1b);                       // night field
  rect(14*u, 30*u, 86*u, 78*u, 0xa9, 0x88, 0x4e);                  // folder back
  rect(14*u, 26*u, 44*u, 34*u, 0xb3, 0x92, 0x5c);                  // tab
  rect(12*u, 34*u, 88*u, 82*u, 0xc9, 0xa8, 0x6a);                  // folder front
  rect(20*u, 44*u, 62*u, 49*u, 0x8a, 0x6c, 0x38);                  // doc line 1
  rect(20*u, 55*u, 50*u, 60*u, 0x8a, 0x6c, 0x38);                  // doc line 2
  rect(18*u, 66*u, 82*u, 76*u, 0xa3, 0x23, 0x1f);                  // red stamp band
  rect(20*u, 68*u, 80*u, 74*u, 0xc9, 0xa8, 0x6a);                  // band inset
  rect(24*u, 69.5*u, 76*u, 72.5*u, 0xa3, 0x23, 0x1f);              // band text bar
  return px;
}

for (const size of [192, 512]) {
  const out = path.join(__dirname, "..", "icons", `icon-${size}.png`);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, png(size, draw(size)));
  console.log("wrote", out);
}
