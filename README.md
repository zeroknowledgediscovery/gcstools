```markdown
# Git–GCS Artifact Tools

Lightweight command-line utilities for managing **large files and directories in Google Cloud Storage (GCS)** while keeping Git repositories clean and fast.

Instead of committing large binaries to Git, these tools store artifacts in GCS and keep **small pointer files (`.gcs`)** in the repository. This avoids repository bloat while preserving reproducibility.

The workflow is intentionally simple and designed to work in **any Git repository**.

---

# Overview

Large artifacts such as:

- datasets
- model checkpoints
- simulation outputs
- intermediate analysis products
- compiled binaries

do not belong in Git history.

This toolset provides a minimal alternative to Git LFS by:

1. Uploading artifacts to **GCS**
2. Writing a small **pointer file (`.gcs`)** in the repository
3. Restoring artifacts from pointers when needed

A pointer file typically looks like:

```

version: 1
type: file
uri: gs://git-org-repo/data/big_dataset.parquet
sha256: 3b7f2d...
size_bytes: 842931234

```

---

# Key Features

- Works in **any Git repository**
- Automatically creates GCS buckets
- Stores only **pointer files** in Git
- Supports **files and directories**
- Automatically updates `.gitignore`
- Verifies integrity using **SHA256 checksums**
- Deterministic bucket naming from Git remote

---

# Bucket Naming

Buckets are created automatically using the repository remote:

```

git-<orgname>-<reponame>

```

Example:

```

git-openai-research-project

```

If a remote cannot be parsed, the fallback is:

```

git-local-<repo>

```

---

# Installation

Run the installer:

```

bash install_gcs_git_tools.sh

```

This installs global commands into:

```

~/.local/bin

```

Installed commands:

```

git_gcs_artifacts   # backend engine
gcsinit
gcspush
gcspull
gcsstatus

```

Ensure your PATH includes:

```

~/.local/bin

```

---

# Quick Start

Inside any Git repository:

```

gcsinit

```

Push a file:

```

gcspush data/big_dataset.parquet

```

Push a directory:

```

gcspush models/run_001

```

This creates:

```

data/big_dataset.parquet.gcs
models/run_001.gcs

```

The actual data lives in GCS.

---

# Restoring Artifacts

Restore a file:

```

gcspull data/big_dataset.parquet.gcs

```

Restore everything under a directory:

```

gcspull models

```

Restore all artifacts in a repository:

```

gcspull --all

```

---

# Example Repository Layout

Before push:

```

repo/
├── data/
│   └── big_dataset.parquet
└── models/
└── run_001/
├── weights.pt
└── config.json

```

After push:

```

repo/
├── data/
│   └── big_dataset.parquet.gcs
└── models/
└── run_001.gcs

```

`.gitignore` automatically contains:

```

/data/big_dataset.parquet
/models/run_001

```

---

# Pointer Files

Pointer files contain metadata required to restore artifacts.

Example:

```

version: 1
type: dir
uri: gs://git-org-repo/models/run_001
manifest_uri: gs://git-org-repo/models/run_001.**manifest**.tsv
file_count: 12
total_bytes: 3240932

```

Directory uploads include a **manifest** containing file hashes.

---

# Commands

## `gcsinit`

Initializes repository artifact storage.

```

gcsinit

```

Creates bucket if necessary.

---

## `gcspush`

Uploads file or directory to GCS.

```

gcspush <file>
gcspush <directory>

```

Example:

```

gcspush data/dataset.parquet
gcspush experiments/run42

```

---

## `gcspull`

Restores artifacts.

```

gcspull pointer.gcs
gcspull directory
gcspull --all

```

---

## `gcsstatus`

Shows pointer files tracked in the repository.

```

gcsstatus

```

---

# Typical Workflow

Push large artifacts:

```

gcspush data/train.parquet
gcspush models/model_v1

```

Commit pointer files:

```

git add *.gcs
git commit -m "add dataset and model artifacts"

```

Clone repository elsewhere and restore:

```

gcspull --all

```

---

# Integrity Verification

Artifacts are verified using:

```

SHA256 checksums

```

For directories, each file is validated using a manifest stored in GCS.

---

# Requirements

- Git
- Google Cloud SDK (`gcloud`)
- Access to a GCP project
- Permissions to create GCS buckets

Install GCloud SDK:

```

[https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

```

Authenticate:

```

gcloud auth login

```

---

# Why Not Git LFS?

Git LFS works well but has limitations:

- server storage quotas
- performance issues with very large datasets
- repository coupling

This approach:

- separates **source control** from **artifact storage**
- leverages scalable cloud storage
- keeps repositories extremely lightweight

---

# Use Cases

This tool is particularly useful for:

- machine learning research
- large simulation outputs
- scientific computing
- data science workflows
- reproducible pipelines

---

# License

MIT License

---

# Contributing

Issues and pull requests are welcome.
```
