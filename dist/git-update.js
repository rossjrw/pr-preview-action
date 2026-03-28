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
const child_process_1 = require("child_process");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
function env(name) {
    return process.env[name] || "";
}
function run(cmd, cwd) {
    console.log(`$ ${cmd}`);
    (0, child_process_1.execSync)(cmd, { stdio: "inherit", cwd });
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
    run(`git clone --depth 1 --branch "${branch}" "https://x-access-token:${token}@github.com/${repo}.git" "${dir}"`);
}
catch {
    fs.mkdirSync(dir, { recursive: true });
    run("git init", dir);
    run(`git checkout --orphan "${branch}"`, dir);
    run(`git remote add origin "https://x-access-token:${token}@github.com/${repo}.git"`, dir);
}
// Apply changes
const target = path.join(dir, targetPath);
if (mode === "deploy") {
    if (fs.existsSync(target)) {
        fs.rmSync(target, { recursive: true });
    }
    fs.mkdirSync(target, { recursive: true });
    run(`cp -r "${path.join(workspace, sourceDir)}"/. "${target}/"`);
}
else {
    if (fs.existsSync(target)) {
        fs.rmSync(target, { recursive: true });
    }
}
// Commit and push
run('git config user.name "pr-preview-action[bot]"', dir);
run('git config user.email "pr-preview-action[bot]@users.noreply.github.com"', dir);
run("git add -A", dir);
try {
    (0, child_process_1.execSync)("git diff --cached --quiet", { cwd: dir });
    console.log("No changes to commit.");
}
catch {
    run(`git commit -m "${commitMessage}"`, dir);
}
run(`git push -u origin "${branch}"`, dir);
// Remove .git so the directory is clean for artifact upload
fs.rmSync(path.join(dir, ".git"), { recursive: true });
