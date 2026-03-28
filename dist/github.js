"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.githubApi = githubApi;
async function githubApi(method, endpoint, body) {
    const token = process.env.INPUT_TOKEN;
    const apiUrl = process.env.GITHUB_API_URL || "https://api.github.com";
    const headers = {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    };
    const opts = { method, headers };
    if (body) {
        headers["Content-Type"] = "application/json";
        opts.body = JSON.stringify(body);
    }
    const resp = await fetch(`${apiUrl}${endpoint}`, opts);
    if (!resp.ok) {
        const text = await resp.text();
        throw new Error(`GitHub API ${method} ${endpoint}: ${resp.status} ${text}`);
    }
    const contentType = resp.headers.get("content-type") || "";
    if (contentType.includes("application/json")) {
        return resp.json();
    }
    return resp.text();
}
