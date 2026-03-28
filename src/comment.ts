import { execSync } from "child_process";
import QRCode from "qrcode";
import { githubApi } from "./github";

const COMMENT_HEADER = "<!-- Sticky Pull Request Comment pr-preview -->";

function env(name: string): string {
  return process.env[name] || "";
}

async function generateQrDataUri(url: string): Promise<string> {
  const pngBuffer = await QRCode.toBuffer(url, {
    type: "png",
    margin: 1,
    scale: 2,
  });
  try {
    const gifBuffer = execSync("convert png:- gif:-", { input: pngBuffer });
    return `data:image/gif;base64,${gifBuffer.toString("base64")}`;
  } catch {
    return `data:image/png;base64,${pngBuffer.toString("base64")}`;
  }
}

async function generateDeployComment(): Promise<string> {
  const actionVersion = env("action_version");
  const previewUrl = env("preview_url");
  const previewBranch = env("INPUT_PREVIEW_BRANCH") || "gh-pages";
  const serverUrl = env("GITHUB_SERVER_URL") || "https://github.com";
  const repository = env("GITHUB_REPOSITORY");
  const actionStartTime = env("action_start_time");
  const qrCodeInput = env("INPUT_QR_CODE");

  let qrCode = "";
  if (qrCodeInput !== "false" && qrCodeInput !== "") {
    const dataUri = await generateQrDataUri(previewUrl);
    qrCode = `<img src="${dataUri}" height="100" align="right" alt="QR code for preview link">`;
  }

  return `${COMMENT_HEADER}
[PR Preview Action](https://github.com/pazerop/pr-preview-action) ${actionVersion}
:---:
| <p>${qrCode}</p> :rocket: View preview at <br> ${previewUrl} <br><br>
| <h6>Built to branch [\`${previewBranch}\`](${serverUrl}/${repository}/tree/${previewBranch}) at ${actionStartTime}. <br> Preview is ready! <br><br> </h6>`;
}

function generateRemoveComment(): string {
  const actionVersion = env("action_version");
  const actionStartTime = env("action_start_time");

  return `${COMMENT_HEADER}
[PR Preview Action](https://github.com/pazerop/pr-preview-action) ${actionVersion}
:---:
Preview removed because the pull request was closed.
${actionStartTime}`;
}

interface Comment {
  id: number;
  body?: string;
}

async function findExistingComment(
  repo: string,
  prNumber: string,
): Promise<Comment | undefined> {
  const comments = (await githubApi(
    "GET",
    `/repos/${repo}/issues/${prNumber}/comments?per_page=100`,
  )) as Comment[];
  return comments.find((c) => c.body?.includes(COMMENT_HEADER));
}

async function postOrUpdateComment(
  repo: string,
  prNumber: string,
  body: string,
): Promise<void> {
  const existing = await findExistingComment(repo, prNumber);
  if (existing) {
    await githubApi("PATCH", `/repos/${repo}/issues/comments/${existing.id}`, {
      body,
    });
    console.log(`Updated existing comment #${existing.id}`);
  } else {
    await githubApi("POST", `/repos/${repo}/issues/${prNumber}/comments`, {
      body,
    });
    console.log("Created new comment");
  }
}

export { generateDeployComment, generateRemoveComment, COMMENT_HEADER };

async function main(): Promise<void> {
  const deploymentAction = env("deployment_action");
  const commentEnabled = env("INPUT_COMMENT");
  const prNumber = env("INPUT_PR_NUMBER");
  const repo = env("GITHUB_REPOSITORY");
  const dryRun = env("DRY_RUN") === "true";

  if (commentEnabled !== "true") {
    console.log("Comments disabled, skipping");
    return;
  }

  let body: string;
  if (deploymentAction === "deploy") {
    body = await generateDeployComment();
  } else if (deploymentAction === "remove") {
    body = generateRemoveComment();
  } else {
    console.log(`No comment for action: ${deploymentAction}`);
    return;
  }

  if (dryRun) {
    process.stdout.write(body);
    return;
  }

  await postOrUpdateComment(repo, prNumber, body);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
