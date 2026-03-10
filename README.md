# git-gcs-tools

Simple Git helpers for storing large files and directories in **Google Cloud Storage (GCS)** while keeping lightweight pointer files in your repository.

The tools allow research repositories to stay small while still allowing deterministic recovery of large artifacts such as datasets, model checkpoints, and simulation outputs.

Unlike Git LFS, this system uses **plain pointer files (`.gcs`) and standard GCS buckets** with minimal infrastructure.

---

# Overview

The toolkit provides the following commands:

```
gcsinit
gcspush
gcspull
gcsstatus
```

These commands work inside any existing Git repository.

Typical workflow:

```
gcspush data/big_dataset.parquet
git add data/big_dataset.parquet.gcs
git commit -m "store dataset in GCS"
```

The actual artifact remains on disk locally but is ignored by Git.

---

# Motivation

Research repositories frequently contain artifacts too large for Git:

- model checkpoints
- datasets
- training outputs
- simulation artifacts
- intermediate results

This toolkit allows:

- Git repositories to remain lightweight
- deterministic recovery of artifacts
- simple storage using Google Cloud Storage
- minimal dependencies

---

# Installation

Clone the repository and run the install script.

```
git clone https://github.com/<org>/git-gcs-tools.git
cd git-gcs-tools
bash install_gcs_git_tools
```

This installs the following commands globally:

```
gcsinit
gcspush
gcspull
gcsstatus
```

They are installed to:

```
~/.local/bin
```

Ensure this directory is in your `PATH`.

---

# Requirements

The following tools must be installed:

- `git`
- `gcloud` CLI
- authenticated Google Cloud credentials

Example authentication:

```
gcloud auth login
gcloud config set project <your-project>
```

---

# Repository Initialization

Inside any Git repository run:

```
gcsinit
```

This command:

1. Creates or verifies a GCS bucket
2. Initializes repository configuration
3. Prepares `.gitignore` if necessary

The bucket name is automatically inferred from the Git repository:

```
git-<org>-<repo>
```

Example:

```
git-zeroknowledgediscovery-zebra_open
```

---

# Uploading Files

Upload a file to GCS:

```
gcspush path/to/file
```

Example:

```
gcspush models/checkpoint.pt
```

Behavior:

1. File is uploaded to GCS
2. A pointer file is created:

```
models/checkpoint.pt.gcs
```

3. The original file remains locally
4. The original path is automatically added to `.gitignore`

Commit only the pointer:

```
git add models/checkpoint.pt.gcs
git commit -m "store checkpoint in GCS"
```

---

# Uploading Directories

Directories can also be uploaded.

```
gcspush results/run1
```

Behavior:

- directory is recursively uploaded
- pointer file created:

```
results/run1.gcs
```

The directory remains locally but is added to `.gitignore`.

---

# Pointer File Format

Pointer files are plain text and contain metadata needed to restore the artifact.

Example:

```
type: file
uri: gs://git-myorg-myrepo/models/checkpoint.pt
sha256: 9f86d081884c7d659a2fe...
```

Directory pointer example:

```
type: dir
uri: gs://git-myorg-myrepo/results/run1
```

These files are small and safe to commit to Git.

---

# Restoring Artifacts

Restore a file:

```
gcspull models/checkpoint.pt.gcs
```

Restore a directory:

```
gcspull results
```

Restore all artifacts in the repository:

```
gcspull --all
```

---

# Checking Stored Artifacts

List all pointer files in the repository:

```
gcsstatus
```

Example output:

```
models/checkpoint.pt.gcs
data/big_dataset.parquet.gcs
results/run1.gcs
```

---

# Example Workflow

Initialize repository:

```
gcsinit
```

Push artifacts:

```
gcspush data/train.parquet
gcspush models/run1
```

Commit pointers:

```
git add data/train.parquet.gcs
git add models/run1.gcs
git commit -m "store artifacts in GCS"
```

Clone on another machine:

```
git clone <repo>
cd <repo>
gcsinit
gcspull --all
```

Artifacts will be restored from GCS.

---

# Recommended `.gitignore`

The push command automatically adds pushed paths to `.gitignore`.

Example:

```
data/train.parquet
models/run1
```

Pointer files remain tracked:

```
*.gcs
```

---

# Design Philosophy

This tool intentionally avoids complex infrastructure.

Key principles:

- minimal dependencies
- plain text pointer files
- repository-agnostic operation
- deterministic artifact recovery
- simple integration with existing Git workflows

---

# License

See `LICENSE` in this repository.