#!/usr/bin/env node

// Screenshot generator for readme

const { firefox } = require("playwright");
const { execSync } = require("child_process");
const { readFileSync } = require("fs");
const { imageSize } = require("image-size");

async function main() {
    const version = execSync(
        'git describe --tags --match "v*.*.*" --abbrev=0',
        { encoding: "utf-8" }
    ).trim();
    const browser = await firefox.launch({ headless: true });
    const page = await browser.newPage({
        viewport: { width: 1280, height: 1024 },
        deviceScaleFactor: 2,
    });

    console.log("Loading PR page...");
    await page.goto("https://github.com/rossjrw/pr-preview-action/pull/1", {
        waitUntil: "domcontentloaded",
    });
    await page.waitForTimeout(2000);
    console.log("Page loaded");

    console.log("Cleaning up comment...");
    await page.evaluate((newVersion) => {
        const style = document.createElement("style");
        style.textContent = `
          .TimelineItem::before,
          .timeline-comment-actions,
          .details-overlay{
            display: none !important;
          }
          .timeline-comment .comment-body table {
            margin-bottom: 0;
          }
          .timeline-comment {
            max-width: fit-content;
          }
          .timeline-comment-header > * {
            font-size: 0 !important;
          }
          .timeline-comment-header strong {
            font-size: 0.875rem !important;
          }
        `;
        document.head.appendChild(style);

        const links = document.querySelectorAll(
            'a[href="/apps/github-actions"]'
        );
        let commentGroup = null;
        for (const link of links) {
            commentGroup = link.closest(".timeline-comment-group");
            if (commentGroup) break;
        }

        if (!commentGroup) return { error: "Comment group not found" };

        // Replace version number
        let versionReplaced = 0;
        const walker = document.createTreeWalker(
            commentGroup,
            NodeFilter.SHOW_TEXT,
            null
        );
        const nodes = [];
        while (walker.nextNode()) {
            nodes.push(walker.currentNode);
        }
        nodes.forEach((node) => {
            if (node.textContent && node.textContent.match(/v\d+\.\d+/)) {
                node.textContent = node.textContent.replace(
                    /v[\d\.\-a-z]+/g,
                    newVersion
                );
                versionReplaced++;
            }
        });
        return { versionReplaced };
    }, version);

    await page.waitForTimeout(500);

    // Calculate bounding box that includes avatar and comment
    const bounds = await page.evaluate(() => {
        const links = document.querySelectorAll(
            'a[href="/apps/github-actions"]'
        );
        let timelineItem = null;
        for (const link of links) {
            timelineItem = link.closest(".TimelineItem");
            if (timelineItem) break;
        }

        if (!timelineItem) return null;

        const avatar = timelineItem.querySelector(".TimelineItem-avatar");
        const comment = timelineItem.querySelector(".timeline-comment");

        if (!avatar || !comment) return null;

        const avatarRect = avatar.getBoundingClientRect();
        const commentRect = comment.getBoundingClientRect();

        return {
            x: Math.min(avatarRect.left, commentRect.left),
            y: Math.min(avatarRect.top, commentRect.top),
            right: Math.max(avatarRect.right, commentRect.right),
            bottom: Math.max(avatarRect.bottom, commentRect.bottom),
        };
    });

    if (!bounds) {
        throw new Error("Could not calculate bounds");
    }

    const width = bounds.right - bounds.x;
    const height = bounds.bottom - bounds.y;

    console.log("Bounds:", { x: bounds.x, y: bounds.y, width, height });

    const clipWidth = Math.round(width + 20);
    const clipHeight = Math.round(height + 20);

    console.log("Taking screenshot...");
    await page.screenshot({
        path: "sample-preview-link.png",
        clip: {
            x: Math.max(0, bounds.x - 10),
            y: Math.max(0, bounds.y - 10),
            width: clipWidth,
            height: clipHeight,
        },
    });

    const imageBuffer = readFileSync("sample-preview-link.png");
    const dimensions = imageSize(imageBuffer);
    console.log(
        `Screenshot saved to sample-preview-link.png (${dimensions.width}x${dimensions.height}px)`
    );

    await browser.close();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
