#!/bin/bash
set -e

dnf update -y
dnf install -y python3 python3-pip

pip3 install flask requests psycopg2-binary

mkdir -p /opt/app

cat > /opt/app/app.py <<'PYEOF'
from urllib.parse import urlencode

import psycopg2
import requests
from flask import Flask, request, redirect, session, render_template_string

app = Flask(__name__)
app.secret_key = "${flask_secret_key}"

DB_HOST = "${db_host}"
DB_NAME = "${db_name}"
DB_USER = "${db_user}"
DB_PASSWORD = "${db_password}"
DB_PORT = 5432

APP_BASE_URL = "${app_base_url}"
COGNITO_DOMAIN = "https://${cognito_domain}.auth.${aws_region}.amazoncognito.com"
COGNITO_CLIENT_ID = "${cognito_client_id}"
COGNITO_CLIENT_SECRET = "${cognito_client_secret}"
REDIRECT_URI = f"{APP_BASE_URL}/callback"

AUTH_URL = f"{COGNITO_DOMAIN}/oauth2/authorize"
TOKEN_URL = f"{COGNITO_DOMAIN}/oauth2/token"
USERINFO_URL = f"{COGNITO_DOMAIN}/oauth2/userInfo"
LOGOUT_URL = f"{COGNITO_DOMAIN}/logout"

