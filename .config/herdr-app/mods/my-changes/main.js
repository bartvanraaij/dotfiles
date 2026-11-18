import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, v_virtual_list } from "gpui-base";
import { spaces, panes, focused, exec, watchFolder, theme, settings, home } from "herdr";

// Dotfiles: a bare repo in ~/.dot with $HOME as its work tree (the `dot` alias). Folders under home that
// are in no other repo show its changes. Only tracked files count: everything else in home is untracked.
const dotfiles = () => ["--git-dir", `${home()}/.dot`, "--work-tree", home()];
const inHome = (cwd) => cwd === home() || cwd.startsWith(`${home()}/`);

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}
const key = () => JSON.stringify(location());
// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie):
// the folder watch would see it, and every refresh would start the next one.
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
// The diff uses the terminal's font, size and weight; rows get the terminal's line height on top of a 1.5 base.
const diffFont = () => {
  const s = settings(), size = Number(s.font_size) || 14;
  return {
    // settings() doesn't report font_weight; 400 is the weight settings.json sets for the terminals.
    family: s.font_family ?? "JetBrains Mono", size, weight: Number(s.font_weight) || 400,
    row: Math.ceil(size * 1.5 * (Number(s.terminal_line_height) || 1)),
  };
};
// GitHub's diff colors (Primer diffBlob tokens), light and dark: line, line-number gutter and hunk header.
const DIFF_COLORS = {
  light: { add: "#dafbe1", addGutter: "#aceebb", del: "#ffebe9", delGutter: "#ffcecb", hunk: "#ddf4ff", hunkText: "#59636e" },
  dark: { add: "#2ea04326", addGutter: "#3fb9504d", del: "#f8514926", delGutter: "#f851494d", hunk: "#388bfd1a", hunkText: "#9198a1" },
};

// Text draws a tab as nothing: pad each to the next 4-column stop.
const untab = (text) => text.replace(/[^\t]*\t/g, (s) => s.slice(0, -1).padEnd((s.length - 1) - (s.length - 1) % 4 + 4));

// Syntax highlighting comes from delta in --color-only mode: it colors the diff without changing a line.
// git gives the whole file as context, so delta sees every line and multi-line constructs (block comments,
// code fences) color right; trimContext then cuts the context back to CONTEXT lines around each change.
// delta uses bat's themes: GitHub is light only, the dark side uses the closest built-in. Markdown gets
// GitHub's markdown colors from ~/.config/bat/themes/github-markdown-*.tmTheme (the GitHub theme leaves it plain).
const SYNTAX_THEME = { light: "GitHub", dark: "Visual Studio Dark+" };
const MARKDOWN_THEME = { light: "github-markdown-light", dark: "github-markdown-dark" };
const isMarkdown = (path) => /\.(md|markdown|mdx)$/i.test(path);
const CONTEXT = 3;
const DELTA = 'theme=$1 mode=$2; shift 2; "$@" | delta --no-gitconfig --color-only --syntax-theme="$theme" "--$mode" ' +
  "--true-color=always --plus-style=syntax --minus-style=syntax --zero-style=syntax --max-line-length=0 --tabs=0";
