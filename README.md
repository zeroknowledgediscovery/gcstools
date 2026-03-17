# Git--GCS Artifacts

A lightweight system to store large files in Google Cloud Storage (GCS)
while keeping only pointer files (.gcs) in Git.

## Features

-   Works in any Git repo
-   Automatic bucket creation: git-`<org>`{=html}-`<repo>`{=html}
-   Pointer files stored alongside original paths
-   Recursive push with size threshold
-   Default: upload + commit + push

## Install

git clone `<repo>`{=html} cd `<repo>`{=html} bash
install_gcs_git_tools.sh

Ensure \~/.local/bin is in PATH

## Usage

gcsinit gcspush file.parquet gcspush -r ./data -t 25 gcspull
file.parquet.gcs

## Pointer Behavior

xx/yy/zz.csv -\> xx/yy/zz.csv.gcs

## License

GPL-3.0
