#!/usr/bin/env python3
"""Telegram research for northstar-osint (the engine behind ns-telegram).

Without a login (Telegram's public web previews, text only):
  lookup NAME                       what a t.me/NAME page says: type, title, bio, members
  preview-search CHANNEL TERM       posts in a public channel's web preview matching TERM

With a research account (Telegram API via Telethon; run `login` once):
  login                             interactive: phone number, code, 2FA password
  search TERM                       public channels, groups and users matching TERM
  messages CHAT TERM [LIMIT]        messages in a channel or group matching TERM ("" = latest)
  members GROUP [LIMIT]             members of a group you can see the member list of
  user NAME                         a user's public profile and current photo

Results are written to the current folder. The API ID and hash come from
~/.config/northstar/keys.env (TELEGRAM_API_ID, TELEGRAM_API_HASH); the login
session is kept in ~/.config/northstar/telegram/ (readable only by you). Neither
is ever printed or logged.
"""
import csv
import datetime
import html
import json
import os
import re
import sys
import urllib.parse
import urllib.request

UA = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"
CONF = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "northstar")
SESSION_DIR = os.path.join(CONF, "telegram")


def clean_name(text):
    """'name', '@name', 't.me/name', 'https://t.me/s/name/123' -> 'name'"""
    t = re.sub(r"^https?://", "", text.strip())
    t = re.sub(r"^(t\.me|telegram\.me)/(s/)?", "", t)
    return re.sub(r"[/?].*$", "", t.lstrip("@"))


def valid(name):
    return re.fullmatch(r"[A-Za-z0-9_]{4,32}", name or "") is not None


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read(4 * 1024 * 1024).decode("utf-8", "replace")


def text_of(fragment):
    fragment = re.sub(r"(?i)<br\s*/?>", "\n", fragment)
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()


def meta(page, prop):
    m = re.search(r'<meta\s+property="%s"\s+content="([^"]*)"' % re.escape(prop), page)
    return html.unescape(m.group(1)) if m else ""


def save_json(name, data):
    with open(name, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False, default=str)