const ANSI = /\x1b\[[0-9;]*m/g;

// delta's ANSI output as lines of {text, color, bold, italic, underline} spans; backgrounds are dropped.
function parseAnsi(out) {
  return out.replace(/\n$/, "").split("\n").map((line) => {
    const spans = [];
    let color = null, bold = false, italic = false, underline = false;
    for (const part of line.split(/(\x1b\[[0-9;]*m)/)) {
      const sgr = /^\x1b\[([0-9;]*)m$/.exec(part);
      if (!sgr) { if (part) spans.push({ text: part, color, bold, italic, underline }); continue; }
      const p = sgr[1].split(";").map(Number);
      for (let i = 0; i < p.length; i++) {
        if (p[i] === 0) { color = null; bold = italic = underline = false; }
        else if (p[i] === 39) color = null;
        else if (p[i] === 1 || p[i] === 22) bold = p[i] === 1;
        else if (p[i] === 3 || p[i] === 23) italic = p[i] === 3;
        else if (p[i] === 4 || p[i] === 24) underline = p[i] === 4;
        else if (p[i] === 38 && p[i + 1] === 2) { color = "#" + p.slice(i + 2, i + 5).map((n) => n.toString(16).padStart(2, "0")).join(""); i += 4; }
        else if (p[i] === 38 && p[i + 1] === 5) i += 2;
      }
    }
    return spans;
  });
}

// Drops the diff marker (+, -, space) from a line's spans and expands tabs the way untab does.
function spanText(spans) {
  const out = [];
  let col = 0, skip = 1;
  for (const sp of spans) {
    let text = sp.text;
    if (skip) { const n = Math.min(skip, text.length); text = text.slice(n); skip -= n; }
    let res = "";
    const start = col;
    for (const ch of text) {
      if (ch === "\t") { const pad = 4 - col % 4; res += " ".repeat(pad); col += pad; } else { res += ch; col++; }
    }
    if (res) out.push({ ...sp, text: res, col: start });
  }
  return out;
}

// Cuts a whole-file hunk back to `context` lines around each change, with fresh @@ headers.
// `lines` starts at the single @@ line; `spans` runs parallel to it.
function trimContext(lines, spans, context) {
  const head = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(lines[0]);
  if (!head) return { lines, spans };
  let old = +head[1], next = +head[2];
  const body = lines.slice(1).map((line, i) => {
    const kind = line[0], at = { line, spans: spans[i + 1], kind, old, next };
    if (kind === "-") old++; else if (kind === "+") next++; else if (kind === " ") { old++; next++; }
    return at;
  });
  const keep = body.map(() => false);
  body.forEach((b, i) => {
    if (b.kind !== "-" && b.kind !== "+") return;
    for (let j = Math.max(0, i - context); j <= Math.min(body.length - 1, i + context); j++) keep[j] = true;
  });
  // "\ No newline at end of file" belongs to the line before it.
  body.forEach((b, i) => { if (b.kind === "\\" && i > 0 && keep[i - 1]) keep[i] = true; });
  const outLines = [], outSpans = [];
  for (let i = 0; i < body.length; ) {
    if (!keep[i]) { i++; continue; }
    let j = i;
    while (j < body.length && keep[j]) j++;
    const group = body.slice(i, j), count = (k) => group.filter((b) => b.kind === k || b.kind === " ").length;
    outLines.push(`@@ -${group[0].old},${count("-")} +${group[0].next},${count("+")} @@`); outSpans.push(null);
    for (const b of group) { outLines.push(b.line); outSpans.push(b.spans); }
    i = j;
  }
  return { lines: outLines, spans: outSpans };
}

// Numbers each diff line once, so a frame only draws the rows on screen.
function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, number: old++, text: untab(line.slice(1)) || " " };
    if (kind === "+") return { kind, number: next++, text: untab(line.slice(1)) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: untab(line.slice(1)) || " " }; }
    return { kind: "", text: line };
  });
}

export default class Changes extends View {
  init(_props, cx) {
    this.files = []; this.repo = []; this.rows = []; this.diffWidth = 0; this.message = ""; this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Commit message" });
    this.input.on("change", (_e, cx) => {
      const hadMessage = Boolean(this.message.trim());
      this.message = this.input.value();
      if (hadMessage !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.commit(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
  }

  watch(root, cx) {
    // A dotfiles root is all of home: too big to watch; the 10-second refresh covers it.
    if (this.on || this.repo.length || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched === root) this.refresh(cx);
        }
      } catch { this.watched = null; }
    });
  }

