import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, panes, spaces, run, theme, settings, checking, props, layout, shared, setShared, home, readTextFile } from "herdr";
import { LIMITS, CONTEXT, level, levelColor, readLimit, readContext, logoColor, untilText, resetText, tokensText } from "./usage.js";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// A Claude session's folder name (its pane's live folder).
const folderOf = (a) => (panes().find((p) => p.pane === a.pane)?.cwd ?? "").replace(/\/+$/, "").split("/").pop() || a.space_name;
// The sidebar's (my-spaces) view of each work session, with its project: written there, read here.
const LIVE = () => `${home()}/.config/herdr-app/sessions-live.json`;
const isClaude = (a) => a.app === "claude-code" || a.program?.key === "claude";

// A Claude session's title, when it names the work: Claude Code puts its session title in the terminal
// title, after a status glyph. Its plain program name, a folder path or a host isn't a title.
function claudeTitle(a) {
  const raw = (a.title ?? "").replace(/^[^\p{L}\p{N}~/]+/u, "").trim();
  if (!raw || /^[~/]/.test(raw) || raw.includes("@")) return null;
  const lower = raw.toLowerCase();
  if (raw === a.address || lower === "claude" || lower === "claude code" || lower === a.program?.name?.toLowerCase()) return null;
  return raw;
}

