import { githubApi } from "./github";

async function setCommitStatus(
  state: string,
  description: string,
  targetUrl: string,
): Promise<void> {
  const repo = process.env.GITHUB_REPOSITORY || "";
  const sha = process.env.INPUT_SHA || "";
  const context = process.env.INPUT_CONTEXT || "Preview";

  await githubApi("POST", `/repos/${repo}/statuses/${sha}`, {
    state,
    description,
    target_url: targetUrl,
    context,
  });

  console.log(`Set commit status: ${state} - ${description}`);
}

const state = process.argv[2];
const description = process.argv[3];
const targetUrl = process.argv[4];

if (!state) {
  console.error("Usage: status.ts <state> <description> <target_url>");
  process.exit(1);
}

setCommitStatus(state, description, targetUrl).catch((err) => {
  console.error(err);
  process.exit(1);
});
