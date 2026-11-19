// Work sessions (Herdr's spaces) grouped by project, and by machine when more than one is known.
// A session is one piece of work, its panes often in several repos, so the list shows no repo or git
// state. A session nobody named takes the title of the first Claude session in it; Claude renames it
// on request. A session's project comes from the folders open in it (projects.json), or is set for
// that session (sessions.json); a header with a dot in the project's color heads each project.
// Rule: ~/.claude/rules/herdr-sessions.md. A session shows only whether it needs you: a red dot while
// waiting, a grey ring when done. Click to switch, right-click for its menu, drag to reorder.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, ScrollHandle } from "gpui-base";
import { spaces, machines, agents, panes, run, openOverlay, hc, theme, shared, setShared, layout, checking, home, readTextFile, writeTextFile } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

const RAIL_CELL = 32;
const railCell = (el) => h_flex().flex_none().justify_center().child(el);
const ROW_HEIGHT = 30;

// Projects by folder ({"Merlin": ["~/Dev/agx_core*", ...]}, a trailing * matches any suffix), edited by
// the user and by Claude. Sessions given a project ({"<space id>": "Merlin"}), by this mod once and by
// Claude on request. And this list's view of every session, for Claude's script (~/.claude/herdr-session.sh).
const PROJECTS = () => `${home()}/.config/herdr-app/projects.json`;
const SESSIONS = () => `${home()}/.config/herdr-app/sessions.json`;
const LIVE = () => `${home()}/.config/herdr-app/sessions-live.json`;
const parse = (text) => { try { const v = JSON.parse(text ?? "{}"); return v && typeof v === "object" && !Array.isArray(v) ? v : {}; } catch { return {}; } };

// A Claude session's title, when it names the work: Claude Code puts its session title in the terminal
// title, after a status glyph. Its plain program name, a folder path or a host isn't a title.
function sessionTitle(a) {
  if (a.app !== "claude-code" && a.program?.key !== "claude") return null;
  const raw = (a.title ?? "").replace(/^[^\p{L}\p{N}~/]+/u, "").trim();
  if (!raw || /^[~/]/.test(raw) || raw.includes("@")) return null;
  const lower = raw.toLowerCase();
  if (raw === a.address || lower === "claude" || lower === "claude code" || lower === a.program?.name?.toLowerCase()) return null;
  return raw;
}

