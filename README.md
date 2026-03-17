# Git–GCS Artifacts

Git–GCS Artifacts is a lightweight command-line system for managing large files and directories in Google Cloud Storage (GCS) while keeping Git repositories small, fast, and reproducible.

Instead of committing large binaries into Git history, the tools upload artifacts to GCS and store small pointer files with the `.gcs` suffix in the repository. Those pointers are versioned in Git and contain the metadata needed to restore the original artifacts later.

This is intended for workflows involving datasets, model checkpoints, simulation outputs, intermediate results, and other large binary assets that do not belong in normal Git history.

---

## What it does

The toolchain provides five commands:

- `git_gcs_artifacts`  
  The backend engine. This is the command the wrappers call internally.

- `gcsinit`  
  Initializes GCS support in the current repository.

- `gcspush`  
  Uploads a file or directory to GCS and creates a `.gcs` pointer file next to it.

- `gcspull`  
  Restores files or directories from `.gcs` pointer files.

- `gcsstatus`  
  Shows current pointer files and repository artifact status.

---

## Core model

The workflow is intentionally simple:

1. You run `gcspush` on a file or directory.
2. The artifact is uploaded to GCS.
3. A `.gcs` pointer file is written next to the original path.
4. `.gitignore` is updated so the large artifact itself is not tracked.
5. The pointer file is committed and pushed to Git by default.
6. On another machine or clone, `gcspull` restores the artifact from the pointer.

This keeps the repository lightweight while preserving exact artifact references.

---

## Key features

- Works in any Git repository
- Automatic per-repo bucket creation
- Pointer files stored next to original artifact paths
- Supports both files and directories
- Recursive push mode with a size threshold
- Default behavior is upload + commit + push
- Recursive mode uses a single batch commit and a single push
- Directory restore includes per-file SHA256 verification
- No repo-specific scripts are required after installation

---

## Bucket naming

By default, the bucket name is derived from the Git remote:

```text
git-<org>-<repo>
```

Examples:

```text
git-zeroknowledgediscovery-zebra-open
git-myorg-myrepo
```

If the Git remote cannot be parsed, the fallback bucket is:

```text
git-local-<repo>
```

The bucket is created automatically if it does not already exist.

---

## Pointer behavior

Pointer files are created in the same path as the target artifact, not in the current working directory.

Examples:

```bash
gcspush xx/yy/zz.csv
```

creates:

```text
xx/yy/zz.csv.gcs
```

and

```bash
gcspush models/run_01
```

creates:

```text
models/run_01.gcs
```

This rule also holds in recursive mode.

---

## Installation

Clone the tools repository and run the installer:

```bash
git clone <your-tools-repo>
cd <your-tools-repo>
bash install_gcs_git_tools.sh
```

The installer places the commands in:

```text
~/.local/bin
```

and installs:

```text
git_gcs_artifacts
gcsinit
gcspush
gcspull
gcsstatus
```

Ensure `~/.local/bin` is on your `PATH`.

For Bash:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Quick start

Initialize the current repository:

```bash
gcsinit
```

Push a file:

```bash
gcspush data/file.parquet
```

Push a directory:

```bash
gcspush models/run_01
```

Restore a single file:

```bash
gcspull data/file.parquet.gcs
```

Restore all tracked artifacts in the repository:

```bash
gcspull --all
```

---

## Default commit behavior

By default, `gcspush` does three things beyond upload:

1. stages the pointer file and `.gitignore`
2. creates a Git commit
3. pushes the commit to the current Git remote

So this:

```bash
gcspush data/file.parquet
```

means:

- upload artifact
- create `data/file.parquet.gcs`
- update `.gitignore`
- `git add`
- `git commit`
- `git push`

This default applies to both normal and recursive push mode.

If needed, this can be disabled with flags described below.

---

# Full command reference

## 1. `gcsinit`

Initializes artifact storage support for the current repository.

This command:

- verifies that you are inside a Git repository
- determines the default bucket name
- creates the GCS bucket if needed
- ensures a `.gitignore` file exists
- appends a section header for managed artifacts if needed

### Syntax

```bash
gcsinit [options]
```

### Options

`--bucket BUCKET`  
Use an explicit bucket name instead of the default derived name.

`--location LOCATION`  
Set the GCS bucket location. Default is `US`.

`--project PROJECT`  
Set the GCP project explicitly when creating the bucket.

`-h`, `--help`  
Show help.

### Examples