HTML = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>User Notes</title>
  <style>
    :root {
      --bg: #0b1020;
      --bg-soft: #121933;
      --card: rgba(18, 25, 51, 0.78);
      --card-strong: rgba(20, 28, 56, 0.95);
      --text: #edf2ff;
      --muted: #a9b4d0;
      --border: rgba(255,255,255,0.10);
      --accent: #7c9cff;
      --accent-2: #4f7cff;
      --success: #86efac;
      --shadow: 0 20px 60px rgba(0,0,0,0.35);
      --radius: 20px;
    }

    * { box-sizing: border-box; }

    html, body {
      margin: 0;
      padding: 0;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(124,156,255,0.18), transparent 30%),
        radial-gradient(circle at top right, rgba(79,124,255,0.14), transparent 28%),
        linear-gradient(180deg, #070b16 0%, #0b1020 100%);
      min-height: 100vh;
    }

    .wrap {
      width: min(1100px, calc(100% - 32px));
      margin: 32px auto;
    }

    .hero {
      background: linear-gradient(135deg, rgba(124,156,255,0.18), rgba(255,255,255,0.03));
      border: 1px solid var(--border);
      border-radius: 28px;
      padding: 28px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      margin-bottom: 24px;
    }

    .hero-top {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .brand-badge {
      width: 54px;
      height: 54px;
      border-radius: 16px;
      background: linear-gradient(135deg, var(--accent), var(--accent-2));
      display: grid;
      place-items: center;
      font-size: 24px;
      box-shadow: 0 12px 30px rgba(79,124,255,0.35);
    }

    h1 {
      margin: 0;
      font-size: clamp(28px, 4vw, 42px);
      line-height: 1.05;
      letter-spacing: -0.03em;
    }

    .subtitle {
      margin: 8px 0 0;
      color: var(--muted);
      max-width: 700px;
      line-height: 1.6;
      font-size: 15px;
    }

    .status {
      margin-top: 18px;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(255,255,255,0.06);
      border: 1px solid var(--border);
      color: var(--text);
      font-size: 14px;
    }

    .dot {
      width: 10px;
      height: 10px;
      border-radius: 999px;
      background: var(--success);
      box-shadow: 0 0 12px rgba(134,239,172,0.8);
      flex: 0 0 auto;
    }

    .action-bar {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .btn, .btn-secondary {
      appearance: none;
      text-decoration: none;
      border: 0;
      cursor: pointer;
      padding: 12px 18px;
      border-radius: 14px;
      font-weight: 700;
      font-size: 14px;
      transition: transform 0.15s ease, box-shadow 0.15s ease, opacity 0.15s ease;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 46px;
    }

    .btn:hover, .btn-secondary:hover {
      transform: translateY(-1px);
    }

    .btn {
      color: white;
      background: linear-gradient(135deg, var(--accent), var(--accent-2));
      box-shadow: 0 12px 28px rgba(79,124,255,0.35);
    }

    .btn-secondary {
      color: var(--text);
      background: rgba(255,255,255,0.05);
      border: 1px solid var(--border);
    }

    .grid {
      display: grid;
      grid-template-columns: 1.05fr 0.95fr;
      gap: 24px;
      align-items: start;
    }

    .panel {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 22px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
    }

    .panel-title {
      margin: 0 0 6px;
      font-size: 20px;
      letter-spacing: -0.02em;
    }

    .panel-text {
      margin: 0 0 18px;
      color: var(--muted);
      line-height: 1.6;
      font-size: 14px;
    }

    .textarea-wrap {
      position: relative;
    }

    textarea {
      width: 100%;
      min-height: 180px;
      resize: vertical;
      padding: 16px 16px 54px;
      border-radius: 16px;
      border: 1px solid rgba(255,255,255,0.10);
      background: rgba(7,11,22,0.65);
      color: var(--text);
      outline: none;
      font: inherit;
      line-height: 1.6;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.04);
    }

    textarea::placeholder {
      color: #7e8db3;
    }

    textarea:focus {
      border-color: rgba(124,156,255,0.65);
      box-shadow: 0 0 0 4px rgba(124,156,255,0.14);
    }

    .composer-actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
      margin-top: 14px;
    }

    .helper {
      color: var(--muted);
      font-size: 13px;
    }

    .notes-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 14px;
    }

    .pill {
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(255,255,255,0.05);
      border: 1px solid var(--border);
      color: var(--muted);
      font-size: 13px;
      font-weight: 600;
    }

    .notes-list {
      display: grid;
      gap: 14px;
    }

    .note {
      background: linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0.02));
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 18px;
      transition: transform 0.15s ease, border-color 0.15s ease;
    }

    .note:hover {
      transform: translateY(-2px);
      border-color: rgba(124,156,255,0.35);
    }

    .note-body {
      font-size: 15px;
      line-height: 1.7;
      color: var(--text);
      white-space: pre-wrap;
      word-break: break-word;
      margin-bottom: 12px;
    }

    .note-meta {
      color: var(--muted);
      font-size: 12px;
      border-top: 1px solid rgba(255,255,255,0.08);
      padding-top: 10px;
    }

    .empty {
      padding: 28px 20px;
      border: 1px dashed rgba(255,255,255,0.14);
      border-radius: 18px;
      text-align: center;
      color: var(--muted);
      background: rgba(255,255,255,0.02);
    }

    .guest {
      text-align: center;
      padding: 38px 24px;
    }

    .guest h2 {
      font-size: 28px;
      margin: 0 0 10px;
      letter-spacing: -0.03em;
    }

    .guest p {
      color: var(--muted);
      line-height: 1.7;
      max-width: 600px;
      margin: 0 auto 22px;
    }

    .guest-card {
      max-width: 760px;
      margin: 0 auto;
    }

    .feature-row {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 14px;
      margin-top: 22px;
      text-align: left;
    }

    .feature {
      padding: 16px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(255,255,255,0.03);
    }

    .feature strong {
      display: block;
      margin-bottom: 6px;
      font-size: 14px;
    }

    .feature span {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.6;
    }

    @media (max-width: 900px) {
      .grid {
        grid-template-columns: 1fr;
      }

      .feature-row {
        grid-template-columns: 1fr;
      }

      .hero {
        padding: 22px;
      }
    }

    @media (max-width: 560px) {
      .wrap {
        width: min(100% - 20px, 1100px);
        margin: 20px auto;
      }

      .panel, .hero {
        border-radius: 20px;
      }

      .btn, .btn-secondary {
        width: 100%;
      }

      .action-bar {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <div class="hero-top">
        <div>
          <div class="brand">
            <div class="brand-badge">📝</div>
            <div>
              <h1>User Notes</h1>
              <p class="subtitle">A cleaner, more modern space for writing and reviewing your private notes.</p>
            </div>
          </div>

          {% if email %}
            <div class="status">
              <span class="dot"></span>
              Signed in as <strong>{{ email }}</strong>
            </div>
          {% endif %}
        </div>

        <div class="action-bar">
          {% if signed_in %}
            <a class="btn-secondary" href="/logout">Logout</a>
          {% else %}
            <a class="btn" href="/login">Login with Cognito</a>
          {% endif %}
        </div>
      </div>
    </section>

    {% if signed_in %}
      <section class="grid">
        <div class="panel">
          <h2 class="panel-title">Write a new note</h2>
          <p class="panel-text">Capture thoughts, reminders, or anything you want to keep private.</p>

          <form method="post">
            <div class="textarea-wrap">
              <textarea name="content" placeholder="Write your private note here..."></textarea>
            </div>

            <div class="composer-actions">
              <div class="helper">Only your notes are shown in your session.</div>
              <button class="btn" type="submit">Save note</button>
            </div>
          </form>
        </div>

        <div class="panel">
          <div class="notes-head">
            <div>
              <h2 class="panel-title" style="margin-bottom:4px;">Your notes</h2>
              <p class="panel-text" style="margin-bottom:0;">Recent entries are shown first.</p>
            </div>
            <div class="pill">{{ notes|length }} note{% if notes|length != 1 %}s{% endif %}</div>
          </div>

          <div class="notes-list">
            {% if notes %}
              {% for n in notes %}
                <article class="note">
                  <div class="note-body">{{ n[1] }}</div>
                  <div class="note-meta">Created: {{ n[2] }}</div>
                </article>
              {% endfor %}
            {% else %}
              <div class="empty">
                No notes yet. Write your first note to get started.
              </div>
            {% endif %}
          </div>
        </div>
      </section>
    {% else %}
      <section class="panel guest guest-card">
        <h2>Your private notes, in one secure place</h2>
        <p>
          Sign in with Cognito to create, save, and review your personal notes in a cleaner interface.
        </p>
        <a class="btn" href="/login">Login with Cognito</a>

        <div class="feature-row">
          <div class="feature">
            <strong>Private by session</strong>
            <span>Only signed-in users can access their notes view.</span>
          </div>
          <div class="feature">
            <strong>Simple workflow</strong>
            <span>Write a note, save it, and see the newest entries first.</span>
          </div>
          <div class="feature">
            <strong>Modern design</strong>
            <span>Better spacing, clearer hierarchy, and improved readability.</span>
          </div>
        </div>
      </section>
    {% endif %}
  </div>
</body>
</html>
"""

def get_conn():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )

def ensure_schema(conn):
    with conn.cursor() as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id BIGSERIAL PRIMARY KEY,
            owner_sub TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_notes_owner_sub ON notes(owner_sub);

        ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
        ALTER TABLE notes FORCE ROW LEVEL SECURITY;

        DO $$
        BEGIN
          IF NOT EXISTS (
            SELECT 1
            FROM pg_policies
            WHERE schemaname = 'public'
              AND tablename = 'notes'
              AND policyname = 'notes_select_own'
          ) THEN
            CREATE POLICY notes_select_own
            ON notes
            FOR SELECT
            USING (owner_sub = current_setting('app.user_sub', true));
          END IF;

          IF NOT EXISTS (
            SELECT 1
            FROM pg_policies
            WHERE schemaname = 'public'
              AND tablename = 'notes'
              AND policyname = 'notes_insert_own'
          ) THEN
            CREATE POLICY notes_insert_own
            ON notes
            FOR INSERT
            WITH CHECK (owner_sub = current_setting('app.user_sub', true));
          END IF;
        END
        $$;
        """)
    conn.commit()

def set_user_context(cur, user_sub):
    cur.execute("SELECT set_config('app.user_sub', %s, false)", (user_sub,))

@app.route("/", methods=["GET", "POST"])
def index():
    if "sub" not in session:
        return render_template_string(HTML, signed_in=False, notes=[], email=None)

    user_sub = session["sub"]

    with get_conn() as conn:
        ensure_schema(conn)

        with conn.cursor() as cur:
            set_user_context(cur, user_sub)

            if request.method == "POST":
                content = request.form.get("content", "").strip()
                if content:
                    cur.execute(
                        """
                        INSERT INTO notes (owner_sub, content)
                        VALUES (%s, %s)
                        """,
                        (user_sub, content)
                    )
                    conn.commit()
                    set_user_context(cur, user_sub)

            cur.execute(
                """
                SELECT id, content, created_at
                FROM notes
                WHERE owner_sub = %s
                ORDER BY id DESC
                """,
                (user_sub,)
            )
            notes = cur.fetchall()

    return render_template_string(
        HTML,
        signed_in=True,
        notes=notes,
        email=session.get("email")
    )

@app.route("/login")
def login():
    params = {
        "response_type": "code",
        "client_id": COGNITO_CLIENT_ID,
        "redirect_uri": REDIRECT_URI,
        "scope": "openid email aws.cognito.signin.user.admin"
    }
    return redirect(f"{AUTH_URL}?{urlencode(params)}")

@app.route("/callback")
def callback():
    code = request.args.get("code")
    if not code:
        return "Missing code", 400

    token_res = requests.post(
        TOKEN_URL,
        auth=(COGNITO_CLIENT_ID, COGNITO_CLIENT_SECRET),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "authorization_code",
            "client_id": COGNITO_CLIENT_ID,
            "code": code,
            "redirect_uri": REDIRECT_URI
        },
        timeout=20
    )
    token_res.raise_for_status()
    tokens = token_res.json()

    userinfo_res = requests.get(
        USERINFO_URL,
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
        timeout=20
    )
    userinfo_res.raise_for_status()
    userinfo = userinfo_res.json()

    session["sub"] = userinfo["sub"]
    session["email"] = userinfo.get("email", "")
    return redirect("/")

@app.route("/logout")
def logout():
    session.clear()
    params = {
        "client_id": COGNITO_CLIENT_ID,
        "logout_uri": APP_BASE_URL
    }
    return redirect(f"{LOGOUT_URL}?{urlencode(params)}")

@app.route("/health")
def health():
    return "ok", 200

app.run(host="0.0.0.0", port=8080)
PYEOF

cat > /etc/systemd/system/notesapp.service <<'SERVICEEOF'
[Unit]
Description=Notes App
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable notesapp
systemctl start notesapp