// The project header and its colors as my-spaces draws them; keep the two alike.
// What a stored color name (shared "project.colors") looks like: one strong color per hue, light and dark alike.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// `color` mixed into `base` by `amount` (0..1); both #rrggbb. Anything else returns `color`.
function mix(color, base, amount) {
  const rgb = (h) => (/^#[0-9a-f]{6}/i.test(h ?? "") ? [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)) : null);
  const a = rgb(color), b = rgb(base);
  if (!a || !b) return color;
  return "#" + a.map((v, i) => Math.round(v * amount + b[i] * (1 - amount)).toString(16).padStart(2, "0")).join("");
}

// A project's color as drawn; "Other", and a project my-spaces hasn't given a color yet, are dim.
function fill(project, t) {
  const color = project ? (shared("project.colors") ?? {})[project] : null;
  if (!color) return t.dim;
  return color.startsWith("#") ? color : (MARK[color] ?? t[color]);
}

// A dot in the project's color and its name in bold SF Pro (Herdr's Geist draws no bold); no count, as
// its sessions are listed under it.
// The active project has a larger dot in a tinted ring and its name in its color; the name keeps its
// font and size, so switching projects moves no text. `base` is the surface the header sits on.
function projectHeader(project, fill, active, t, base) {
  // The dot's slot is as wide as the active dot, so the names line up; the ring draws past it.
  const dot = h_flex().w(10).h(10).flex_none().items_center().justify_center()
    .child(active
      ? h_flex().size(16).flex_none().rounded(8).bg(mix(fill, base, 0.3)).items_center().justify_center()
          .child(div().size(10).rounded(5).bg(fill))
      : div().size(8).rounded(4).bg(fill));
  return h_flex().id(`project-${project ?? "other"}`).h(32).flex_none().pt(8).px(8).gap(8).items_center()
    .child(dot)
    .child(div().flex_1().min_w(0).truncate().font_family("SF Pro").font_bold().text_size(12)
      .text_color(active ? fill : t.muted).child(project ?? "Other"));
}

export default class ClaudeUsage extends View {
  init(_props, cx) {
    this.limits = {}; this.context = {}; this.sessions = {}; this.shownKey = "";
    this.button = Boolean(props()?.button);
    if (checking()) return;
    if (this.button) this.registerPanel();
    this.refresh(cx);
    cx.timer.every(5000, (cx) => this.refresh(cx));
  }

  // Redraws only when a number changed or a minute passed (the countdowns), not on every poll.
  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const limits = {}, context = {};
        let sessions = {};
        for (const name of Object.keys(LIMITS)) limits[name] = await readLimit(name);
        if (!this.button) {
          for (const a of agents().filter(isClaude)) context[a.address] = await readContext(a.address);
          try { sessions = JSON.parse(await readTextFile(LIVE()) ?? "{}") ?? {}; } catch {}
        }
        const key = JSON.stringify([limits, context, sessions, Math.floor(Date.now() / 60000)]);
        if (key === this.shownKey) return;
        this.shownKey = key; this.limits = limits; this.context = context; this.sessions = sessions;
        cx.notify();
      } finally { this.loading = false; }
    });
  }

  // The tab bar remembers the open panel per space, but only restores panels listed in
  // "workspace.panels" (its default: files and changes).
  registerPanel() {
    const panels = shared("workspace.panels") ?? ["files", "changes"];
    if (!panels.includes("usage")) setShared("workspace.panels", [...panels, "usage"]);
  }

  // `pace` marks how far the window is in time: usage left of it is under pace.
  bar(id, pct, color, t, pace) {
    return div().id(id).relative().w_full().h(6).rounded(3).bg(t.raised)
      .child(div().absolute().top(0).left(0).h_full().rounded(3).bg(color).w(`${Math.min(100, Math.max(0, pct))}%`))
      .when(pace !== undefined, (el) => el.child(div().absolute().top(-2).h(10).w(2).rounded(1).bg(t.muted).left(`${pace}%`)));
  }

  // Columns shared by the limit and context rows, so their percentages and times line up.
  // Context rows have no label: their folder is on the line above.
  row(id, t, { label, pct, color, pace, right }) {
    return h_flex().id(id).h(28).gap(12).items_center().min_w(0)
      .when(label != null, (el) => el.child(div().w(64).flex_none().truncate().child(label)))
      .child(div().flex_1().min_w(0).child(this.bar(`${id}-bar`, pct ?? 0, color, t, pace)))
      .child(div().w(40).flex_none().text_right().font_semibold().text_color(color).child(pct == null ? "–" : `${pct}%`))
      .child(div().w(52).flex_none().text_right().text_size(11).text_color(t.muted).child(right ?? ""));
  }

  // Flat sections on the panel itself, split by a line like the header's, so rows sit one level deep.
  section(t, title, rows, { first = false, gap = 6 } = {}) {
    return v_flex().gap(gap).px(10).pt(16).pb(14).when(!first, (el) => el.border_t(1).border_color(t.border))
      .child(div().px(10).pb(4).text_size(11).text_color(t.muted).child(title))
      .children(rows);
  }

  limitRow(name, t) {
    const spec = LIMITS[name], data = this.limits[name];
    const row = h_flex().id(`limit-${name}`).px(10).rounded(6);
    if (!data) return row.child(this.row(`limit-${name}-row`, t, { label: spec.title, color: t.dim }));
    const elapsed = 100 * (1 - (data.reset - Date.now() / 1000) / spec.seconds);
    return row.tooltip(`Resets ${resetText(data.reset)}`).child(div().flex_1().min_w(0).child(this.row(`limit-${name}-row`, t, {
      label: spec.title, pct: data.pct, color: levelColor(level(data.pct, spec), t),
      pace: Math.max(0, Math.min(100, elapsed)), right: untilText(data.reset),
    })));
  }

  // Claude sessions under their work session, under its project: projects in the order they first appear,
  // sessions in no project last, under "Other". The project holding the active work session is the
  // active one, as in the sidebar.
  contextGroups(claudes, t) {
    const projects = new Map();
    for (const a of claudes) {
      const project = this.sessions[a.space]?.project ?? null;
      if (!projects.has(project)) projects.set(project, new Map());
      const spaces = projects.get(project);
      if (!spaces.has(a.space)) spaces.set(a.space, []);
      spaces.get(a.space).push(a);
    }
    const order = [...projects.keys()].filter((p) => p !== null);
    if (projects.has(null)) order.push(null);
    const activeSpace = spaces().find((s) => s.active)?.id;
    return order.flatMap((project) => {
      const groups = [...projects.get(project).entries()];
      const color = fill(project, t);
      const active = groups.some(([space]) => space === activeSpace);
      return [
        projectHeader(project, color, active, t, t.background),
        ...groups.flatMap(([space, list], i) => this.workSession(space, list, i > 0, t)),
      ];
    });
  }

  // A work session with one Claude session is one row: its title and the folder above the bar. With more,
  // its title gets a row of its own and each Claude session names itself: its own title, even when it
  // repeats the work session's, and its folder.
  workSession(space, list, spaced, t) {
    const title = list[0].space_name;
    if (list.length === 1) return [this.contextRow(list[0], t, { title, spaced })];
    return [
      h_flex().id(`work-${space}`).h(26).flex_none().pl(26).pr(8).items_center().when(spaced, (el) => el.mt(6))
        .child(div().min_w(0).truncate().child(title)),
      ...list.map((a) => this.contextRow(a, t, { title: claudeTitle(a), muted: true })),
    ];
  }

  // A Claude session: `title · folder` above its context bar. The title is the work session's (foreground)
  // or the Claude session's own (muted); the folder stays whole and a long title truncates.
  contextRow(a, t, { title, muted = false, spaced = false }) {
    const c = this.context[a.address], used = c?.used == null ? null : Math.round(c.used);
    const own = claudeTitle(a), folder = folderOf(a);
    // A work session nobody named carries its folder's name: the folder isn't repeated after it.
    if (title === folder) title = null;
    const tip = [!muted && own && own !== title ? own : null, c?.tokens && c?.size ? `${tokensText(c.tokens)} / ${tokensText(c.size)} tokens` : null, c?.model]
      .filter(Boolean).join(" · ");
    return v_flex().id(`ctx-${a.address}`).flex_none().pl(26).pr(8).py(2).rounded(8).cursor_pointer()
      .when(spaced, (el) => el.mt(6))
      .when(a.focused, (el) => el.bg(t.selected)).hover((s) => s.bg(t.hover))
      .when(Boolean(tip), (el) => el.tooltip(tip))
      .on_click(() => run("pane.focus", { pane: a.pane }))
      .child(h_flex().h(muted ? 20 : 24).gap(6).min_w(0).when(muted, (el) => el.items_end()).when(!muted, (el) => el.items_center())
        .when(Boolean(title), (el) => el
          .child(div().flex_shrink(1).min_w(0).truncate().text_color(muted ? t.muted : t.foreground).child(title))
          .child(div().flex_none().text_color(t.muted).child("·")))
        .child(div().flex_none().max_w(160).truncate().text_color(title || muted ? t.muted : t.foreground).child(folder)))
      .child(this.row(`ctx-${a.address}-row`, t, {
        pct: used, color: used == null ? t.dim : levelColor(level(used, CONTEXT), t),
        right: c?.tokens ? tokensText(c.tokens) : "",
      }));
  }

  // The tab bar button: toggles the usage panel like Files and Changes, and shows the 5-hour window.
  renderButton(t) {
    const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
    const on = panel && !panel.hidden && body?.active === "usage", five = this.limits.five;
    const logo = logoColor(five, settings().dark);
    return h_flex().size_full().pr(10).justify_end().items_center().bg(t.chrome).border_b(1).border_color(t.border)
      // 8, not the tabs mod's 6: at 6 this block draws visibly sharper corners than the Changes button.
      .child(h_flex().id("panel-usage").h(26).px(8).gap(5).flex_none().items_center().rounded(8)
        .text_size(12).bg(on ? t.selected : t.chrome).text_color(on ? t.foreground : t.muted)
        .hover((s) => s.bg(t.hover)).on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => {
          if (on) run("layout.hide", { id: "panel" });
          else { run("layout.select", { stack: "panel-body", child: "usage" }); run("layout.show", { id: "panel" }); }
        })
        // One color for logo, percentage and time: the button reads as one mark.
        .child(div().text_size(14).text_color(logo).child("✻"))
        .when(!five, (el) => el.child("Usage"))
        .when(Boolean(five), (el) => el.child(div().font_semibold().text_color(logo).child(`${five.pct}%`))
          .child(div().text_size(11).text_color(logo).child(untilText(five.reset)))));
  }

  render() {
    const t = theme();
    if (this.button) return this.renderButton(t);
    const claudes = agents().filter(isClaude);
    return v_flex().id("claude-usage").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background)
      .border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().text_size(14).text_color(logoColor(this.limits.five, settings().dark)).child("✻"))
        .child(div().font_semibold().child("Claude usage")))
      .child(v_flex().id("claude-usage-body").flex_1().min_h(0).overflow_y_scrollbar()
        .child(this.section(t, "Limits", [this.limitRow("five", t), this.limitRow("week", t)], { first: true }))
        .child(this.section(t, "Context", claudes.length ? this.contextGroups(claudes, t)
          : [div().px(8).text_size(11).text_color(t.dim).child("No Claude sessions running")], { gap: 0 })));
  }
}