def save_csv(name, rows, fields):
    with open(name, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


# --- no login ----------------------------------------------------------------------
def cmd_lookup(raw):
    name = clean_name(raw)
    if not valid(name):
        print("That isn't a Telegram username (5–32 letters, digits or _).")
        return 1
    page = fetch(f"https://t.me/{name}")
    extra = re.search(r'<div class="tgme_page_extra">(.*?)</div>', page, re.S)
    extra = text_of(extra.group(1)) if extra else ""
    button = re.search(r'<a class="tgme_action_button_new[^"]*"[^>]*>(.*?)</a>', page, re.S)
    button = text_of(button.group(1)) if button else ""
    title = meta(page, "og:title")
    if not title or (title.startswith("Telegram: Contact") and not extra):
        print(f"@{name}: no public channel, group or user with that name (or it's hidden).")
        save_json("lookup.json", {"username": name, "found": False, "checked_utc": now()})
        return 0
    kind = ("channel" if "subscriber" in extra else "group" if "member" in extra
            else "bot" if "Start Bot" in button else "user")
    info = {"username": name, "found": True, "type": kind, "title": title,
            "description": meta(page, "og:description"), "counts": extra, "button": button,
            "photo": meta(page, "og:image"), "url": f"https://t.me/{name}", "checked_utc": now()}
    save_json("lookup.json", info)
    for k in ("type", "title", "counts", "description", "url"):
        if info[k]:
            print(f"{k:>11}: {info[k]}")
    return 0


def parse_preview(page, channel):
    posts = []
    for block in re.split(r'<div class="tgme_widget_message_wrap', page)[1:]:
        post = re.search(r'data-post="([^"]+)"', block)
        when = re.search(r'<time[^>]*datetime="([^"]+)"', block)
        body = re.search(r'<div class="tgme_widget_message_text[^"]*"[^>]*>(.*?)</div>', block, re.S)
        views = re.search(r'<span class="tgme_widget_message_views">([^<]+)</span>', block)
        if post:
            posts.append({"date_utc": when.group(1) if when else "", "post": post.group(1),
                          "url": f"https://t.me/{post.group(1)}", "views": views.group(1) if views else "",
                          "text": text_of(body.group(1)) if body else ""})
    return posts


def cmd_preview_search(raw, term):
    name = clean_name(raw)
    if not valid(name):
        print("That isn't a Telegram channel name.")
        return 1
    url = f"https://t.me/s/{name}" + (f"?q={urllib.parse.quote_plus(term)}" if term else "")
    posts = parse_preview(fetch(url), name)
    save_csv("posts.csv", posts, ["date_utc", "post", "url", "views", "text"])
    print(f"{len(posts)} posts{' matching ' + repr(term) if term else ''} in @{name}'s web preview"
          " (the preview shows the most recent matches only; the API search goes further).")
    for p in posts[-10:]:
        print(f"  {p['date_utc'][:16]}  {p['url']}\n    {p['text'][:140]}")
    if not posts:
        print("No posts: the channel may be private, a group (no web preview), or have no matches.")
    return 0


# --- with a login --------------------------------------------------------------------
def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def keys():
    vals = {}
    path = os.path.join(CONF, "keys.env")
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if "=" in line:
                k, v = line.rstrip("\n").split("=", 1)
                vals[k] = v
    return vals.get("TELEGRAM_API_ID", ""), vals.get("TELEGRAM_API_HASH", "")


def client():
    try:
        from telethon.sync import TelegramClient
    except ImportError:
        print("Telethon isn't installed: ./install.sh --only social")
        sys.exit(1)
    api_id, api_hash = keys()
    if not (api_id.isdigit() and api_hash):
        print("Add your Telegram API ID and hash first: main menu → API keys (from https://my.telegram.org/apps).")
        sys.exit(1)
    os.makedirs(SESSION_DIR, mode=0o700, exist_ok=True)
    os.chmod(SESSION_DIR, 0o700)
    c = TelegramClient(os.path.join(SESSION_DIR, "northstar"), int(api_id), api_hash)
    return c


def connected():
    c = client()
    c.connect()
    if not c.is_user_authorized():
        print("Not logged in: Telegram menu → Log in for searches.")
        sys.exit(1)
    return c


def flood(exc):
    print(f"Telegram asked us to slow down: wait {getattr(exc, 'seconds', '?')} seconds and try again.")
    return 1


def cmd_login():
    c = client()
    c.start()                      # prompts for phone, code and 2FA password in the terminal
    me = c.get_me()
    print(f"Logged in as {me.first_name or ''} (@{me.username or '-'}). The session is kept in {SESSION_DIR}.")
    for f in os.listdir(SESSION_DIR):
        os.chmod(os.path.join(SESSION_DIR, f), 0o600)
    c.disconnect()
    return 0


def describe(entity):
    from telethon.tl.types import Channel, Chat, User
    if isinstance(entity, User):
        kind = "bot" if entity.bot else "user"
        title = " ".join(x for x in (entity.first_name, entity.last_name) if x)
    elif isinstance(entity, Channel):
        kind = "channel" if entity.broadcast else "group"
        title = entity.title
    elif isinstance(entity, Chat):
        kind, title = "group (basic)", entity.title
    else:
        kind, title = type(entity).__name__, ""
    return {"type": kind, "id": entity.id, "username": getattr(entity, "username", "") or "",
            "title": title, "members": getattr(entity, "participants_count", "") or "",
            "verified": bool(getattr(entity, "verified", False)), "scam": bool(getattr(entity, "scam", False)),
            "fake": bool(getattr(entity, "fake", False)),
            "url": f"https://t.me/{entity.username}" if getattr(entity, "username", None) else ""}


def cmd_search(term):
    from telethon.errors import FloodWaitError
    from telethon.tl.functions.contacts import SearchRequest
    c = connected()
    try:
        r = c(SearchRequest(q=term, limit=100))
    except FloodWaitError as exc:
        return flood(exc)
    rows = [describe(e) for e in list(r.chats) + list(r.users)]
    save_csv("search.csv", rows, ["type", "id", "username", "title", "members", "verified", "scam", "fake", "url"])
    print(f"{len(rows)} public channels, groups and users match {term!r}:")
    for x in rows[:25]:
        print(f"  {x['type']:<8} @{x['username'] or '-':<24} {x['title'][:50]}  {x['members']}")
    c.disconnect()
    return 0


def cmd_messages(chat, term, limit="500"):
    from telethon.errors import FloodWaitError
    c = connected()
    try:
        ent = c.get_entity(clean_name(chat) if not chat.lstrip("-").isdigit() else int(chat))
        info = describe(ent)
        rows = []
        for m in c.iter_messages(ent, search=term or None, limit=int(limit)):
            rows.append({"date_utc": m.date.strftime("%Y-%m-%dT%H:%M:%SZ"), "id": m.id,
                         "url": f"https://t.me/{info['username']}/{m.id}" if info["username"] else "",
                         "sender_id": m.sender_id or "", "views": m.views or "", "forwards": m.forwards or "",
                         "forwarded_from": getattr(getattr(m.fwd_from, "from_id", None), "channel_id", "")
                         or getattr(getattr(m.fwd_from, "from_id", None), "user_id", "") if m.fwd_from else "",
                         "reply_to": m.reply_to_msg_id or "", "media": type(m.media).__name__ if m.media else "",
                         "text": m.message or ""})
    except FloodWaitError as exc:
        return flood(exc)
    except ValueError as exc:
        print(f"Couldn't open that chat: {exc}")
        return 1
    save_json("chat.json", info)
    save_csv("messages.csv", rows, ["date_utc", "id", "url", "sender_id", "views", "forwards", "forwarded_from",
                                    "reply_to", "media", "text"])
    print(f"{len(rows)} messages{' matching ' + repr(term) if term else ''} from {info['type']} {info['title']!r}.")
    for r in rows[:10]:
        print(f"  {r['date_utc'][:16]}  {r['url'] or r['id']}\n    {r['text'][:140]}")
    c.disconnect()
    return 0


def cmd_members(group, limit="10000"):
    from telethon.errors import ChatAdminRequiredError, FloodWaitError
    from telethon.tl.types import UserStatusOffline, UserStatusOnline, UserStatusRecently
    c = connected()
    try:
        ent = c.get_entity(clean_name(group))
        info = describe(ent)
        rows = []
        for u in c.iter_participants(ent, limit=int(limit)):
            st = u.status
            seen = (st.was_online.strftime("%Y-%m-%dT%H:%M:%SZ") if isinstance(st, UserStatusOffline)
                    else "online" if isinstance(st, UserStatusOnline) else "recently" if isinstance(st, UserStatusRecently)
                    else type(st).__name__.replace("UserStatus", "").lower() if st else "")
            rows.append({"id": u.id, "username": u.username or "", "first_name": u.first_name or "",
                         "last_name": u.last_name or "", "phone": u.phone or "", "bot": u.bot, "deleted": u.deleted,
                         "premium": bool(getattr(u, "premium", False)), "last_seen": seen})
    except ChatAdminRequiredError:
        print("This group hides its member list (only admins can see it).")
        return 1
    except FloodWaitError as exc:
        return flood(exc)
    except ValueError as exc:
        print(f"Couldn't open that group: {exc}")
        return 1
    save_json("chat.json", info)
    save_csv("members.csv", rows, ["id", "username", "first_name", "last_name", "phone", "bot", "deleted", "premium",
                                   "last_seen"])
    print(f"{len(rows)} members of {info['title']!r}" + (f" (Telegram reports {info['members']})" if info["members"] else "")
          + ". Large groups only show part of their members to non-admins.")
    c.disconnect()
    return 0


def cmd_user(name):
    from telethon.errors import FloodWaitError
    from telethon.tl.functions.users import GetFullUserRequest
    c = connected()
    try:
        u = c.get_entity(clean_name(name))
        full = c(GetFullUserRequest(u))
    except FloodWaitError as exc:
        return flood(exc)
    except (ValueError, TypeError) as exc:
        print(f"Couldn't find that user: {exc}")
        return 1
    fu = full.full_user
    info = {**describe(u), "first_name": u.first_name or "", "last_name": u.last_name or "",
            "usernames": [x.username for x in (getattr(u, "usernames", None) or [])] or [u.username or ""],
            "phone": u.phone or "", "bot": u.bot, "premium": bool(getattr(u, "premium", False)),
            "bio": fu.about or "", "common_chats": fu.common_chats_count,
            "personal_channel_id": getattr(fu, "personal_channel_id", None) or "",
            "birthday": str(getattr(fu, "birthday", "") or ""), "checked_utc": now()}
    photo = c.download_profile_photo(u, file="profile_photo")
    info["profile_photo"] = os.path.basename(photo) if photo else ""
    save_json("user.json", info)
    for k in ("type", "id", "title", "usernames", "bio", "phone", "premium", "common_chats", "birthday", "profile_photo"):
        if info.get(k) not in ("", None, [], [""]):
            print(f"{k:>14}: {info[k]}")
    c.disconnect()
    return 0


def main(argv):
    cmds = {"lookup": (cmd_lookup, 1, 1), "preview-search": (cmd_preview_search, 2, 2), "login": (cmd_login, 0, 0),
            "search": (cmd_search, 1, 1), "messages": (cmd_messages, 2, 3), "members": (cmd_members, 1, 2),
            "user": (cmd_user, 1, 1)}
    if len(argv) < 2 or argv[1] not in cmds or not cmds[argv[1]][1] <= len(argv) - 2 <= cmds[argv[1]][2]:
        print(__doc__)
        return 2
    try:
        return cmds[argv[1]][0](*argv[2:])
    except OSError as exc:                       # network
        print(f"Network error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
