# PR Preview Action

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

## Usage

A [GitHub Actions
workflow](https://docs.github.com/en/actions/learn-github-actions) is
required to use this Action.

All the workflow needs to do first is checkout the repository and build the
Pages site.

If your GitHub pages site is deployed from the `gh-pages` branch, built
with e.g. an `npm` script to the `./build/` dir, and you're happy with the
default settings, usage is very simple:

```yml
# .github/workflows/preview.yml
name: Deploy PR previews

on: pull_request

jobs:
  deploy-preview:
    runs-on: ubuntu-20.04
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Install and Build
        run: |
          npm install
          npm run build

      - name: Deploy preview
        uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: ./build/
```

Consider limiting this workflow to run [only when relevant files are
edited](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore)
to avoid deploying previews unnecessarily.

### Don't delete your previews when deploying a new release!

**Important:** If your root directory on the GitHub Pages deployment branch
(or `docs/` on the main branch) is generated automatically (e.g. on pushes
to the main branch, with a tool such as Webpack), you will need to configure
it not to remove the umbrella directory (`pr-preview/` by default, see
configuration below).

For example, if you are using
[JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)
to deploy your build, you can implement this using its `clean-exclude`
parameter:

```yml
# .github/workflows/build-deploy-pages-site.yml
- steps:
  ...
  - uses: JamesIves/github-pages-deploy-action@v4
    ...
    with:
      clean-exclude: pr-preview/
      ...
```

If you don't do this, your main deployment may delete all of your
currently-existing PR previews.

## Configuration

The following configuration settings are provided, which can be passed to
the `with` parameter.

- `source-dir`: Directory containing files to deploy.

  E.g. if your project builds to `./dist/` you would put `./dist/` (or just
  `dist`) here. For the root directory of your project, put `.` here.

  Equivalent to
  [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)
  'folder' setting.

  Will be ignored when removing a preview.

  Default: `.`

- `preview-branch`: Branch on which the previews will be deployed. This
  should be the same branch that your GitHub Pages site is deployed from.

  Default: `gh-pages`

- `umbrella-dir`: Name of the directory containing all previews. All
  previews will be created inside this directory.

  The umbrella directory is used to namespace previews from your main
  branch's deployment on GitHub Pages.

  Set to `.` to place preview directories into the root directory, but be
  aware that this may cause your main branch's deployment to interfere with
  your preview deployments (and vice-versa!)

  Default: `pr-preview`

- **(Advanced)** `action`: Determines what this action will do when it is
  executed. Supported values: `deploy`, `remove`, `none`, `auto`.

  - `deploy`: will attempt to deploy the preview and overwrite any
    existing preview in that location.
  - `remove`: will attempt to remove the preview in that location.
  - `auto`: the action will try to determine whether to deploy or remove
    the preview. It will deploy the preview on
    `pull_request.types.synchronize` events, and remove it on
    `pull_request.types.closed` events. It will not do anything for all other
    events.
  - `none` and all other values: the action will not do anything.

  Default value: `auto`

## Examples

### Full example

Full example with all default values pointlessly added:

```yml
# .github/workflows/preview.yml
name: Deploy PR previews
on:
  pull_request:
    types:
      - synchronize
      - closed
jobs:
  deploy-preview:
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v2
      - run: npm i && npm run build
      - uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: .
          preview-branch: gh-pages
          umbrella-dir: pr-preview
          action: auto
```

### Reimplementing `auto`

If you don't trust my implementation of `auto`, you can do it yourself

### Permanent previews

If you want to keep PR previews around forever, even after the associated ,
you don't want the cleanup behaviour of `auto` &mdash; call `deploy` and
never call `remove`:

```yml
# .github/workflows/everlasting-preview.yml
name: Deploy everlasting PR preview
on:
  pull_request:
    types:
      - synchronize
jobs:
  deploy-preview:
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v2
      - run: npm i && npm run build
      - uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: ./build/
          action: deploy
          # or,
          # action: github. && <true-value> || <false-value>
```

## Acknowledgements

Big thanks to the following:

- [shlinkio/deploy-preview-action](https://github.com/shlinkio/deploy-preview-action)
  (MIT), prior art that informed the direction of this Action
- [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)
  (MIT), used by this Action to deploy previews
- [marocchino/sticky-pull-request-comment](https://github.com/marocchino/sticky-pull-request-comment)
  (MIT), used by this Action to leave a sticky comment on pull requests