// What a stored color name looks like on an avatar (the same in every mod
// that draws space avatars): one strong color per hue, light and dark alike.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// `color` mixed into `base` by `amount` (0..1); both #rrggbb. Anything else returns `color`.
function mix(color, base, amount) {
  const rgb = (h) => (/^#[0-9a-f]{6}/i.test(h ?? "") ? [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)) : null);
  const a = rgb(color), b = rgb(base);
  if (!a || !b) return color;
  return "#" + a.map((v, i) => Math.round(v * amount + b[i] * (1 - amount)).toString(16).padStart(2, "0")).join("");
}

export default class Spaces extends View {
  init(_props, cx) {
    this.named = new Set(); // spaces this copy has asked to rename, so it asks once
    this.projects = {}; // project -> folder patterns (projects.json)
    this.sessions = {}; // space -> project, set for that session (sessions.json)
    this.sessionsText = null; // sessions.json as read, for writing it back only when unchanged
    this.toAssign = {}; // space -> project, waiting to be written to sessions.json
    this.liveText = null;
    this.pressed = null;
    this.over = null;
    this.scroll = ScrollHandle.new(); // the list's position: the active space is brought into view through it
    this.activeAt = -1; // the active space's place among the list's children (headers and rows), -1 when not drawn
    this.machines = [];
    try {
      this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
      if (!this.reconnecting || typeof this.reconnecting !== "object" || Array.isArray(this.reconnecting)) this.reconnecting = {};
      for (const state of Object.values(this.reconnecting)) state.busy = false;
    } catch { this.reconnecting = {}; }
    try { this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]")); } catch { this.folded = new Set(); }
    this.refreshMachines(cx);
    cx.timer.every(15000, cx => this.refreshMachines(cx));
    if (checking()) return;
    this.sync(cx);
    cx.timer.every(2000, (cx) => this.sync(cx));
  }

  // Reads the project files, writes pending session projects, and publishes this list's view for Claude.
  sync(cx) {
    if (this.syncing) return;
    this.syncing = true;
    cx.spawn(async (cx) => {
      try {
        const [projects, sessionsText] = await Promise.all([readTextFile(PROJECTS()).catch(() => null), readTextFile(SESSIONS()).catch(() => null)]);
        let sessions = parse(sessionsText), text = sessionsText;
        const pending = Object.entries(this.toAssign).filter(([id]) => !(id in sessions));
        if (pending.length) {
          sessions = { ...sessions, ...Object.fromEntries(pending) };
          const next = JSON.stringify(sessions, null, 2) + "\n";
          try { await writeTextFile(SESSIONS(), next, sessionsText); text = next; this.toAssign = {}; } catch {}
        }
        const changed = JSON.stringify([projects, sessions]) !== JSON.stringify([this.projectsRaw, this.sessions]);
        this.projectsRaw = projects; this.projects = parse(projects); this.sessions = sessions; this.sessionsText = text;
        this.loaded = true;
        const live = JSON.stringify(Object.fromEntries(spaces().map((s) => {
          const folders = this.folders(s);
          return [s.id, { title: s.name, project: this.projectOf(s), set: s.id in this.sessions, folders }];
        })), null, 2) + "\n";
        if (live !== this.liveText) {
          const old = await readTextFile(LIVE()).catch(() => null);
          try { await writeTextFile(LIVE(), live, old); this.liveText = live; } catch {}
        }
        if (changed) cx.notify();
      } finally { this.syncing = false; }
    });
  }

  // The live folders of a session's panes, in pane order.
  folders(s) {
    const tabs = new Set((s.tabs ?? []).map((t) => t.id));
    return [...new Set(panes().filter((p) => tabs.has(p.tab) && p.cwd).map((p) => p.cwd))];
  }

  // The project whose longest folder pattern holds `dir`, or null.
  matchProject(dir) {
    let best = null, length = -1;
    for (const [name, patterns] of Object.entries(this.projects)) for (const raw of Array.isArray(patterns) ? patterns : []) {
      const p = String(raw).replace(/^~/, home());
      const hit = p.endsWith("*") ? dir.startsWith(p.slice(0, -1)) : dir === p || dir.startsWith(`${p}/`);
      if (hit && p.length > length) { best = name; length = p.length; }
    }
    return best;
  }

  // Set for this session, else the first open folder in a project, else null (the "Other" group).
  projectOf(s) {
    return this.sessions[s.id] ?? this.toAssign[s.id] ?? this.folders(s).map((d) => this.matchProject(d)).find(Boolean) ?? null;
  }

  // Names each space nobody named after the first Claude session in it with a title, once.
  // The rename makes it a named space, so later sessions and folder changes leave it alone.
  nameSpaces(sp) {
    if (checking()) return;
    const all = agents();
    for (const s of sp) {
      // A titled session settles its project once; sessions titled before this list ran included.
      if (s.named && this.loaded && !(s.id in this.sessions) && !(s.id in this.toAssign)) {
        const project = this.projectOf(s);
        if (project) this.toAssign[s.id] = project;
      }
      if (s.named || this.named.has(s.id)) continue;
      const title = all.filter((a) => a.space === s.id).map(sessionTitle).find(Boolean);
      if (!title) continue;
      this.named.add(s.id);
      run("space.rename", { id: s.id, name: title });
      // Its project is settled at the same moment: later folder changes don't move it.
      const project = this.projectOf(s);
      if (project && !(s.id in this.sessions)) this.toAssign[s.id] = project;
    }
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try { const r = await hc(["machine", "ls", "--json"]); if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary); } catch {}
      cx.notify();
    });
  }

  rebuilt(machine) {
    return machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? "");
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code !== 0) {
            let error;
            try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
            throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
          }
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add"];
        if (machine.via) args.push("--via", machine.target);
        else args.push(machine.target);
        args.push("--name", name);
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  menu(w) {
    // A popup is as tall as its items; height is only the most.
    openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: w.id } } });
  }

  ordered() {
    return spaces().map((w, i) => ({ w, i }));
  }

  // The rows, under a header per machine once one isn't this computer.
  grouped(t, collapsed) {
    const rows = this.ordered();
    const draw = (r, project, fill) => (collapsed ? this.compact(r, project, fill, t) : this.row(r, t));
    // Where the active space's row lands among the children this returns: the list scrolls by its direct
    // children, and machine headers, login notes and loading rows count too.
    this.activeAt = -1;
    let before = 0;
    const remote = [...new Set([...rows.map(r => r.w.machine).filter(Boolean), ...this.machines.map(m => m.name), ...Object.keys(this.reconnecting)])].sort();
    const loading = m => {
      const layout = machines().find(k => k.name === m)?.layout;
      return layout === "loading" || (!layout && this.machines.some(k => k.name === m && k.state === "connected"));
    };
    const loadingRow = m => h_flex().id(`machine-loading-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).items_center().when(collapsed, el => el.justify_center()).text_size(12).text_color(t.dim).child(collapsed ? "…" : "Loading…");
    if (!remote.length) {
      if (loading(null) && !rows.length) return [loadingRow(null)];
      const items = this.byProject(rows, draw, t, collapsed);
      this.activeAt = items.active;
      return items.list;
    }
    const machineNames = [null, ...remote];
    return machineNames.flatMap((m) => {
      const mine = rows.filter((r) => (r.w.machine ?? null) === m);
      const repair = this.reconnecting[m];
      const machine = this.machines.find(k => k.name === m) ?? repair?.machine;
      const connected = !m || machine?.state === "connected";
      const rebuilt = this.rebuilt(machine) || !!repair;
      const login = machine?.state === "needs_login" ? `hc machine login ${m}` : null;
      const folded = this.folded.has(m);
      const icon = svg(`mods/workspace-chrome/${m ? "server" : "monitor"}.svg`).size(13).flex_none();
      const badge = div().absolute().right(-3).bottom(-2).size(6).rounded(3).border_1().border_color(t.chrome).bg(connected ? t.ansi2 : t.dim);
      const head = h_flex().id(`machine-${m ?? "local"}`).h(26).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().text_size(11).text_color(t.dim)
        .when(collapsed, el => el.mt(4).w(RAIL_CELL).justify_center().rounded(6).tooltip(login ? `${m} needs a login: run ${login}. Click for Copy.` : m ? `${m} · ${connected ? "connected" : (machine?.state ?? "asleep").replace(/_/g, " ")}` : "This computer"))
        .cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => {
          if (collapsed && login) { run("app.settings", { section: "machines" }); return; }
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .when(machine?.keeps_running_after_logout === false, el => el.child(div().id(`machine-logout-${m}`)
          .flex_none().text_color(t.blocked).tooltip("Agents stop when you disconnect. Click for the fix.")
          .on_click((_e, cx) => { cx.stop_propagation(); openOverlay({ mod: "machine-add", kind: "dialog", width: 560 }); }).child("⚠")))
        .when(!collapsed, el => el.child(icon))
        .when(collapsed, el => el.child(div().relative().flex_none().child(icon).when(Boolean(m), el => el.child(badge))))
        .when(!collapsed, el => el.child(div().flex_1().truncate().child(m ?? "This computer"))
          .when(!connected && !rebuilt && !login, el => el.child(div().flex_none().child((machine?.state ?? "asleep").replace(/_/g, " "))))
          .when(rebuilt, el => el.child(h_flex().flex_none().gap(3).items_center()
            .child(div().max_w(140).truncate().child(repair?.error || "rebuilt ·"))
            .child(div().id(`machine-connect-${m}`).text_color(repair?.error ? t.blocked : t.muted)
              .hover(s => s.text_color(t.foreground))
              .tooltip(repair?.error || "This machine was rebuilt or replaced. Click to connect to the new one.")
              .on_click((_e, cx) => { cx.stop_propagation(); this.reconnect(machine, cx); })
              .child(repair?.busy ? "Connecting…" : "Connect"))))
          .when(connected, el => el.child(div().id(`machine-add-${m ?? "local"}`).flex_none().px(4).rounded(4).hover(s => s.bg(t.hover).text_color(t.foreground))
            .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: m ?? "" }); }).child("+")))
          .child(div().size(6).rounded(3).flex_none().bg(connected ? t.ansi2 : t.dim))
          .child(svg(`mods/workspace-chrome/chevron-${folded ? "right" : "down"}.svg`).size(11).flex_none()));
      const empty = h_flex().id(`machine-new-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().rounded(7)
        .text_size(12).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => run("space.new", { machine: m ?? "" }))
        .when(collapsed, el => el.w(RAIL_CELL).rounded(6).justify_center().tooltip(`New space on ${m ?? "this computer"}`)
          .child(h_flex().size(18).rounded(5).border_1().border_color(t.dim).items_center().justify_center()
            .child(svg("mods/workspace-chrome/plus.svg").size(10))))
        .when(!collapsed, el => el.child(svg("mods/workspace-chrome/plus.svg").size(12)).child("New space there"));
      if (!collapsed && rebuilt) { before += 1; return [head]; }
      const cell = collapsed ? railCell : (el) => el;
      const guidance = !collapsed && login ? [v_flex().px(8).pb(6).gap(3).flex_none()
        .child(div().text_size(11).text_color(t.blocked).child("needs a login: run"))
        .child(h_flex().gap(5).items_center()
          .child(div().flex_1().min_w(0).truncate().tooltip(login).text_size(11).text_color(t.muted).child(login))
          .child(div().id(`machine-login-copy-${m}`).flex_none().px(5).py(2).rounded(4)
            .text_size(11).text_color(t.foreground).bg(t.raised).cursor_pointer().hover(s => s.bg(t.hover))
            .on_click((_e, cx) => { cx.stop_propagation(); cx.write_to_clipboard(login); this.copiedLogin = login; cx.notify(); })
            .child(this.copiedLogin === login ? "Copied" : "Copy")))] : [];
      const grouped = this.byProject(mine, draw, t, collapsed);
      const items = [cell(head), ...guidance, ...(folded ? [] : mine.length ? grouped.list : [loading(m) ? loadingRow(m) : cell(empty)])];
      const first = folded ? -1 : grouped.active;
      if (first >= 0) this.activeAt = before + 1 + guidance.length + first;
      before += items.length;
      return items;
    });
  }

  // Rows under a header per project, in the order projects first appear; sessions in no project go last,
  // under "Other". The rail (a narrow sidebar) has no room for headers: a gap parts its projects instead.
  // `active`: the active row's index.
  byProject(rows, draw, t, collapsed) {
    const groups = new Map();
    for (const r of rows) {
      const project = this.projectOf(r.w);
      if (!groups.has(project)) groups.set(project, []);
      groups.get(project).push(r);
    }
    const order = [...groups.keys()].filter((p) => p !== null);
    if (groups.has(null)) order.push(null);
    const list = [];
    let active = -1;
    for (const project of order) {
      const mine = groups.get(project);
      const fill = this.fill(project, t);
      if (!collapsed) list.push(this.projectHeader(project, fill, mine.length, mine.some((r) => r.w.active), t));
      else if (list.length) list.push(div().id(`project-gap-${project ?? "other"}`).h(8).flex_none());
      for (const r of mine) {
        if (r.w.active) active = list.length;
        list.push(draw(r, project, fill));
      }
    }
    return { list, active };
  }

  // A project's color as drawn; "Other" is dim.
  fill(project, t) {
    if (!project) return t.dim;
    const color = this.projectColor(project);
    return color.startsWith("#") ? color : (MARK[color] ?? t[color]);
  }

  // A dot in the project's color, its name in bold SF Pro (Herdr's Geist draws no bold) and its session count.
  // The project holding the active session has a larger dot in a tinted ring and its name in its color; the
  // name keeps its font and size, so switching projects moves no text.
  // The claude-usage mod draws the same header; keep the two alike.
  projectHeader(project, fill, count, active, t) {
    // The dot's slot is as wide as the active dot, so the names line up; the ring draws past it.
    const dot = h_flex().w(10).h(10).flex_none().items_center().justify_center()
      .child(active
        ? h_flex().size(16).flex_none().rounded(8).bg(mix(fill, t.chrome, 0.3)).items_center().justify_center()
            .child(div().size(10).rounded(5).bg(fill))
        : div().size(8).rounded(4).bg(fill));
    return h_flex().id(`project-${project ?? "other"}`).h(32).flex_none().pt(8).px(8).gap(8).items_center()
      .child(dot)
      .child(div().flex_1().min_w(0).truncate().font_family("SF Pro").font_bold().text_size(12)
        .text_color(active ? fill : t.muted).child(project ?? "Other"))
      .child(div().flex_none().text_size(12).text_color(t.dim).child(String(count)));
  }

  // A small red dot while the session waits for you, a grey ring when it's done; nothing otherwise.
  mark(status, t) {
    if (status === "blocked") return div().size(6).flex_none().rounded(3).bg(t.blocked);
    if (status === "done") return div().size(6.5).flex_none().rounded(4).border(1.25).border_color(t.muted);
    return null;
  }


  // A project's label color: picked once per project, the least used first, and kept in shared state.
  projectColor(project) {
    const colors = shared("project.colors") ?? {};
    if (colors[project]) return colors[project];
    const palette = ["ansi4", "ansi3", "ansi6", "ansi5", "ansi2", "ansi1"];
    const uses = (c) => Object.values(colors).filter((v) => v === c).length;
    const color = palette.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    setShared("project.colors", { ...colors, [project]: color });
    return color;
  }

  row({ w, i }, t) {
    const on = w.active;
    const fromIndex = this.pressed === null ? -1 : spaces().findIndex(s => s.id === this.pressed);
    const mark = this.mark(w.status, t);
    return v_flex()
      .relative()
      .id(`space-${w.id}`)
      // The title lines up with the project name: header padding 8, dot slot 10, gap 8.
      .pl(26)
      .pr(8)
      .h(ROW_HEIGHT)
      .flex_none()
      .justify_center()
      .rounded(8)
      .when(on, (el) => el.bg(t.selected))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .when(this.pressed === w.id && this.over !== w.id, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === w.id && this.pressed !== w.id, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(fromIndex < i, line => line.bottom(0))
          .when(fromIndex > i, line => line.top(0)),
      ))
      .on_mouse_down("left", () => {
        this.pressed = w.id;
        this.over = w.id;
      })
      .on_mouse_move((_e, cx) => {
        const source = spaces().find(s => s.id === this.pressed);
        const over = source && (source.machine ?? null) === (w.machine ?? null) ? w.id : null;
        if (this.pressed !== null && this.over !== over) {
          this.over = over;
          cx.notify();
        }
      })
      .on_mouse_up("left", (_e, cx) => {
        const from = this.pressed;
        const over = this.over;
        this.pressed = null;
        this.over = null;
        if (from !== null && over === w.id && from !== w.id) {
          const index = spaces().findIndex(s => s.id === w.id);
          if (index !== -1) run("space.move", { id: from, index: index + 1 });
        } else if (from === w.id) run("space.select", { id: w.id });
        cx.notify();
      })
      .on_mouse_down("right", () => this.menu(w))
      // The mark sits right after the title; a long title shrinks and truncates, the mark stays.
      .child(
        h_flex()
          .gap(8)
          .items_center()
          // A waiting session's title is red too: it can't go on without you.
          .child(div().flex_shrink(1).min_w(0).truncate().text_color(w.status === "blocked" ? t.blocked : t.foreground).child(w.name))
          .when(Boolean(mark), (el) => el.child(mark)),
      );
  }

  // The rail's cell: a dot in the session's project color.
  compact({ w }, project, fill, t) {
    return railCell(h_flex()
      .id(`space-${w.id}`)
      .w(RAIL_CELL)
      .h(26)
      .rounded(6)
      .justify_center()
      .items_center()
      .tooltip(`${project ?? "Other"} · ${w.name}`)
      .when(w.active, (el) => el.bg(t.selected))
      .when(!w.active, (el) => el.hover((s) => s.bg(t.hover)))
      .on_click(() => run("space.select", { id: w.id }))
      .child(div().size(8).rounded(4).bg(fill)));
  }

  render() {
    const t = theme();
    const collapsed = narrow();
    const palette = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
    const sp = spaces();
    this.nameSpaces(sp);
    const ids = new Set(sp.map(p => p.id));
    const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
    let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
    for (const p of sp) {
      if (kept[p.id] || p.name === "~") continue;
      const uses = c => Object.values(kept).filter(v => v === c).length;
      kept[p.id] = palette.reduce((best, c) => uses(c) < uses(best) ? c : best);
      changed = true;
    }
    if (changed) setShared("space.colors", kept);
    const list = this.grouped(t, collapsed);
    // Bring the active space into view when it, or its place in the list, changes; a row already in view stays put.
    const active = sp.find(p => p.active)?.id;
    if (active !== this.revealed || this.activeAt !== this.revealedAt) {
      this.revealed = active;
      this.revealedAt = this.activeAt;
      if (this.activeAt >= 0) this.scroll.scroll_to_item(this.activeAt);
    }
    return v_flex().size_full().min_h(0).bg(t.chrome).text_size(13)
      .child(h_flex().h(31).pl(16).pr(10).items_center().justify_between().text_size(11.5).text_color(t.dim)
        .when(collapsed, el => el.pl(0).pr(0).justify_center())
        .when(!collapsed, el => el.child("Projects"))
        .child(div().id("space-new").size(26).flex_none().flex().items_center().justify_center().rounded(6).hover(s => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => run("space.new")).child(svg("mods/workspace-chrome/plus.svg").size(14))))
      .child(v_flex().flex_1().min_h(0).px(collapsed ? 0 : 8).pb(14).overflow_y_scrollbar().mode("always").track_scroll(this.scroll)
        // A block above (another mod's) growing, or the window resizing, shrinks this list and can push the active space out.
        .on_size_change((_size, cx) => { if (this.activeAt >= 0) { this.scroll.scroll_to_item(this.activeAt); cx.notify(); } })
        .on_mouse_up("left", (_e, cx) => { this.pressed = null; cx.notify(); })
        .children(list));
  }
}
