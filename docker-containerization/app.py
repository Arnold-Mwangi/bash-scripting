import random
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Our "Serverless" Database of Wisdom
JOKES = [
    "I'm afraid for the calendar. Its days are numbered.",
    "My wife said I should do lunges to stay in shape. That would be a big step forward.",
    "Why do Protestants always carry a map? Because they don't want to get lost in the Reformation.",
    "I used to play piano by ear, but now I use my hands.",
    "Docker containers are like teenagers: they don't listen, but they're very portable.",
]


def _payload_dict():
    joke = random.choice(JOKES)
    return {
        "status": "Success",
        "function_name": "serveless_function",
        "memory_usage": f"{random.randint(1, 100)} MB",
        "execution_time": f"{random.randint(1, 100)} ms",
        "payload": joke,
    }


INDEX_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Serverless jokes</title>
  <style>
    :root {
      --bg: #0f1419;
      --card: #1a2332;
      --text: #e7ecf3;
      --muted: #8b9cb3;
      --accent: #3d8bfd;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Segoe UI", system-ui, sans-serif;
      background: radial-gradient(ellipse 120% 80% at 50% -20%, #1e3a5f 0%, var(--bg) 55%);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1.5rem;
    }
    .wrap {
      width: min(36rem, 100%);
      background: var(--card);
      border-radius: 1rem;
      padding: 1.75rem;
      box-shadow: 0 20px 50px rgba(0,0,0,.45);
      border: 1px solid rgba(255,255,255,.06);
    }
    h1 {
      font-size: 1.15rem;
      font-weight: 600;
      margin: 0 0 0.25rem;
      letter-spacing: -0.02em;
    }
    .sub {
      font-size: 0.8rem;
      color: var(--muted);
      margin-bottom: 1.25rem;
    }
    .joke {
      font-size: 1.05rem;
      line-height: 1.55;
      min-height: 4.5rem;
      padding: 1rem 1.1rem;
      background: rgba(0,0,0,.25);
      border-radius: 0.65rem;
      border-left: 3px solid var(--accent);
    }
    .meta {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.5rem 1rem;
      margin-top: 1.25rem;
      font-size: 0.78rem;
      color: var(--muted);
    }
    .meta span { color: var(--text); font-variant-numeric: tabular-nums; }
    .tick {
      margin-top: 1rem;
      font-size: 0.72rem;
      color: var(--muted);
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Serverless function</h1>
    <p class="sub">New joke every 5 seconds</p>
    <p class="joke" id="joke">Loading…</p>
    <div class="meta">
      <div>Status <span id="status">—</span></div>
      <div>Function <span id="fn">—</span></div>
      <div>Memory <span id="mem">—</span></div>
      <div>Exec time <span id="exec">—</span></div>
    </div>
    <p class="tick" id="tick">Next joke in 5s</p>
  </div>
  <script>
    const jokeEl = document.getElementById("joke");
    const statusEl = document.getElementById("status");
    const fnEl = document.getElementById("fn");
    const memEl = document.getElementById("mem");
    const execEl = document.getElementById("exec");
    const tickEl = document.getElementById("tick");

    function apply(data) {
      jokeEl.textContent = data.payload;
      statusEl.textContent = data.status;
      fnEl.textContent = data.function_name;
      memEl.textContent = data.memory_usage;
      execEl.textContent = data.execution_time;
    }

    async function pull() {
      try {
        const r = await fetch("/api/joke");
        const data = await r.json();
        apply(data);
      } catch (e) {
        jokeEl.textContent = "Could not load joke.";
      }
    }

    let left = 5;
    function updateTick() {
      tickEl.textContent = "Next joke in " + left + "s";
    }
    function tick() {
      left -= 1;
      if (left <= 0) {
        pull();
        left = 5;
      }
      updateTick();
    }

    pull();
    updateTick();
    setInterval(tick, 1000);
  </script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(INDEX_HTML)


@app.route("/api/joke")
def api_joke():
    return jsonify(_payload_dict())

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)