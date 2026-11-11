# Git, PR and review conventions

## Commits
- Only commit or push when I ask. Never auto-commit while brainstorming, planning or implementing.
- New work while a PR is open: ask "same PR/branch, or a new branch (which ticket)?" before the first commit. Don't assume either way.
- One-line messages only. No body paragraphs. The one exception is a `Co-Authored-By:` trailer when an AI agent co-authored the commit.
- Format: `type(TICKET-123): Verb noun phrase`
  - Types: feat, fix, refactor, perf, test, docs, build, ci, chore, revert. Breaking change: `feat(TICKET-123)!: ...`
  - Ticket key in uppercase, exactly as in the tracker. Don't know the ticket? Ask. Don't invent one or drop the scope.
  - Start with a capitalized imperative verb, rest in sentence case, no trailing period. Never gerunds ("Adding") or past tense ("Added").
  - The verb doesn't echo the type: `fix(X-1): Prevent crash on empty upload`, not `fix(X-1): Fix crash`.
  - The subject names what the commit changes, never why it exists: `Remove the config entry type annotation`, not `Apply review feedback`. A commit with two unrelated changes gets split, so each subject can name its change.
- Splitting: every commit must build ("no red intermediates"). Group by layer or coherent unit when signatures ripple; one docs commit at the end is fine.
- Why: commit bodies never get read. The subject carries everything, the type makes the log filterable, and the ticket links the context.

## PR descriptions
- Title = the commit subject format.
- The body opens with a summary of one or two plain sentences, no heading: what the PR is about and why it is needed, the context the change lines don't carry.
- Then `This PR:` and one line per change, starting with a bold third-person verb ("**Adds**", "**Fixes**", "**Moves**"). The PR is the subject, so the verb is something the PR changes, not runtime behaviour ("Handles"). The why goes in the same sentence and names the concrete situation the reader knows. If a reviewer will obviously ask "does this affect prod?", answer it in the line. Incidental changes (docs, conventions) are just another line. No sub-bullets or paragraphs in this list.
- Below it, in this order; a part with nothing to say is left out:
    - `Details:` implementation notes per change, as plain statements ("Unwrapping is in ...").
    - `Out-of-scope:` follow-ups and known gaps, each linking its ticket where one exists.
    - `### Reviewing`, holding `What I need from you:` (numbered asks to the reviewer, including where to start reading) and `How to test:` (prerequisites in one line, then the steps as one commented code block, expected output as comments).
- The `_Co-Authored by ..._` line (see "Posting as me") ends the description.

Example:
```
Field uploads rejected a FeatureCollection holding a single Feature, the shape most GeoJSON tools (and the Outsystems export) produce.

This PR:

- **Adds** support for a FeatureCollection holding a single Feature. Multiple features get a 400.
- **Adds** PR description conventions to AGENTS.md, so AI agents follow our style.

Details:

- Unwrapping is in the shared GeoJsonFeatureConverter, so every endpoint that takes a Feature accepts it. OriginalGeoJson stores the unwrapped feature.

Out-of-scope:

- Multi-feature uploads ([JIRA-124](https://agxeed.atlassian.net/browse/JIRA-124)).

### Reviewing

What I need from you:

1. Start with GeoJsonFeatureConverter: is unwrapping there the right layer?

How to test:

    dotnet test src/tests/CoreAPI.Integration.Tests --filter FieldUploadTests
```

## Writing voice (PRs, comments, write-ups)
- No "christmas tree". Use formatting only when it helps the reader: a bold short section header, a table when people compare or scan rows, a list for separate items. No decorative italics, checkboxes, blockquotes or emoji sprinkles (a single emoji for tone is fine).
- No em-dashes. Use a comma, period, semicolon or parentheses.
- Plain English; I'm Dutch/ESL. Avoid fancy idioms ("churn", "leaks into", "net effect", "boilerplate"). Casual is fine ("super messy", "way better").
- Concrete numbers and facts over abstractions: "15-minute window", not "short period".
- Don't narrate the code as a tour ("It lives in X"). State the fact: "Handled in the shared X, so it applies to every Y."
- Bug explanations as a story: concrete example → current wrong behaviour → why it's wrong → "This PR fixes that by...".

## Posting as me (PR descriptions, comments, replies, tasks)
- The post shows under my name, so end every post with exactly `_Co-Authored by Claude <model> (Claude Code)_`, e.g. `_Co-Authored by Claude Opus 5.5 (Claude Code)_`. Always "Co-Authored", never "Generated with" or "Written by", because I may edit the text afterwards.
- Never use first person ("I", "my", "we") for work only the agent did; it reads as me. Write impersonally ("Keeping this as is, because...") or refer to Claude in third person.
- Confirm with me before posting anything I didn't explicitly ask for.
- Bitbucket (PRs, comments, tasks): use the Atlassian MCP; operation names and inputs are in `mcp-operations.md`. There's no Bitbucket CLI.
- Bitbucket markdown: put a blank line before every list, and indent nested bullets by 4 spaces (2 renders flat). After writing a description, check the rendered `summary.html`.
- In review comments, tables are welcome when they help scanning (finding / where / fix).

## Handling review feedback
- Don't implement review comments blindly. First go through them point by point: agree, partly agree or disagree, each with technical reasoning and the proposed fix. Wait for my go before changing code.
- Push back with reasons when a suggestion is wrong for this codebase, unused (YAGNI), or conflicts with an earlier decision.
- No performative agreement ("Great point!", "You're absolutely right").
- Bot review comments (Copilot, CodeRabbit) get a short text reply too, not only a code change that marks them outdated: "Good suggestion, applied in <commit>." or a one-line reason when keeping things as they are.
- When asking me several questions, label them as in `numbered-questions.md`.

## Design docs
Code comments: see `code-comments.md`.
- Design docs/ADRs: plain declaratives. State facts and don't narrate the document. Write what we DO, not what we don't. Concrete definitions you can check against a real file. No dashes as punctuation, no bold for emphasis, no rhetorical flourishes.
- Leave open questions in design docs open, even when the answer is known; they're there so colleagues think them through. Flag it once at most.
