# Deploy PR Preview action

[GitHub Action](https://github.com/features/actions) that deploys previews of pull requests to [GitHub Pages](https://pages.github.com/). Works on any repository with a GitHub Pages site.

Features:

-   Creates and deploys previews of pull requests to your GitHub Pages site
-   Leaves a comment on the pull request with a link to the preview so that you and your team can collaborate on new features faster
-   Updates the deployment and the comment whenever new commits are pushed to the pull request
-   Includes a QR code in the preview comment for easy mobile access
-   Cleans up after itself &mdash; removes deployed previews when the pull request is closed
-   Can be configured to override any of these behaviours

Preview URLs look like this: `https://[owner].github.io/[repo]/pr-preview/pr-[number]/`

<p align="center">
  <img src="https://github.com/rossjrw/pr-preview-action/blob/main/.github/sample-preview-link.png" alt="Sample comment left by the action" width="548">
</p>
<p align="center">
  Pictured: https://github.com/rossjrw/pr-preview-action/pull/1
</p>

This Action does not currently support deploying previews for PRs from forks, but will do so in [the upcoming v2](https://github.com/rossjrw/pr-preview-action/pull/6).

# Setup

A [GitHub Actions workflow](https://docs.github.com/en/actions/learn-github-actions) is required to use this Action.

You just need to do two things to set up your repository to support previews, both in the repository settings:

### 1. Deploy Pages from branch

Ensure that your repository is configured to have its GitHub Pages site deployed from a branch, by setting the source for the deployment under **Settings** > **Pages** of your repository to **Deploy from branch**:

<p align="center">
  <img src="https://github.com/rossjrw/pr-preview-action/blob/main/.github/deployment-settings.png" alt="GitHub Pages settings">
</p>
<p align="center">
  Pictured: Repository Pages settings at /settings/page
</p>

> [!IMPORTANT]  
> The other option (called "GitHub Actions") has a [misleading name](https://github.com/orgs/community/discussions/30113#discussioncomment-7650234) and does not work with this action.

### 2. Let your workflow write to the repo

In **Settings** > **Actions** > **General** > **Workflow permissions**, select "Read and write permissions" to allow action runs to make changes to your deployment branch (in this case, to add and remove previews).

# Usage

All the workflow needs to do before running the preview action is checkout the repository and build the Pages site.

If your GitHub pages site is deployed from the `gh-pages` branch, built with e.g. an `npm` script to the `./build/` dir, and you're happy with the default settings, usage is very simple:

```yml
# .github/workflows/preview.yml
name: Deploy PR previews

on:
    pull_request:
        types:
            - opened
            - reopened
            - synchronize
            - closed

concurrency: preview-${{ github.ref }}

jobs:
    deploy-preview:
        runs-on: ubuntu-latest
        steps:
            - name: Checkout
              uses: actions/checkout@v4

            - name: Install and Build
              if: github.event.action != 'closed' # We don't need the build if we know the preview will be removed
              run: |
                  npm install
                  npm run build

            - name: Deploy preview
              uses: rossjrw/pr-preview-action@v1
              with:
                  source-dir: ./build/
                  preview-branch: gh-pages
                  qr-code: true
```

> [!TIP]  
> The `gh-pages` branch is used for GitHub Pages deployments by convention, and will be used in examples here as well, but you can use whatever branch you like (just make sure to change the `preview-branch` input).

## Inputs (configuration)

The following input parameters are provided, which can be passed to the `with` parameter. ALL parameters are optional and have a default value.

| Input&nbsp;parameter | Description |
| --- | --- |
| `source-dir` | When creating or updating a preview, the path to the directory that contains the files to deploy. E.g. if your project builds to `./dist/` you would put `./dist/` (or `dist`, etc.). <br> Equivalent to [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) 'folder' setting. <br><br> Default: `.` (repository root) |
| `deploy-repository` | The repository to deploy the preview to. <br> **Note:** The `token` parameter must also be set if changing this from the default. <br><br> Default: The pull request's target repository. |
| `preview-branch` | Branch to save previews to. This should be the same branch that your GitHub Pages site is deployed from. <br><br> Default: `gh-pages` |
| `umbrella-dir` | Path to the directory to place previews in. <br> The umbrella directory is used to namespace previews from your main branch's deployment on GitHub Pages. <br><br> Default: `pr-preview` |
| `pr-number` | The PR number to use for the preview path. <br> Useful for testing or when the workflow is not triggered by a pull_request event. <br><br> Default: The PR number (`${{ github.event.number }}`) |
| `pages-base-url` | Base URL to use when providing a link to the preview site. <br><br> Default: The pull request's target repository's default GitHub Pages URL (e.g. `rossjrw.github.io/pr-preview-action/`) |
| `pages-base-path` | Path that GitHub Pages is being served from, as configured in your repository settings, e.g. `docs/`. When generating the preview URL path, this is removed from the beginning of the file path. <br><br> Default: `.` (repository root) |
| `wait-for-pages-deployment` <br> (boolean) | Whether to wait for the GitHub Pages deployment to complete. When enabled, the action will poll the GitHub Deployments API and delay workflow completion until the Pages deployment finishes, e.g. to ensure the preview URL is accessible when the comment is posted. <br><br> Default: `false` (this will be `true` in a future version of this Action) |
| `comment` <br> (boolean) | Whether to leave a [sticky comment](https://github.com/marocchino/sticky-pull-request-comment) on the PR after the preview is built.<br> The comment may be added before the preview finishes deploying unless `wait-for-pages-deployment` is enabled. <br><br> Default: `true` |
| `qr-code` <br> | Whether to include a QR code in the sticky comment for easy mobile access, which links to the preview URL. Only affects the default comment (i.e. if `comment` is not `false`). <br> Enabled by default - set to `false` to disable, or to a string to use a different provider ([see below](#use-a-different-qr-code-provider)). <br><br> Default: [`https://qr.rossjrw.com/?color.dark=0d1117&url=`](https://qr.rossjrw.com) |
| `token` | Authentication token for the preview deployment. <br> The default value works for non-fork pull requests to the same repository. For anything else, you will need a [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with permission to access it, and [store it as a secret](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) in your repository. E.g. you might name that secret 'PREVIEW_TOKEN' and use it with `token: ${{ secrets.PREVIEW_TOKEN }}`. <br><br> Default: `${{ github.token }}`, which gives the action permission to deploy to the current repository. |
| `action` <br> (enum) | Determines what this action will do when it is executed. Supported values: <br><br> <ul><li>`deploy` - create and deploy the preview, overwriting any existing preview in that location.</li><li>`remove` - remove the preview.</li><li>`auto` - determine whether to deploy or remove the preview based on [the emitted event](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads#pull_request). If the event is `pull_request`, it will deploy the preview when the event type is `opened`, `reopened` and `synchronize`, and remove it on `closed` events. Does not do anything for other events or event types, even if you explicitly instruct the workflow to run on them.</li><li>`none` and all other values: does not do anything.</li></ul> Default: `auto` |

<details>
<summary><b>Extra parameters for controlling the commits</b></summary>

| Input&nbsp;parameter | Description |
| --- | --- |
| `deploy-commit-message` | The commit message to use when adding/updating a preview. <br> **Note:** You can use certain [GitHub context variables](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts). <br><br> Default: `Deploy preview for PR ${{ github.event.number }} 🛫` |
| `remove-commit-message` | The commit message to use when removing a preview. <br> Note: If using `action` with a value of `"auto"`, you need to specify BOTH `deploy-commit-message` and `remove-commit-message`. <br><br> Default: `Remove preview for PR ${{ github.event.number }} 🛬` |
| `git-config-name` | The git user.name to use for the deployment commit. <br><br> Default: The user who created the `token` |
| `git-config-email` | The git user.email to use for the deployment commit. <br><br> Default: The user who created the `token` |

</details>

## Outputs

Several output values are provided to use after this Action in your workflow. To use them, give this Action's step an `id` and reference the value with `${{ steps.<id>.outputs.<name> }}`, e.g.:

```yml
# .github/workflows/preview.yml
jobs:
    deploy-preview:
        steps:
            - uses: rossjrw/pr-preview-action@v1
              id: preview-step
            - if: steps.preview-step.outputs.deployment-action == "deploy"
              run: echo "Preview visible at ${{ steps.preview-step.outputs.preview-url }}"
```

You could use these outputs and input parameter `comment: false` to write your own sticky comment after the Action has run.

| Output | Description |
| --- | --- |
| `deployment-action` | Resolved value of the `action` input parameter (deploy, remove, none). |
| `pages-base-url` | What this Action thinks the base URL of the GitHub Pages site is. |
| `preview-url-path` | Path to the preview from the Pages base URL. |
| `preview-url` | Full URL to the preview (`https://<pages-base-url>/<preview-url-path>/`). |
| `deployed-commit-sha` | The SHA of the commit that was deployed to the preview branch. |
| `action-version` | The full, exact version of this Action when it was run. |
| `action-start-timestamp` | The time that the workflow step started as a Unix timestamp. |
| `action-start-time` | The time that the workflow step started in a readable format (UTC, depending on runner). |

# Considerations

## Common pitfalls

### Grant Actions permission to read and write to the repository

This must be changed in the repository settings by selecting "Read and write permissions" at **Settings** > **Actions** > **General** > **Workflow permissions**. Otherwise, the Action won't be able to make any changes to your deployment branch.

### Run on all appropriate pull request events

Be sure to [pick the right event types](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request) for the `pull_request` event. It only comes with `opened`, `reopened`, and `synchronize` by default &mdash; but this Action assumes by default that the preview should be removed during the `closed` event, which it only sees if you explicitly add it to the workflow.

### Ensure your main deployment is compatible

If you are using GitHub Actions to deploy your GitHub Pages sites (typically on push to the main branch), there are some actions you should take to avoid the PR preview overwriting the main deployment, or vice-versa.

1. **Prevent your main deployment from deleting previews**

    If your root directory on the GitHub Pages deployment branch (or `docs/` on the main branch) is generated automatically (e.g. on pushes to the main branch, with a tool such as Webpack), you will need to configure it not to remove the umbrella directory (`pr-preview/` by default, see configuration below).

    For example, if you are using [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) to deploy your build, you can implement this using its `clean-exclude` parameter:

    ```yml
    # .github/workflows/build-deploy-pages-site.yml
    steps:
        ...
        - uses: JamesIves/github-pages-deploy-action@v4
          ...
          with:
              clean-exclude: pr-preview/
              ...
    ```

    If you don't do this, your main deployment may delete all of your currently-existing PR previews.

2. **Don't force-push your main deployment**

    Force-pushing your main deployment will cause it to overwrite any and all files in the deployment location. This will destroy any ongoing preview deployments. Instead, consider adjusting your deployment workflow to rebase or merge your main deployment onto the deployment branch to respect other ongoing deployments.

    For example, if you are using [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) to deploy your build, be aware that at the time of writing (v4.7.2) it force-pushes new deployments by default. You can disable this by setting its `force` parameter to `false`, which will prompt it to rebase new deployments instead of force-pushing them:

    ```yml
    # .github/workflows/build-deploy-pages-site.yml
    steps:
        ...
        - uses: JamesIves/github-pages-deploy-action@v4
            ...
            with:
                force: false
                ...
    ```

    This feature was introduced in v4.3.0 of the above Action.

## Best practices

### Run only when files are changed

Consider limiting this workflow to run [only when relevant files are edited](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) to avoid deploying previews unnecessarily.

### Set a concurrency group

I highly recommend [setting a concurrency group](https://docs.github.com/en/actions/using-jobs/using-concurrency) scoped to each PR using `github.ref` as above, which should prevent the preview and comment from desynchronising if you are e.g. committing very frequently.

## Examples

### Full example

Full example with all default values added:

```yml
# .github/workflows/preview.yml
name: Deploy PR previews
concurrency: preview-${{ github.ref }}
on:
    pull_request:
        types:
            - opened
            - reopened
            - synchronize
            - closed
jobs:
    deploy-preview:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - run: npm i && npm run build
              if: github.event.action != 'closed'
            - uses: rossjrw/pr-preview-action@v1
              with:
                  source-dir: .
                  preview-branch: gh-pages
                  umbrella-dir: pr-preview
                  action: auto
                  wait-for-pages-deployment: false
                  comment: true
                  qr-code: false
```

...and an accompanying main deployment workflow:

```yml
# .github/workflows/deploy.yml
name: Deploy
on:
    push:
        branches:
            - main
jobs:
    deploy:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - run: npm i && npm run build
            - uses: JamesIves/github-pages-deploy-action@v4
              with:
                  folder: .
                  branch: gh-pages
                  clean-exclude: pr-preview
                  force: false
```

### Deployment from `docs/`

If your Pages site is built to `build/` and deployed from the `docs/` directory on the `main` branch:

```yml
# .github/workflows/preview.yml
steps:
    ...
    - uses: rossjrw/pr-preview-action@v1
      with:
          source-dir: build
          preview-branch: main
          umbrella-dir: docs/pr-preview
          pages-base-path: docs
```

You should definitely limit this workflow to run only on changes to directories other than `docs/`, otherwise this workflow will call itself recursively.

### Only remove previews for unmerged PRs

Information from the [context](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) and [conditionals](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions) can be used to make more complex decisions about what to do with previews; for example, removing only those associated with _unmerged_ PRs when they are closed:

```yml
# .github/workflows/preview.yml
steps:
    ...
    - uses: rossjrw/pr-preview-action@v1
      if: contains(['opened', 'reopened', 'synchronize'], github.event.action)
      with:
          source-dir: ./build/
          action: deploy
    - uses: rossjrw/pr-preview-action@v1
      if: github.event.action == "closed" && !github.event.pull_request.merged
      with:
          source-dir: ./build/
          action: remove
```

### Permanent previews

If you want to keep PR previews around forever, even after the associated PR has been closed, you don't want the cleanup behaviour of `auto` &mdash; call `deploy` and never call `remove`:

```yml
# .github/workflows/everlasting-preview.yml
name: Deploy everlasting PR preview
concurrency: preview-${{ github.ref }}
on:
    pull_request:
        types:
            - opened
            - synchronize
jobs:
    deploy-preview:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - run: npm i && npm run build
            - uses: rossjrw/pr-preview-action@v1
              with:
                  source-dir: ./build/
                  action: deploy
```

### Wait for GitHub Pages deployment to complete

By default, this action starts a deployment to the target branch and leaves a comment immediately, but GitHub Pages may take 30-60 seconds to build and deploy your site. This can result in comments with preview links that don't work yet.

Set `wait-for-deployment: true` to make the action automatically wait for Pages deployment before posting the comment:

```yml
- uses: rossjrw/pr-preview-action@v1
  with:
      wait-for-pages-deployment: true
```

### Customise the sticky comment

You can use `id`, `with: comment: false`, the output values and [context variables](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) to construct your own comment to be left on the PR. This example recreates this Action's default comment (complete with HTML spacing jank), but you could change it however you like, use a different commenting Action from the marketplace, etc.

```yml
# .github/workflows/preview.yml
name: Deploy PR preview
concurrency: preview-${{ github.ref }}
on:
    pull_request:
        types:
            - opened
            - reopened
            - synchronize
            - closed
env:
    PREVIEW_BRANCH: gh-pages
jobs:
    deploy-preview:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - run: npm i && npm run build

            - uses: rossjrw/pr-preview-action@v1
              id: preview-step
              with:
                  source-dir: ./build/
                  preview-branch: ${{ env.PREVIEW_BRANCH }}
                  comment: false

            - uses: marocchino/sticky-pull-request-comment@v2
              if: steps.preview-step.outputs.deployment-action == 'deploy' && env.deployment_status == 'success'
              with:
                  header: pr-preview
                  message: |
                      [PR Preview Action](https://github.com/rossjrw/pr-preview-action) ${{ steps.preview-step.outputs.action-version }}
                      :---:
                      | <p><img src="https://qr.rossjrw.com/?url=${{ steps.preview-step.outputs.preview-url }}" height="100" align="right" alt="QR code for preview link"></p> :rocket: View preview at <br> ${{ steps.preview-step.outputs.preview-url }} <br><br>
                      | <h6>Built to branch [`${{ env.PREVIEW_BRANCH }}`](${{ github.server_url }}/${{ github.repository }}/tree/${{ env.PREVIEW_BRANCH }}) at ${{ steps.preview-step.outputs.action-start-time }}. <br> Preview will be ready when the [GitHub Pages deployment](${{ github.server_url }}/${{ github.repository }}/deployments) is complete. <br><br> </h6>

            - uses: marocchino/sticky-pull-request-comment@v2
              if: steps.preview-step.outputs.deployment-action == 'remove' && env.deployment_status == 'success'
              with:
                  header: pr-preview
                  message: |
                      [PR Preview Action](https://github.com/rossjrw/pr-preview-action) ${{ steps.preview-step.outputs.action-version }}
                      :---:
                      Preview removed because the pull request was closed.
                      ${{ steps.preview-step.outputs.action-start-time }}
```

### Use a different QR code provider

If you have this action include a QR code in the sticky comment with `qr-code: true`, the default QR code provider is [qr.rossjrw.com](https://qr.rossjrw.com/), a provider that I built for this project because I don't trust any pre-existing ones. Likewise, you probably shouldn't trust mine - what if I go rogue and change all your QR codes to point to something else? You never know.

To use a different QR code provider (it's easy to make your own - consider forking https://github.com/rossjrw/qrcode-worker), set `qr-code` to its URL. The URI-encoded preview link will be appended to it. E.g.:

```yml
- uses: rossjrw/pr-preview-action@v1
  with:
      qr-code: https://my-qrcode-provider.example.com/generate?url=
```

If using a customised comment with `comment: false`, simply construct the image URL from your chosen provider's URL and the preview URL (`${{ steps.[JOB ID].outputs.preview-url }}`).

# Acknowledgements

Big thanks to the following:

-   [shlinkio/deploy-preview-action](https://github.com/shlinkio/deploy-preview-action) (MIT), prior art that informed the direction of this Action
-   [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) (MIT), used by this Action to deploy previews
-   [marocchino/sticky-pull-request-comment](https://github.com/marocchino/sticky-pull-request-comment) (MIT), used by this Action to leave a sticky comment on pull requests
-   [Everyone who has contributed](https://github.com/rossjrw/pr-preview-action/graphs/contributors) to this Action
