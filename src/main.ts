import * as path from "path";
import * as core from "@actions/core";
import { context } from "@actions/github";
import deploy from "@jamesives/github-pages-deploy-action";
import {
  ActionInterface,
  TestFlag,
} from "@jamesives/github-pages-deploy-action/lib/constants";

async function main() {
  const previewBranch = core.getInput("preview-branch");
  const umbrellaDir = core.getInput("umbrella-dir");
  const sourceDir = core.getInput("source-dir");
  let action = core.getInput("action");

  if (action === null) action = "null";
  if (action === "auto") action = determineAutoAction();

  const deploySettings: ActionInterface = {
    branch: previewBranch,
    folder: sourceDir,
    isTest: TestFlag.NONE,
    silent: false,
    targetFolder: path.join(umbrellaDir, getPrDir()),
    workspace: process.env.GITHUB_WORKSPACE || "",
  };

  if (action === "deploy") await deployPreview(deploySettings);
  else if (action === "remove") await removePreview(deploySettings);
  else if (action !== "null") core.setFailed(`unknown action ${action}`);
}

void main();

/**
 * When the action input is set to 'auto', the Action will attempt to
 * determine whether to deploy or remove a preview automatically, based on
 * the follow assumptions:
 *
 * - If the event is new commits being added to a PR, a preview should be
 *   deployed
 * - If the event is a PR being closed (regardless of whether it was
 *   merged), the preview should be removed
 * - For all other events, do nothing
 *
 * If the user wishes to override this behaviour they should construct
 * workflows(s) that explictly set the 'deploy' and 'remove' action.
 *
 * @returns The action to perform.
 */
function determineAutoAction(): string {
  core.info("action = auto; determining best action");
  if (context.eventName !== "pull_request") {
    core.info(`unknown event ${context.eventName}; auto -> null`);
    return "null";
  }
  if (context.payload.action === "synchronized") {
    core.info("synchronized event; auto -> deploy");
    return "deploy";
  }
  if (context.payload.action === "closed") {
    core.info("closed event; auto -> remove");
    return "remove";
  }
  core.info(
    `unknown event type ${String(context.payload.action)}; auto -> null`
  );
  return "null";
}

/**
 * Generates a name for the directory that the preview for this PR will
 * live in. Should be deterministic and dependent entirely on the PR to
 * avoid duplications.
 *
 * Uses the PR number instead of e.g. the branch name to avoid exposing
 * malicious content from e.g. forks to Pages URLs.
 *
 * @returns The directory for the preview for this PR.
 */
function getPrDir(): string {
  return `pr-${String(context.payload.number)}`;
}

/**
 * Deploys a new preview via James Ives' Action.
 *
 * @param deploySettings - Configuration for the deployment.
 */
async function deployPreview(deploySettings: ActionInterface) {
  core.info("deploying");
  await deploy(deploySettings);
}

/**
 * Removes a preview using James Ives' Action by deploying to the target
 * directory an empty set of files.
 *
 * @param deploySettings - Configuration for the deployment.
 */
async function removePreview(deploySettings: ActionInterface) {
  core.info("removing");
  // Create a temporary, empty dir to overwrite deployed files with nothing
  deploySettings.folder = "$(mktemp -d)";
  await deploy(deploySettings);
}
