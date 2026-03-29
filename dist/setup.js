"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs"));
function env(name) {
    return process.env[name] || "";
}
function calculatePagesBaseUrl(repo) {
    const [owner, repoName] = repo.split("/");
    if (repoName === `${owner}.github.io`) {
        return `${owner}.github.io`;
    }
    return `${owner}.github.io/${repoName}`;
}
function normalisePath(p) {
    return p
        .replace(/^\.\//, "")
        .replace(/^\/+/, "")
        .replace(/\/+$/, "")
        .replace(/\/+/g, "/");
}
function removePrefixPath(basePath, originalPath) {
    const normBase = normalisePath(basePath);
    const normOriginal = normalisePath(originalPath);
    if (!normBase)
        return normOriginal;
    if (normOriginal.startsWith(normBase + "/")) {
        return normOriginal.slice(normBase.length + 1);
    }
    return normOriginal;
}
function determineAutoAction(eventName, eventPath) {
    if (eventName === "push") {
        const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
        const defaultBranch = event.repository?.default_branch;
        const ref = env("GITHUB_REF");
        if (defaultBranch && ref === `refs/heads/${defaultBranch}`) {
            return "deploy";
        }
        console.error(`Push to non-default branch (${ref}), skipping`);
        return "none";
    }
    if (eventName !== "pull_request" && eventName !== "pull_request_target") {
        console.error(`unknown event ${eventName}; no action to take`);
        return "none";
    }
    const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
    const action = event.action;
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
function appendToFile(filePath, content) {
    fs.appendFileSync(filePath, content);
}
function writeEnvAndOutput(vars, envFile, outputFile) {
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
const isPrEvent = eventName === "pull_request" || eventName === "pull_request_target";
const previewFilePath = isPrEvent ? `${umbrellaDir}/pr-${prNumber}` : "";
let previewUrlPath = "";
if (previewFilePath) {
    previewUrlPath = removePrefixPath(pagesBasePath, previewFilePath);
    if (pagesBasePath &&
        removePrefixPath("", previewFilePath) === previewUrlPath) {
        console.warn(`::warning title=pages-base-path doesn't match::The pages-base-path directory (${pagesBasePath}) does not contain umbrella-dir (${umbrellaDir}). pages-base-path has been ignored. The value of umbrella-dir should start with the value of pages-base-path.`);
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
    const headSha = event.pull_request?.head?.sha || env("GITHUB_SHA") || "";
    shortSha = headSha.slice(0, 7);
}
catch {
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
const sharedVars = {
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
