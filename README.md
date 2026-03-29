# Deploy PR Preview

Deploy previews of pull requests to [GitHub Pages](https://pages.github.com/). Works when GitHub Pages is configured with source set to **GitHub Actions**.

Features:

-   Creates and deploys previews of pull requests to your GitHub Pages site
-   Leaves a comment on the pull request with a link to the preview so that you and your team can collaborate on new features faster
-   Updates the deployment and the comment whenever new commits are pushed to the pull request
-   Includes a QR code in the preview comment for easy mobile access
-   Sets commit statuses on the PR head SHA to indicate deployment progress
-   Cache-busted preview URLs ensure you always see the latest content
-   Cleans up after itself &mdash; removes deployed previews when the pull request is closed

Preview URLs look like this: `https://[owner].github.io/[repo]/pr-preview/pr-[number]/`

> **Note:** This is a fork of [rossjrw/pr-preview-action](https://github.com/rossjrw/pr-preview-action) that replaces the "Deploy from a branch" code path with artifact-based deployment via `actions/upload-pages-artifact` + `actions/deploy-pages`.

# Setup

In your repository **Settings** > **Pages**, set the source to **GitHub Actions** (not "Deploy from a branch").

# Usage

Call the reusable workflow from your PR workflow:

```yaml
# .github/workflows/preview.yml
name: Deploy PR previews

on:
    pull_request:
        types: [opened, reopened, synchronize, closed]

jobs:
    deploy-preview:
        uses: PazerOP/pr-preview-action/.github/workflows/preview.yml@v1
        with:
            source-dir: ./build/
        secrets: inherit
```

That's it. Permissions, concurrency, fork safety, and the GitHub Pages environment are all handled internally by the reusable workflow. You don't need to configure any of that.

If your site needs a build step, add a separate job and pass the artifact name:

```yaml
name: Deploy PR previews

on:
    pull_request:
        types: [opened, reopened, synchronize, closed]

jobs:
    build:
        runs-on: ubuntu-latest
        if: github.event.action != 'closed'
        steps:
            - uses: actions/checkout@v6
            - run: npm install && npm run build
            - uses: actions/upload-artifact@v4
              with:
                  name: build
                  path: ./build/

    deploy-preview:
        needs: build
        if: always()
        uses: PazerOP/pr-preview-action/.github/workflows/preview.yml@v1
        with:
            artifact-name: build
        secrets: inherit
```

The `artifact-name` input tells the workflow to download the named artifact instead of checking out the repository. The build job is skipped on PR close (`if: github.event.action != 'closed'`), and `if: always()` on the deploy job ensures cleanup still runs.

## Inputs

All parameters are optional. Either `source-dir` or `artifact-name` must be provided.

| Input&nbsp;parameter | Description |
| --- | --- |
| `source-dir` | Directory containing files to deploy. E.g. `./dist/` or `./build/`. Required when `artifact-name` is not set. <br> Default: `"."` |
| `artifact-name` | Name of a previously-uploaded artifact to use as the deploy source. When set, the sparse checkout of `source-dir` is skipped and the artifact is downloaded instead. |
| `preview-branch` | Branch to save previews to. <br> Default: `gh-pages` |
| `umbrella-dir` | Path to the directory containing all previews. <br> Default: `pr-preview` |
| `action` | `deploy`, `remove`, or `auto`. `auto` deploys on `opened`/`reopened`/`synchronize` and removes on `closed`. <br> Default: `auto` |
| `comment` | Whether to leave a sticky comment on the PR. <br> Default: `"true"` |
| `qr-code` | Whether to include a QR code in the PR comment. Set to `"false"` to disable. <br> Default: `"true"` |
| `commit-status-context` | The context string for commit statuses. <br> Default: `"Preview"` |
| `pr-number` | The PR number to use for the preview path. <br> Default: from event context |
| `pages-base-url` | Base URL of the GitHub Pages site. <br> Default: auto-detected |
| `pages-base-path` | Path that GitHub Pages is served from. <br> Default: `""` |
| `deploy-commit-message` | Commit message when adding/updating a preview. <br> Default: `Deploy preview for PR {number}` |
| `remove-commit-message` | Commit message when removing a preview. <br> Default: `Remove preview for PR {number}` |

## Outputs

| Output | Description |
| --- | --- |
| `deployment-action` | Resolved value of the `action` input (deploy, remove, none). |
| `preview-url` | Full URL to the preview (includes `?v={short_sha}` cache-busting param). |

## How it works

1. **Push to branch**: Pushes preview files to a subdirectory on the `gh-pages` branch
2. **Upload artifact**: Checks out the full `gh-pages` branch and uploads it as a Pages artifact
3. **Deploy**: Deploys the artifact to GitHub Pages via `actions/deploy-pages`
4. **Comment**: Posts/updates a sticky PR comment with the preview URL
5. **Status**: Sets commit statuses (pending → success/failure) on the PR head SHA

The `gh-pages` branch serves as the source of truth for all content (production + all PR previews). Each deployment uploads the **entire** branch as a single artifact, since `actions/deploy-pages` replaces the whole site.

# Considerations

## Ensure your main deployment is compatible

If you use GitHub Actions to deploy your main site (e.g. on push to main), configure it to not delete the preview umbrella directory when pushing to `gh-pages`.

# Acknowledgements

-   [rossjrw/pr-preview-action](https://github.com/rossjrw/pr-preview-action) (MIT), the original action this is forked from
