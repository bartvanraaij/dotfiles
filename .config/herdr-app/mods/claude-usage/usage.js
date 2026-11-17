// Claude Code usage as ~/.claude/statusline.sh records it: plan limits per account, context per terminal.
import { home, readTextFile } from "herdr";

// warn/crit: the used percentage where "getting tight" and "critical" start.
// The 5-hour critical threshold matches the red in ~/.config/tmux/claude-usage.sh.
export const LIMITS = {
  five: { title: "5 hours", file: ".cache/claude-usage", seconds: 5 * 3600, warn: 70, crit: 90 },
  week: { title: "Week", file: ".cache/claude-usage-7d", seconds: 7 * 24 * 3600, warn: 70, crit: 90 },
};
// Claude Code compacts the context by itself near the end of the window.
export const CONTEXT = { warn: 50, crit: 75 };

export const level = (pct, { warn, crit }) => (pct >= crit ? "crit" : pct >= warn ? "warn" : "good");
export const levelColor = (lvl, t) => ({ good: t.ansi2, warn: t.ansi3, crit: t.ansi1 })[lvl];

// "<used_percentage> <resets_at>", or null when missing or when the window has reset since.
export async function readLimit(name) {
  const text = await readTextFile(`${home()}/${LIMITS[name].file}`).catch(() => null);
  const [pct, reset] = (text ?? "").trim().split(/\s+/).map(Number);
  if (!Number.isFinite(pct) || !Number.isFinite(reset) || reset * 1000 <= Date.now()) return null;
  return { pct: Math.round(pct), reset };
}

// {used, tokens, size, model} for a Herdr terminal address, or null.
export async function readContext(address) {
  const text = await readTextFile(`${home()}/.cache/claude-context/${address}`).catch(() => null);
  try { return text ? JSON.parse(text) : null; } catch { return null; }
}

export function untilText(reset) {
  const left = Math.max(0, Math.floor(reset - Date.now() / 1000));
  const d = Math.floor(left / 86400), h = Math.floor((left % 86400) / 3600), m = Math.floor((left % 3600) / 60);
  return d ? `${d}d ${h}h` : h ? `${h}h${m}m` : `${m}m`;
}

export function resetText(reset) {
  const at = new Date(reset * 1000), today = new Date().toDateString() === at.toDateString();
  const time = `${String(at.getHours()).padStart(2, "0")}:${String(at.getMinutes()).padStart(2, "0")}`;
  return today ? time : `${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][at.getDay()]} ${time}`;
}

export const tokensText = (n) =>
  n >= 1e6 ? `${+(n / 1e6).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}k` : String(n);

// The ✻ logo: Claude orange, red from the 5-hour critical threshold. Same colors as ~/.config/tmux/claude-usage.sh.
export function logoColor(five, dark) {
  const crit = five && five.pct >= LIMITS.five.crit;
  return dark ? (crit ? "#f85149" : "#d97757") : (crit ? "#cf222e" : "#c15f3c");
}
