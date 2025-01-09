# Deploy PR Preview action

[GitHub Action](https://github.com/features/actions) that deploys previews
of pull requests to [GitHub Pages](https://pages.github.com/). Works on any
repository with a GitHub Pages site.

Features:

- Creates and deploys previews of pull requests to your GitHub Pages site
- Leaves a comment on the pull request with a link to the preview so that
  you and your team can collaborate on new features faster
- Updates the deployment and the comment whenever new commits are pushed to
  the pull request
- Cleans up after itself &mdash; removes deployed previews when the pull
  request is closed
- Can be configured to override any of these behaviours

Preview URLs look like this:
`https://[owner].github.io/[repo]/pr-preview/pr-[number]/`

<p align="center">
  <img src="https://github.com/rossjrw/pr-preview-action/blob/main/.github/sample-preview-link.png" alt="Sample comment left by the action">
</p>
<p align="center">
  Pictured: https://github.com/rossjrw/pr-preview-action/pull/1
</p>

This Action does not currently support deploying previews for PRs from forks,
but will do so in [the upcoming
v2](https://github.com/rossjrw/pr-preview-action/pull/6).

## Usage

A [GitHub Actions
workflow](https://docs.github.com/en/actions/learn-github-actions) is
required to use this Action.

All the workflow needs to do first is checkout the repository and build the
Pages site.

First, ensure that your repository is configured to have its GitHub Pages
site deployed from a branch, by setting the source for the deployment under
**Settings** > **Pages** of your repository to **Deploy from branch**:

<p align="center">
  <img src="https://github.com/rossjrw/pr-preview-action/blob/main/.github/deployment-settings.png" alt="GitHub Pages settings">
</p>
<p align="center">
  Pictured: Repository Pages settings at /settings/page
</p>

The `gh-pages` branch is used for GitHub Pages deployments by convention,
and will be used in examples here as well.

If your GitHub pages site is deployed from the `gh-pages` branch, built
with e.g. an `npm` script to the `./build/` dir, and you're happy with the
default settings, usage is very simple:

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
    runs-on: ubuntu-20.04
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install and Build
        if: github.event.action != 'closed' # You might want to skip the build if the PR has been closed
        run: |
          npm install
          npm run build

      - name: Deploy preview
        uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: ./build/
```

# Inputs (configuration)

The following input parameters are provided, which can be passed to the `with` parameter. All parameters are optional and have a default value.

Input&nbsp;parameter | Description
--- | ---
`source-dir` | When creating or updating a preview, the path to the directory that contains the files to deploy. E.g. if your project builds to `./dist/` you would put `./dist/` (or `dist`, etc.). <br> Equivalent to [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) 'folder' setting. <br><br> Default: `.` (repository root)
`deploy-repository` | The repository to deploy the preview to. <br> __Note:__ The `token` parameter must also be set if changing this from the default. <br><br> Default: The pull request's target repository.
`preview-branch` | Branch to save previews to. This should be the same branch that your GitHub Pages site is deployed from. <br><br> Default: `gh-pages`
`umbrella-dir` | Path to the directory to place previews in. <br> The umbrella directory is used to namespace previews from your main branch's deployment on GitHub Pages. <br><br> Default: `pr-preview`
`pages-base-url` | Base URL to use when providing a link to the preview site. <br><br> Default: The pull request's target repository's default GitHub Pages URL (e.g. `rossjrw.github.io/pr-preview-action/`)
`pages-base-path` | Path that GitHub Pages is being served from, as configured in your repository settings, e.g. `docs/`. When generating the preview URL path, this is removed from the beginning of the file path. <br><br> Default: `.` (repository root)
`comment` <br> (boolean) | Whether to leave a [sticky comment](https://github.com/marocchino/sticky-pull-request-comment) on the PR after the preview is built.<br> The comment may be added before the preview finishes deploying. <br><br> Default: `true`
`token` | Authentication token for the preview deployment. <br> The default value works for non-fork pull requests to the same repository. For anything else, you will need a [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with permission to access it, and [store it as a secret](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) in your repository. E.g. you might name that secret 'PREVIEW_TOKEN' and use it with `token: ${{ secrets.PREVIEW_TOKEN }}`. <br><br> Default: `${{ github.token }}`, which gives the action permission to deploy to the current repository.
`action` <br> (enum) | Determines what this action will do when it is executed. Supported values: <br><br> <ul><li>`deploy` - create and deploy the preview, overwriting any existing preview in that location.</li><li>`remove` - remove the preview.</li><li>`auto` - determine whether to deploy or remove the preview based on [the emitted event](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads#pull_request). If the event is `pull_request`, it will deploy the preview when the event type is `opened`, `reopened` and `synchronize`, and remove it on `closed` events. Does not do anything for other events or event types, even if you explicitly instruct the workflow to run on them.</li><li>`none` and all other values: does not do anything.</li></ul> Default: `auto`

# Outputs

Several output values are provided to use after this Action in your workflow. To use them, give this Action's step an `id` and reference the value with `${{ steps.<id>.outputs.<name> }}`, e.g.:

```yml
# .github/workflows/preview.yml
jobs:
  deploy-preview:
    steps:
      - uses: rossjrw/pr-preview-action@v1
        id: preview-step
      - run: echo "Preview visible at ${{ steps.preview-step.outputs.preview-url }}"
```

You could use these outputs and input parameter `comment: false` to write your own sticky comment after the Action has run.

Output | Description
--- | ---
`deployment-action` | Resolved value of the `action` input parameter (deploy, remove, none).
`pages-base-url` | What this Action thinks the base URL of the GitHub Pages site is.
`preview-url-path` | Path to the preview from the Pages base URL.
`preview-url` | Full URL to the preview (`https://<pages-base-url>/<preview-url-path>/`).
`action-version` | The version of this Action when it was run.
`action-start-timestamp` | The time that the workflow step started as a Unix timestamp.
`action-start-time` | The time that the workflow step started in a readable format (UTC, depending on runner).

# Common pitfalls

### Grant Actions permission to read and write to the repository

This must be changed in the repository settings by selecting "Read and
write permissions" at **Settings** > **Actions** > **General** >
**Workflow permissions**. Otherwise, the Action won't be able to make any
changes to your deployment branch.

### Run on all appropriate pull request events

Be sure to [pick the right event
types](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request)
for the `pull_request` event. It only comes with `opened`, `reopened`, and
`synchronize` by default &mdash; but this Action assumes by default that
the preview should be removed during the `closed` event, which it only sees
if you explicitly add it to the workflow.

### Ensure your main deployment is compatible

If you are using GitHub Actions to deploy your GitHub Pages sites
(typically on push to the main branch), there are some actions you should
take to avoid the PR preview overwriting the main deployment, or
vice-versa.

1. **Prevent your main deployment from deleting previews**

   If your root directory on the GitHub Pages deployment branch (or `docs/`
   on the main branch) is generated automatically (e.g. on pushes to the
   main branch, with a tool such as Webpack), you will need to configure it
   not to remove the umbrella directory (`pr-preview/` by default, see
   configuration below).

   For example, if you are using
   [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)
   to deploy your build, you can implement this using its `clean-exclude`
   parameter:

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

   If you don't do this, your main deployment may delete all of your
   currently-existing PR previews.

2. **Don't force-push your main deployment**

   Force-pushing your main deployment will cause it to overwrite any and
   all files in the deployment location. This will destroy any ongoing
   preview deployments. Instead, consider adjusting your deployment
   workflow to rebase or merge your main deployment onto the deployment
   branch to respect other ongoing deployments.

   For example, if you are using
   [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)
   to deploy your build, be aware that at the time of writing (v4.7.2) it
   force-pushes new deployments by default. You can disable this by setting
   its `force` parameter to `false`, which will prompt it to rebase new
   deployments instead of force-pushing them:

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

# Best practices

### Run only when files are changed

Consider limiting this workflow to run [only when relevant files are
edited](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore)
to avoid deploying previews unnecessarily.

### Set a concurrency group

I highly recommend [setting a concurrency
group](https://docs.github.com/en/actions/using-jobs/using-concurrency)
scoped to each PR using `github.ref` as above, which should prevent the
preview and comment from desynchronising if you are e.g. committing very
frequently.

# Examples

## Full example

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
      - uses: actions/checkout@v3
      - run: npm i && npm run build
        if: github.event.action != 'closed'
      - uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: .
          preview-branch: gh-pages
          umbrella-dir: pr-preview
          action: auto
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
      - uses: actions/checkout@v3
      - run: npm i && npm run build
      - uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: .
          branch: gh-pages
          clean-exclude: pr-preview
          force: false
```

## Deployment from `docs/`

If your Pages site is built to `build/` and deployed from the `docs/`
directory on the `main` branch:

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

You should definitely limit this workflow to run only on changes to
directories other than `docs/`, otherwise this workflow will call itself recursively.

## Only remove previews for unmerged PRs

Information from the context and conditionals can be used to make more
complex decisions about what to do with previews; for example, removing
only those associated with _unmerged_ PRs when they are closed:

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

## Permanent previews

If you want to keep PR previews around forever, even after the associated
PR has been closed, you don't want the cleanup behaviour of `auto` &mdash;
call `deploy` and never call `remove`:

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
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v3
      - run: npm i && npm run build
      - uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: ./build/
          action: deploy
```

# Acknowledgements

Big thanks to the following:

- [shlinkio/deploy-preview-action](https://github.com/shlinkio/deploy-preview-action) (MIT), prior art that informed the direction of this Action
- [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) (MIT), used by this Action to deploy previews
- [marocchino/sticky-pull-request-comment](https://github.com/marocchino/sticky-pull-request-comment) (MIT), used by this Action to leave a sticky comment on pull requests
- [Everyone who has contributed](https://github.com/rossjrw/pr-preview-action/graphs/contributors) to this Action