  refresh(cx) {
    if (this.loading || this.busy) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) {
      this.context = context; this.root = null; this.files = []; this.open = null;
      this.setLines([]); this.message = ""; this.input.set_value(""); this.error = null; this.note = null; this.watched = null; this.closed = false; this.limited = false;
    }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        let root = top.stdout.trim(), repo = [];
        if (top.code !== 0 && !on && inHome(cwd)) {
          const dot = await exec("git", [...dotfiles(), "rev-parse", "--git-dir"], { cwd });
          if (key() !== context) return;
          if (dot.code === 0) { root = home(); repo = dotfiles(); }
        }
        if (!root) { this.root = null; this.files = []; this.setLines([]); this.open = null; this.error = "Not a git repository"; return; }
        const git = (args) => exec("git", [...READ, ...repo, ...args], { cwd: root, on });
        const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", `--untracked-files=${repo.length ? "no" : "all"}`]);
        if (status.code !== 0) throw new Error(status.stderr);
        const head = await git(["rev-parse", "--verify", "HEAD"]);
        const stats = {};
        const results = head.code === 0 ? [await git(["diff", "HEAD", "--numstat", "-z", "--no-renames"])] : [await git(["diff", "--cached", "--numstat", "-z", "--no-renames"]), await git(["diff", "--numstat", "-z", "--no-renames"])];
        for (const result of results) {
          if (result.code !== 0) throw new Error(result.stderr);
          for (const entry of result.stdout.split("\0")) {
            const [a, d, ...parts] = entry.split("\t");
            if (!parts.length) continue;
            const path = parts.join("\t"), old = stats[path] ?? { add: 0, del: 0 };
            stats[path] = { add: old.add + (Number(a) || 0), del: old.del + (Number(d) || 0), binary: a === "-" };
          }
        }
        const files = [];
        const entries = status.stdout.split("\0").filter(Boolean);
        for (const entry of entries.slice(0, 1000)) {
          const xy = entry.slice(0, 2), path = entry.slice(3), fresh = xy === "??";
          const conflict = xy.includes("U") || xy === "AA" || xy === "DD";
          const s = conflict ? "U" : xy.includes("D") ? "D" : fresh || xy.includes("A") ? "A" : "M";
          const stat = stats[path] ?? { add: 0, del: 0 };
          files.push({ path, status: s, fresh, ...stat });
        }
        if (key() !== context) return;
        this.root = root; this.repo = repo; this.on = on; this.hasHead = head.code === 0; this.files = files; this.limited = entries.length > 1000; this.error = null;
        this.watch(root, cx);
        if (this.open && !files.some((f) => f.path === this.open)) { this.open = null; this.setLines([]); }
        // The first file's diff shows until you pick another.
        if (!this.open && !this.closed && files.length) this.open = files[0].path;
        if (this.open) {
          try { await this.load(this.open, context); }
          catch { if (key() === context) this.setLines(["Cannot preview this diff (too large or unreadable)"]); }
        }
      } catch (e) { if (key() === context) this.error = String(e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  async load(path, context) {
    const file = this.files.find((f) => f.path === path), root = this.root, on = this.on;
    if (!file) return;
    const fresh = file.fresh || (!this.hasHead && file.status === "A");
    const diff = fresh
      ? ["git", "diff", "--no-index", "--no-ext-diff", "--no-color", `-U${1e6}`, "--", "/dev/null", path]
      : ["git", ...READ, ...this.repo, "diff", ...(this.hasHead ? ["HEAD"] : []), "--no-ext-diff", "--no-textconv", "--no-color", `-U${1e6}`, "--", path];
    const dark = settings().dark, theme = (isMarkdown(path) ? MARKDOWN_THEME : SYNTAX_THEME)[dark ? "dark" : "light"];
    const coloring = exec("sh", ["-c", DELTA, "sh", theme, dark ? "dark" : "light", ...diff], { cwd: root, on }).catch(() => null);
    const out = await coloring;
    if (out?.stdout.includes("@@")) return this.present(file, fresh, out, true, path, context);
    // delta missing or failing (a remote machine): the plain diff, uncolored.
    const plain = await exec(diff[0], diff.slice(1), { cwd: root, on });
    // git diff --no-index exits 1 when the files differ.
    if (plain.code > (fresh ? 1 : 0)) throw new Error(plain.stderr);
    this.present(file, fresh, plain, false, path, context);
  }

  present(file, fresh, out, colored, path, context) {
    if (key() !== context || this.open !== path) return;
    const all = out.stdout.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.replace(ANSI, "").startsWith("@@"));
    let lines, spans = null;
    if (first < 0) lines = [file.binary ? "Binary file changed" : fresh ? "Binary file · no text diff" : "No text diff available"];
    else {
      const raw = all.slice(first);
      const trimmed = trimContext(raw.map((l) => l.replace(ANSI, "")), colored ? parseAnsi(raw.join("\n")) : [], CONTEXT);
      lines = trimmed.lines; spans = colored ? trimmed.spans : null;
      if (fresh) file.add = lines.filter((l) => l[0] === "+").length;
    }
    const long = (line) => line.length > 4000;
    this.setLines(lines.slice(0, 1500).map((line) => long(line) ? line.slice(0, 4000) + "… (line truncated)" : line),
      spans && spans.slice(0, 1500).map((sp, i) => long(lines[i]) ? null : sp));
  }

  setLines(lines, spans = null) {
    this.rows = diffRows(lines);
    // A row keeps its spans only when they spell its exact text, so a mismatch falls back to plain.
    if (spans) this.rows.forEach((row, i) => {
      const own = row.kind && row.kind !== "@" && spans[i] ? spanText(spans[i]) : null;
      if (own && own.map((sp) => sp.text).join("") === row.text) row.spans = own;
    });
    this.diffWidth = Math.max(300, ...this.rows.map(row => (row.text.length + 1) * diffFont().size * 0.6 + 50));
  }

  pick(path, cx) {
    this.open = this.open === path ? null : path; this.setLines([]); this.note = null;
    this.closed = !this.open;
    const context = this.context;
    if (this.open) cx.spawn(async (cx) => {
      try { await this.load(path, context); }
      catch (e) { if (key() === context && this.open === path) this.note = `Cannot preview this diff (too large or unreadable): ${e}`; }
      cx.notify();
    });
    cx.notify();
  }

  commit(cx) {
    if (!this.message.trim() || !this.root || this.busy || this.loading || this.context !== key()) return;
    const root = this.root, repo = this.repo, on = this.on, context = this.context, message = this.message.trim();
    this.busy = true; this.note = null;
    cx.spawn(async (cx) => {
      try {
        // Dotfiles stage tracked files only: `add -A` would add all of home.
        for (const args of [[...repo, "add", repo.length ? "-u" : "-A"], [...repo, "commit", "-m", message]]) {
          const r = await exec("git", args, { cwd: root, on });
          if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim());
        }
        if (key() === context) { this.message = ""; this.input.set_value(""); }
      } catch (e) { if (key() === context) this.note = `Commit failed: ${e}`; }
      finally { this.busy = false; this.refresh(cx); cx.notify(); }
    });
    cx.notify();
  }

  diffRow({ kind, number, text, spans }, t) {
    const h = diffFont().row, c = DIFF_COLORS[settings().dark ? "dark" : "light"];
    if (kind === "@") return div().w_full().px(12).h(h).flex_none().truncate().bg(c.hunk).text_color(c.hunkText).child(text);
    const line = kind === "+" ? c.add : kind === "-" ? c.del : null, gutter = kind === "+" ? c.addGutter : kind === "-" ? c.delGutter : null;
    return h_flex().w_full().h(h).flex_none().when(Boolean(line), (e) => e.bg(line))
      .child(div().w(40).h_full().flex_none().flex().items_center().justify_end().pr(8).text_color(t.dim).when(Boolean(gutter), (e) => e.bg(gutter))
        .child(number === undefined ? "" : String(number)))
      // Each span sits at its column times the measured cell width: laid out side by side, every span
      // rounds its own width, and the line shifts a few pixels against the plain text drawn before it.
      .child(spans && this.cell
        ? div().flex_1().min_w(0).h_full().relative().overflow_hidden().children(spans.map((sp) => div().absolute().top(0).bottom(0).left(10 + sp.col * this.cell)
          .flex().items_center().whitespace_nowrap().when(Boolean(sp.color), (e) => e.text_color(sp.color))
          .when(sp.bold, (e) => e.font_bold()).when(sp.italic, (e) => e.italic()).when(sp.underline, (e) => e.underline()).child(sp.text)))
        : div().flex_1().min_w(0).pl(10).truncate().child(text));
  }

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), add = this.files.reduce((n, f) => n + f.add, 0), del = this.files.reduce((n, f) => n + f.del, 0);
    const enabled = Boolean(this.message.trim() && this.root && !this.busy && !this.loading);
    return v_flex().id("changes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Changes"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${this.files.length} files`))
        .when(Boolean(this.root && this.repo.length), (e) => e.child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child("dotfiles")))
        .child(div().flex_1()).child(div().text_size(11).text_color(t.ansi2).child(`+${add}`)).child(div().text_size(11).text_color(t.ansi1).child(`−${del}`)))
      // overflow_y_scrollbar() wraps the list, so its flex sizing never reached the panel's layout.
      .child(div().flex_1().min_h(44).max_h(this.files.length * 28 + 12).relative().border_b(1).border_color(t.border)
        .child(v_flex().id("changes-list").absolute().inset_0().overflow_y_scroll().p(6).children(this.files.map((f) => {
        const parts = f.path.split("/"), name = parts.pop();
        return h_flex().id(`change-${f.path}`).h(28).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().when(this.open === f.path, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pick(f.path, cx))
          .child(div().w(14).text_size(11).text_color(f.status === "A" ? t.ansi2 : f.status === "D" ? t.ansi1 : f.status === "U" ? t.ansi1 : t.blocked).child(f.status))
          .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().max_w(260).min_w(0).truncate().child(name)))
          .when(f.add > 0, (e) => e.child(div().text_size(11).text_color(t.ansi2).child(`+${f.add}`))).when(f.del > 0, (e) => e.child(div().text_size(11).text_color(t.ansi1).child(`−${f.del}`)));
      })).when(!this.files.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.error || (this.loading ? "Loading changes…" : this.root ? "No uncommitted changes" : "No folder")))))
        .child(Scrollbar.vertical("changes-list").absolute().inset_0()))
      .when(this.limited, el => el.child(div().px(12).py(4).text_size(11).text_color(t.dim).child("Showing the first 1,000 changed files")))
      .child(div().flex_1().min_h(0).relative().font_family(diffFont().family).text_size(diffFont().size).font_weight(diffFont().weight)
        // The diff font's cell width, from 100 drawn characters, for placing colored spans.
        .child(div().id("diff-cell").absolute().top(0).left(0).invisible().whitespace_nowrap().child("0".repeat(100))
          .on_size_change((size, cx) => { if (size.width / 100 !== this.cell) { this.cell = size.width / 100; cx.notify(); } }))
        .child(div().id("changes-diff-x").size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.diffWidth).h_full().child(v_virtual_list("changes-diff", this.rows.length, diffFont().row, (i) => String(i),
            (range) => this.rows.slice(range.start, range.end).map((row) => this.diffRow(row, t))).size_full())))
        .child(Scrollbar.vertical("changes-diff").viewport_from_layout().absolute().inset_0())
        .when(!this.open && this.files.length > 0, (e) => e.child(div().absolute().top(6).px(12).text_color(t.dim).child("Select a file to view its changes"))))
      .when(Boolean(this.note), (e) => e.child(div().px(10).pb(8).text_size(11).text_color(t.ansi1).child(this.note)))
      .child(h_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(div().id("commit-message").flex_1().min_w(0).h(32).px(10).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
        .child(div().id("commit").h(32).px(14).flex().items_center().rounded(8).bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim).text_size(12).when(enabled, (e) => e.cursor_pointer()).on_click((_e, cx) => this.commit(cx)).child(this.busy ? "Committing…" : "Commit")));
  }
}
