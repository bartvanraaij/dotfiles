import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, run, theme, settings, checking, props, layout, shared, setShared } from "herdr";
import { LIMITS, CONTEXT, level, levelColor, readLimit, readContext, logoColor, untilText, resetText, tokensText } from "./usage.js";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const isClaude = (a) => a.app === "claude-code" || a.program?.key === "claude";
// Drops the status glyph Claude Code puts in front of its terminal title.
const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

export default class ClaudeUsage extends View {
  init(_props, cx) {
    this.limits = {}; this.context = {}; this.shownKey = "";
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
        for (const name of Object.keys(LIMITS)) limits[name] = await readLimit(name);
        if (!this.button) for (const a of agents().filter(isClaude)) context[a.address] = await readContext(a.address);
        const key = JSON.stringify([limits, context, Math.floor(Date.now() / 60000)]);
        if (key === this.shownKey) return;
        this.shownKey = key; this.limits = limits; this.context = context;
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

  // Columns shared by the limit and context rows, so their bars, percentages and times line up.
  row(id, t, { label, labelColor, pct, color, pace, right }) {
    return h_flex().id(id).h(28).gap(12).items_center().min_w(0)
      .child(div().w(64).flex_none().truncate().text_color(labelColor ?? t.foreground).child(label ?? ""))
      .child(div().flex_1().min_w(0).child(this.bar(`${id}-bar`, pct ?? 0, color, t, pace)))
      .child(div().w(40).flex_none().text_right().font_semibold().text_color(color).child(pct == null ? "–" : `${pct}%`))
      .child(div().w(52).flex_none().text_right().text_size(11).text_color(t.muted).child(right ?? ""));
  }

  // Flat sections on the panel itself, split by a line like the header's, so rows sit one level deep.
  section(t, title, rows, { first = false } = {}) {
    return v_flex().gap(6).px(10).pt(16).pb(14).when(!first, (el) => el.border_t(1).border_color(t.border))
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

  // Session titles are too long for the label column: the title gets its own line, the space takes the label.
  contextRow(a, t) {
    const c = this.context[a.address], used = c?.used == null ? null : Math.round(c.used);
    const tip = [c?.tokens && c?.size ? `${tokensText(c.tokens)} / ${tokensText(c.size)} tokens` : null, c?.model].filter(Boolean).join(" · ");
    return v_flex().id(`ctx-${a.address}`).px(10).pt(8).pb(4).gap(2).rounded(8).cursor_pointer()
      .when(a.focused, (el) => el.bg(t.selected)).hover((s) => s.bg(t.hover))
      .when(Boolean(tip), (el) => el.tooltip(tip))
      .on_click(() => run("pane.focus", { pane: a.pane }))
      .child(div().min_w(0).truncate().child(clean(a.title) || a.tab_name))
      .child(this.row(`ctx-${a.address}-row`, t, {
        label: a.space_name, labelColor: t.muted, pct: used, color: used == null ? t.dim : levelColor(level(used, CONTEXT), t),
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
        .child(this.section(t, "Context", claudes.length ? claudes.map((a) => this.contextRow(a, t))
          : [div().px(8).text_size(11).text_color(t.dim).child("No Claude sessions running")])));
  }
}
