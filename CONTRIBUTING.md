# Contributing

Contributions are welcome!

## Testing Contributor PRs

Procedure for testing forked PRs from external contributors:

When an external contributor (someone who does not have push access to this repo) submits a PR:

1. New features and fixes may need integration tests - the contributor could write them, but the maintainer could too
2. Integration tests must be added to `.github/workflows/test-integration.yml` so they can run targeting the test repository
3. Workflow runs that originate from a forked PR run on `pull_request_target`, which use workflow files from the base branch - which, for security, does not include the new integration tests :(

The following procedure enables contributor PRs to be tested while minimising risk of security incidents and making sure both the contribution and the tests can be reviewed transparently.

The onus is on the maintainer to make sure it happens. Contributors are welcome to write integration tests but are not expected to be able to run them.

None of this applies to unit tests, which don't need access to anything and always run.

### 1. Contributor submits PR

A contributor opens PR e.g. #123 with their changes, and maybe some new tests too if they're cool.

### 2. Maintainer creates test branch

From a clean state (no unstaged/uncommited changes):

```bash
./.github/scripts/create-test-pr.sh 123
```

This:

1. Fetches the contributor's PR
2. Creates a local branch `test-pr-123` from the contributor's forked branch
3. Checks out that branch

If needed, the maintainer then adds any extra integration tests that weren't already in the contribution.

### 4. Maintainer pushes and creates test PR

```bash
./.github/scripts/push-test-pr.sh 123
```

This pushes the `test-pr-123` branch and creates a draft PR. Tests that run on this PR run within the repository and therefore are able to run any new integration tests.

If the contributor updates their PR, rebase and push the test branch:

```shell
git checkout test-pr-123
git fetch origin pull/123/head:test-pr-123-tmp
git rebase test-pr-123-tmp
# <- Update tests if needed
git push origin test-pr-123 --force-with-lease --force-if-includes
```

### 6. Maintainer merges contribution PR

If tests passes, the feature is desirable, etc, the maintainer should merge the contributor's PR. Unmark the test PR as draft to indicate that it can be merged.

Do not squash merge because that fucks up the commit history.

### 7. Maintainer merges test PR

The maintainer should ensure that the commit history of the test PR is correct (it should now ONLY contain commits that added integration tests, if any) and merge it if appropriate.
