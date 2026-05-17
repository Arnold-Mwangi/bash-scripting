const express = require("express");
const fs = require("fs/promises");
const path = require("path");
const os = require("os");

const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = process.env.DATA_DIR || "/data";
const DATA_FILE = path.join(DATA_DIR, "app-data.json");
const APP_MESSAGE = process.env.APP_MESSAGE || "Hello from Kubernetes";
const APP_ENV = process.env.APP_ENV || "development";
const API_SECRET = process.env.API_SECRET || "";

const app = express();
app.use(express.json());

async function ensureDataDir() {
  await fs.mkdir(DATA_DIR, { recursive: true });
}

async function readStoredData() {
  try {
    const raw = await fs.readFile(DATA_FILE, "utf8");
    return JSON.parse(raw);
  } catch (err) {
    if (err.code === "ENOENT") {
      return { visits: 0, notes: [], updatedAt: null };
    }
    throw err;
  }
}

async function writeStoredData(data) {
  await ensureDataDir();
  data.updatedAt = new Date().toISOString();
  await fs.writeFile(DATA_FILE, JSON.stringify(data, null, 2), "utf8");
  return data;
}

app.get("/health", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/ready", async (_req, res) => {
  try {
    await ensureDataDir();
    res.status(200).json({ status: "ready" });
  } catch (err) {
    res.status(503).json({ status: "not ready", error: err.message });
  }
});

app.get("/api/info", (_req, res) => {
  res.json({
    message: APP_MESSAGE,
    environment: APP_ENV,
    hostname: os.hostname(),
    secretConfigured: Boolean(API_SECRET),
    dataDir: DATA_DIR,
  });
});

app.get("/api/data", async (_req, res) => {
  try {
    const data = await readStoredData();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/data", async (req, res) => {
  try {
    const data = await readStoredData();
    data.visits += 1;
    if (req.body?.note) {
      data.notes.push({
        text: String(req.body.note),
        at: new Date().toISOString(),
        pod: os.hostname(),
      });
    }
    await writeStoredData(data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/", (_req, res) => {
  res.type("html").send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>K8s Demo App</title>
  <style>
    :root { --bg: #0f1419; --card: #1a2332; --text: #e7ecf3; --muted: #8b9cb3; --accent: #3d8bfd; }
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; font-family: system-ui, sans-serif;
      background: radial-gradient(ellipse 120% 80% at 50% -20%, #1e3a5f 0%, var(--bg) 55%);
      color: var(--text); display: flex; align-items: center; justify-content: center; padding: 1.5rem;
    }
    .wrap {
      width: min(40rem, 100%); background: var(--card); border-radius: 1rem;
      padding: 1.75rem; box-shadow: 0 20px 50px rgba(0,0,0,.45);
      border: 1px solid rgba(255,255,255,.06);
    }
    h1 { margin: 0 0 0.25rem; font-size: 1.2rem; }
    .sub { color: var(--muted); font-size: 0.85rem; margin-bottom: 1rem; }
    pre {
      background: rgba(0,0,0,.3); padding: 1rem; border-radius: 0.5rem;
      overflow-x: auto; font-size: 0.8rem; border-left: 3px solid var(--accent);
    }
    button {
      margin-top: 1rem; padding: 0.6rem 1.2rem; border: none; border-radius: 0.5rem;
      background: var(--accent); color: #fff; font-weight: 600; cursor: pointer;
    }
    button:hover { filter: brightness(1.1); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Kubernetes Demo App</h1>
    <p class="sub">Deployment · Service · Ingress · PV · ConfigMap · Secret · HPA</p>
    <pre id="out">Loading…</pre>
    <button type="button" id="visit">Record visit (writes to PV)</button>
  </div>
  <script>
    const out = document.getElementById("out");
    async function refresh() {
      const [info, data] = await Promise.all([
        fetch("/api/info").then(r => r.json()),
        fetch("/api/data").then(r => r.json()),
      ]);
      out.textContent = JSON.stringify({ info, data }, null, 2);
    }
    document.getElementById("visit").onclick = async () => {
      await fetch("/api/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ note: "visit from browser" }),
      });
      refresh();
    };
    refresh();
  </script>
</body>
</html>`);
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT} (hostname=${os.hostname()})`);
});