```bash
gcsinit
gcsinit --bucket git-my-explicit-bucket
gcsinit --location US-CENTRAL1
gcsinit --project my-gcp-project
```

---

## 2. `gcspush`

Uploads a file or directory to GCS and creates a `.gcs` pointer next to it.

There are two operating modes:

- normal mode
- recursive mode

### Normal mode

Normal mode pushes one file or one directory.

### Syntax

```bash
gcspush PATH
gcspush PATH --no-commit
gcspush PATH --no-push
gcspush PATH --no-commit --no-push
```

### Options

`--no-commit`  
Upload the artifact and create the pointer, but do not commit changes.

`--no-push`  
Commit locally but do not `git push`.

`-h`, `--help`  
Show help.

Any backend arguments that your setup supports can be forwarded after the path.

### Examples

```bash
gcspush data/train.parquet
gcspush data/train.parquet --no-push
gcspush models/run_01 --no-commit
gcspush outputs/final_model --no-commit --no-push
```

### What happens in normal mode

For a file:

```bash
gcspush data/train.parquet
```

the tool will:

- upload `data/train.parquet` to GCS
- compute SHA256
- create `data/train.parquet.gcs`
- add `/data/train.parquet` to `.gitignore`
- add `!/data/train.parquet.gcs` to `.gitignore`
- stage the pointer and `.gitignore`
- commit
- push

For a directory:

```bash
gcspush models/run_01
```

the tool will:

- upload the full directory recursively
- generate a manifest describing the files
- upload the manifest to GCS
- create `models/run_01.gcs`
- ignore the local directory in `.gitignore`
- commit and push the pointer by default

---

## 3. `gcspush -r` / recursive mode

Recursive mode scans a directory tree and pushes only files meeting a size threshold.

This is useful when you want to process a project tree and externalize only large files while leaving small files in Git.

### Syntax

```bash
gcspush -r DIRECTORY
gcspush -r DIRECTORY -t 25
gcspush -r DIRECTORY --threshold-mb 25
gcspush -r DIRECTORY --no-push
gcspush -r DIRECTORY --no-commit
gcspush -r DIRECTORY --no-commit --no-push
```

### Options

`-r`, `--recursive`  
Enable recursive mode.

`-t MB`, `--threshold-mb MB`  
Only push files whose size is greater than or equal to the threshold in megabytes. Default is `10`.

`--no-commit`  
Do not create the final batch commit.

`--no-push`  
Create the batch commit locally but do not push.

`-h`, `--help`  
Show help.

### Examples

Push all files >= 10 MB:

```bash
gcspush -r ./data
```

Push all files >= 25 MB:

```bash
gcspush -r ./results -t 25
```

Upload only, no commit or push:

```bash
gcspush -r ./artifacts --no-commit --no-push
```

Commit locally but do not push:

```bash
gcspush -r ./artifacts --no-push
```

### Recursive commit behavior

Recursive mode does **not** make one commit per file.

Instead, it:

1. finds all qualifying files
2. pushes them one by one to GCS
3. creates `.gcs` pointers next to each file
4. stages all pointers together
5. stages `.gitignore` if changed
6. creates **one single Git commit**
7. pushes once

This is deliberate. It keeps commit history clean and avoids one commit per artifact.

### Recursive pointer behavior

If recursive mode sees a file like:

```text
xx/a/b/large.csv
```

it creates:

```text
xx/a/b/large.csv.gcs
```

The pointer always lives next to the file it represents.

---

## 4. `gcspull`

Restores artifacts from `.gcs` pointers.

It supports three patterns:

- restore one pointer
- restore all pointers under a directory
- restore all pointers in the repository

### Syntax

```bash
gcspull POINTER.gcs
gcspull DIRECTORY
gcspull --all
```

### Options

`--all`  
Restore every `.gcs` pointer in the repository.

`-h`, `--help`  
Show help.

### Examples

Restore one file:

```bash
gcspull data/train.parquet.gcs
```

Restore all pointers under a directory:

```bash
gcspull models
```

Restore all pointers in the repository:

```bash
gcspull --all
```

### Pull behavior

For a file pointer, `gcspull`:

- reads the GCS URI from the pointer
- downloads the file to the path obtained by removing `.gcs`
- verifies SHA256 if present

For a directory pointer, `gcspull`:

- downloads the manifest
- downloads every file in the manifest
- reconstructs the directory tree
- verifies SHA256 for each restored file

---

## 5. `gcsstatus`

Shows the current repository status related to Git–GCS artifacts.

### Syntax

