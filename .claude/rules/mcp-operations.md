# MCP operations: look up once, then call directly

Some MCP servers (Atlassian, and others with a `discover` + `execute` pattern) hide their operations behind a search tool. Each search costs a round trip and returns several full operation descriptions when only one name is needed.

- Before searching, check the list below. A listed operation is called directly with the inputs shown.
- After searching for an operation that will be used again, add it here with its exact name, execute tool and inputs, and note the date.
- When a listed call fails with an unknown operation or an input validation error, search again and fix the entry here.
- Ask for small responses (`responseFields` or the server's equivalent).

**Why:** I noticed the same search running every time for routine actions (open a PR, mark it draft). One verified list saves that cost in every project.

## Atlassian MCP: Bitbucket

Deferred tools: load `mcp__claude_ai_Atlassian__executeRead` / `executeWrite` with ToolSearch (`discover` only when needed). Bitbucket operations need no cloudId. Workspace `agxeed`. All take `workspaceId`, `repoId`; pull request operations take `prId` (a number, exact key).

Verified 2026-10-29:
- `createBitbucketRepoPullRequest` (executeWrite): `title`, `sourceBranch`, `targetBranch`, `description`, `draft`, `closeSourceBranch`, `reviewers` [{uuid | account_id | username}]. Adds no default reviewers.
- `updateBitbucketRepoPullRequest` (executeWrite): `prId` plus any of `title`, `description`, `targetBranch`, `reviewers`, `closeSourceBranch`, `draft`.
- `addBitbucketRepoPullRequestComment` (executeWrite): `prId`, `content` (markdown), optional `parentCommentId`, `pending`, `inlinePath`, `inlineToLine` / `inlineFromLine`.
- `updateBitbucketRepoPullRequestComment` (executeWrite): `prId`, `commentId`, `content`.
- `createBitbucketRepoPullRequestTask` (executeWrite): `prId`, `taskContent`, optional `parentCommentId`.
- `approveBitbucketRepoPullRequest` (executeWrite): `prId` only (verified 2026-10-30).

Verified 2026-10-29:
- `listBitbucketRepoPullRequestComments` (executeRead): `prId`, optional `page`, `pagelen`. Deleted comments stay in the list with `deleted: true`.
- There is no operation to delete a pull request comment; delete it in the Bitbucket UI.

Verified 2026-10-30 (pipelines):
- `runBitbucketRepoPipeline` (executeWrite): `target` {`ref_type`: "branch", `ref_name`}, `selector` {`type`: "custom", `pattern`: "<custom pipeline name>"}, `variables` [{`key`, `value`, `secured`?}]. Returns `build_number`.
- `listBitbucketRepoPipelines` (executeRead): `targetBranch`, `sort` ("-created_on"), `pagelen`. Fields: `values.build_number`, `values.state.name`, `values.state.result.name`.
- `listBitbucketRepoPipelineSteps` (executeRead): `pipelineId` (build number as a string, e.g. "832"; a number fails validation, checked 2026-11-12). Fields: `values.name`, `values.uuid`, `values.state.result.name`.
- `getBitbucketRepoPipelineStepLog` (executeRead): `pipelineId`, `stepUuid` ("{...}" form).

Names seen, inputs not verified yet (executeRead): `getBitbucketRepoPullRequest`, `listBitbucketRepoPullRequests`, `getBitbucketRepoPullRequestDiff`, `listBitbucketRepoPullRequestTasks`.

Useful `responseFields`: `["id", "draft", "links.html.href", "summary.html"]`. `summary.html` shows how a description renders.
