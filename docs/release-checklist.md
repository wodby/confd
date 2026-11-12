# Release Checklist

1. Make sure `CHANGELOG` describes every change since the previous release, under the new version.
2. After the pull request is merged, create a signed, annotated `vX.Y.Z` tag on `master` whose
   message summarizes the changes, and push it.

Builds set the version from the tag with `-ldflags "-X main.Version=X.Y.Z -X main.GitSHA=<commit>"`.
