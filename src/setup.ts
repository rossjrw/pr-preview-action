import * as fs from "fs";
import * as path from "path";

function env(name: string): string {
  return process.env[name] || "";
}

function calculatePagesBaseUrl(repo: string): string {
  const [owner, repoName] = repo.split("/");
  if (repoName === `${owner}.github.io`) {
    return `${owner}.github.io`;
  }
  return `${owner}.github.io/${repoName}`;
}

function normalisePath(p: string): string {
  return p
    .replace(/^\.\//, "")
    .replace(/^\/+/, "")
    .replace(/\/+$/, "")
    .replace(/\/+/g, "/");
}

function removePrefixPath(basePath: string, originalPath: string): string {
  const normBase = normalisePath(basePath);
  const normOriginal = normalisePath(originalPath);
  if (!normBase) return normOriginal;
  if (normOriginal.startsWith(normBase + "/")) {
    return normOriginal.slice(normBase.length + 1);
  }
  return normOriginal;
}

function determineAutoAction(eventName: string, eventPath: string): string {
  if (eventName === "push") {
    return "deploy";
  }

  if (eventName !== "pull_request" && eventName !== "pull_request_target") {
    console.error(`unknown event ${eventName}; no action to take`);
    return "none";
  }

  const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
  const action: string = event.action;
  console.error(`event_type is ${action}`);

  switch (action) {
    case "opened":
    case "reopened":
    case "synchronize":
      return "deploy";
    case "closed":
      return "remove";
    default:
      console.error(`unknown event type ${action}; no action to take`);
      return "none";
  }
}

function appendToFile(filePath: string, content: string): void {
  fs.appendFileSync(filePath, content);
}

function writeEnvAndOutput(
  vars: Record<string, string>,
  envFile: string,
  outputFile: string,
): void {
  const lines = Object.entries(vars)
    .map(([k, v]) => `${k}=${v}`)
    .join("\n");
  appendToFile(envFile, lines + "\n");
  appendToFile(outputFile, lines + "\n");
}

// Main
const inputAction = env("INPUT_ACTION") || "auto";
const umbrellaDir = env("INPUT_UMBRELLA_DIR") || "pr-preview";
const pagesBaseUrlInput = env("INPUT_PAGES_BASE_URL");
const pagesBasePath = env("INPUT_PAGES_BASE_PATH");
const prNumber = env("INPUT_PR_NUMBER");
const actionRef = env("INPUT_ACTION_REF") || "unknown";
const eventName = env("GITHUB_EVENT_NAME");
const eventPath = env("GITHUB_EVENT_PATH");
const repository = env("GITHUB_REPOSITORY");
const envFile = env("GITHUB_ENV");
const outputFile = env("GITHUB_OUTPUT");

const pagesBaseUrl = pagesBaseUrlInput || calculatePagesBaseUrl(repository);

const isPrEvent =
  eventName === "pull_request" || eventName === "pull_request_target";
const previewFilePath = isPrEvent ? `${umbrellaDir}/pr-${prNumber}` : "";

let previewUrlPath = "";
if (previewFilePath) {
  previewUrlPath = removePrefixPath(pagesBasePath, previewFilePath);
  if (
    pagesBasePath &&
    removePrefixPath("", previewFilePath) === previewUrlPath
  ) {
    console.warn(
      `::warning title=pages-base-path doesn't match::The pages-base-path directory (${pagesBasePath}) does not contain umbrella-dir (${umbrellaDir}). pages-base-path has been ignored. The value of umbrella-dir should start with the value of pages-base-path.`,
    );
    previewUrlPath = previewFilePath;
  }
}

let deploymentAction = inputAction;
if (deploymentAction === "auto") {
  console.error("Determining auto action");
  deploymentAction = determineAutoAction(eventName, eventPath);
  console.error(`Auto action is ${deploymentAction}`);
}

const basePreviewUrl = previewUrlPath
  ? `https://${pagesBaseUrl}/${previewUrlPath}/`
  : `https://${pagesBaseUrl}/`;

// Get short SHA for cache busting
let shortSha = "";
try {
  const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
  const headSha: string =
    event.pull_request?.head?.sha || env("GITHUB_SHA") || "";
  shortSha = headSha.slice(0, 7);
} catch {
  shortSha = (env("GITHUB_SHA") || "").slice(0, 7);
}

const previewUrl = shortSha
  ? `${basePreviewUrl}?v=${shortSha}`
  : basePreviewUrl;

const actionStartTimestamp = Math.floor(Date.now() / 1000).toString();
const actionStartTime = new Date()
  .toISOString()
  .replace("T", " ")
  .replace(/\.\d+Z$/, " UTC");

// Write to both GITHUB_ENV and GITHUB_OUTPUT
const sharedVars: Record<string, string> = {
  deployment_action: deploymentAction,
  preview_file_path: previewFilePath,
  pages_base_url: pagesBaseUrl,
  preview_url_path: previewUrlPath,
  preview_url: previewUrl,
  short_sha: shortSha,
  action_version: actionRef,
  action_start_time: actionStartTime,
  action_start_timestamp: actionStartTimestamp,
};

writeEnvAndOutput(sharedVars, envFile, outputFile);


console.log(`Action: ${deploymentAction}`);
console.log(`Preview URL: ${previewUrl}`);
