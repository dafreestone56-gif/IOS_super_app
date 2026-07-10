# GitHub Actions Setup

GitHub Actions only detects workflows in this exact path:

```text
.github/workflows/ios-unsigned-ipa.yml
```

That folder exists in this local project, but because it starts with a dot, some Windows/file-picker views hide it or skip it during manual uploads.

## If `.github` Is Missing On GitHub

Use one of these options:

1. In GitHub, click **Add file** > **Create new file**.
2. Name the file exactly:

```text
.github/workflows/ios-unsigned-ipa.yml
```

3. Copy the contents from:

```text
GITHUB_ACTIONS_VISIBLE/ios-unsigned-ipa.yml
```

4. Commit the file.

After that, GitHub should show an **Actions** tab workflow named **Build Unsigned iOS IPA**.

## Why There Is A Visible Copy

The visible copy is only a convenience backup. GitHub will not run it from `GITHUB_ACTIONS_VISIBLE`; it must be copied to `.github/workflows`.