```bash
gcsstatus
gcsstatus --dir DIRECTORY
```

### Options

`--dir DIRECTORY`  
Restrict the pointer listing to a subtree.

`-h`, `--help`  
Show help.

### Examples

```bash
gcsstatus
gcsstatus --dir data
gcsstatus --dir models
```

### Output includes

- `git status --porcelain`
- a list of `.gcs` pointers under the chosen path
- the default bucket name inferred for the repository

---

## 6. `git_gcs_artifacts` backend

This is the backend command used by the wrappers. Most users will not call it directly, but it is useful for debugging or scripting.

### Syntax

```bash
git_gcs_artifacts init [options]

git_gcs_artifacts add --local PATH [options]

git_gcs_artifacts pull [--pointer POINTER.gcs | --dir DIRECTORY | --all] [options]

git_gcs_artifacts status [--dir DIRECTORY]
```

### Backend subcommands

#### `git_gcs_artifacts init`

Same function as `gcsinit`.

#### `git_gcs_artifacts add`

Direct backend for `gcspush`.

Example:

```bash
git_gcs_artifacts add --local data/train.parquet --commit --push
```

#### `git_gcs_artifacts pull`

Direct backend for `gcspull`.

Examples:

```bash
git_gcs_artifacts pull --pointer data/train.parquet.gcs
git_gcs_artifacts pull --dir models
git_gcs_artifacts pull --all
```

#### `git_gcs_artifacts status`

Direct backend for `gcsstatus`.

---

# Pointer file format

## File pointer example

```text
version: 1
type: file
uri: gs://git-myorg-myrepo/data/train.parquet
sha256: 2d4f6f5f4c...
size_bytes: 842931234
source_repo_relpath: data/train.parquet
```

## Directory pointer example

```text
version: 1
type: dir
uri: gs://git-myorg-myrepo/models/run_01
manifest_uri: gs://git-myorg-myrepo/models/run_01.__manifest__.tsv
manifest_sha256: 7305f7...
file_count: 12
total_bytes: 3240932
source_repo_relpath: models/run_01
```

---

## `.gitignore` behavior

When an artifact is pushed, the tool updates `.gitignore` so the artifact itself is not committed, but the pointer remains trackable.

For a file:

```text
/data/train.parquet
!/data/train.parquet.gcs
```

For a directory:

```text
/models/run_01
!/models/run_01.gcs
```

This is appended exactly once per managed path.

---

## Typical workflows

### Single large file

```bash
gcspush data/cohort.parquet
```

Result:

- `data/cohort.parquet` uploaded
- `data/cohort.parquet.gcs` committed and pushed

### Model directory

```bash
gcspush models/checkpoint_17
```

Result:

- entire directory uploaded
- `models/checkpoint_17.gcs` committed and pushed

### Sweep a tree for large files

```bash
gcspush -r ./results -t 50
```

Result:

- all files >= 50 MB uploaded
- one batch commit
- one Git push

### Restore everything after clone

```bash
gcspull --all
```

---

## Requirements

- Git
- Google Cloud SDK with `gcloud storage`
- authenticated GCP environment
- permission to create and write GCS buckets
- a valid Git repository for normal operation

Typical authentication:

```bash
gcloud auth login
gcloud config set project <project-id>
```

---

## Design philosophy

This tool is deliberately simple.

It is meant to provide:

- explicit artifact locations
- reproducible restore paths
- minimal hidden state
- easy debugging
- clean Git history

It does not try to be a full data versioning framework. It is a practical bridge between Git and GCS.

---

## Comparison with alternatives

### Compared with Git LFS

Advantages:

- external object storage is explicit
- bucket per repo can be created automatically
- no LFS server dependency
- pointer files are transparent text

Tradeoff:

- less integrated with Git hosting platforms

### Compared with DVC

Advantages:

- simpler mental model
- much less machinery
- easier to inspect and debug

Tradeoff:

- fewer pipeline and data-versioning features

---

## Known behavior and caveats

- Bucket names must be globally unique in GCS.
- Recursive mode only pushes files meeting the threshold.
- Recursive mode uses one final commit, not one commit per file.
- If you pass `--no-commit`, no commit is created.
- If you pass `--no-push`, the commit remains local.
- Pointer placement follows the target path, not the current directory.

---

## Example session

```bash
gcsinit

gcspush data/train.parquet

gcspush models/run_01

gcspush -r ./results -t 25

gcspull data/train.parquet.gcs

gcspull models

gcspull --all

gcsstatus
```

---

## License

GPL-3.0
