import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

function env(name: string): string {
  return process.env[name] || "";
}

function run(cmd: string, cwd?: string): void {
  console.log(`$ ${cmd}`);
  execSync(cmd, { stdio: "inherit", cwd });
}

const mode = process.argv[2]; // "deploy" or "remove"
if (mode !== "deploy" && mode !== "remove") {
  console.error(`Usage: git-update.ts <deploy|remove>`);
  process.exit(1);
}

const branch = env("INPUT_BRANCH");
const token = env("INPUT_TOKEN");
const repo = env("GITHUB_REPOSITORY");
const targetPath = env("INPUT_TARGET_PATH");
const commitMessage = env("INPUT_COMMIT_MESSAGE");
const sourceDir = env("INPUT_SOURCE_DIR");
const workspace = env("GITHUB_WORKSPACE");
const dir = path.join(workspace, "__gh-pages-content");

// Clone or init
if (fs.existsSync(dir)) {
  fs.rmSync(dir, { recursive: true });
}

try {
  run(
    `git clone --depth 1 --branch "${branch}" "https://x-access-token:${token}@github.com/${repo}.git" "${dir}"`,
  );
} catch {
  fs.mkdirSync(dir, { recursive: true });
  run("git init", dir);
  run(`git checkout --orphan "${branch}"`, dir);
  run(
    `git remote add origin "https://x-access-token:${token}@github.com/${repo}.git"`,
    dir,
  );
}

// Apply changes
const target = path.join(dir, targetPath);
if (mode === "deploy") {
  if (fs.existsSync(target)) {
    fs.rmSync(target, { recursive: true });
  }
  fs.mkdirSync(target, { recursive: true });
  run(`cp -r "${path.join(workspace, sourceDir)}"/. "${target}/"`);
} else {
  if (fs.existsSync(target)) {
    fs.rmSync(target, { recursive: true });
  }
}

// Commit and push
run('git config user.name "pr-preview-action[bot]"', dir);
run(
  'git config user.email "pr-preview-action[bot]@users.noreply.github.com"',
  dir,
);
run("git add -A", dir);
try {
  execSync("git diff --cached --quiet", { cwd: dir });
  console.log("No changes to commit.");
} catch {
  run(`git commit -m "${commitMessage}"`, dir);
}
run(`git push -u origin "${branch}"`, dir);

// Remove .git so the directory is clean for artifact upload
fs.rmSync(path.join(dir, ".git"), { recursive: true });
