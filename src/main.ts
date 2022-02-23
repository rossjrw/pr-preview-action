import * as path from "path";
import * as core from "@actions/core";
import { context } from "@actions/github";
import deploy from "@jamesives/github-pages-deploy-action";
import { TestFlag } from "@jamesives/github-pages-deploy-action/lib/constants";

const previewBranch = core.getInput("preview-branch");
const umbrellaDir = core.getInput("umbrella-dir");
const sourceDir = core.getInput("source-dir");
let action: string | null = core.getInput("action");

if (action === "null") action = null;

if (action === "auto") {
  core.info("action = auto; determining best action");
  if (context.eventName !== "pull_request") {
    core.info(`unknown event ${context.eventName}; auto -> null`);
    action = null;
  } else if (context.payload.action === "synchronized") {
    core.info("synchronized event; auto -> deploy");
    action = "deploy";
  } else if (context.payload.action === "closed") {
    core.info("closed event; auto -> remove");
    action = "remove";
  } else {
    core.info(
      `unknown event type ${String(context.payload.action)}; auto -> null`
    );
    action = null;
  }
}

// Use PR number to set the directory name
const prDir = `pr-${String(context.payload.number)}`;

if (action === "deploy") {
  core.info("deploying");
  void deploy({
    branch: previewBranch,
    folder: sourceDir,
    isTest: TestFlag.NONE,
    silent: false,
    targetFolder: path.join(umbrellaDir, prDir),
    workspace: process.env.GITHUB_WORKSPACE || "",
  });
}
