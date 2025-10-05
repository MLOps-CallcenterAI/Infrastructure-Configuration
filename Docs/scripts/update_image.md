# Update Docker Image Script

## Overview

The `update_image.sh` script updates the Docker image tag in a specified Kubernetes manifest file.
It automates the process of changing the container image version in your manifests before deployment.

---

## File Location

```
scripts/update_image.sh
```

---

## Prerequisites

* Bash shell
* Kubernetes manifest file containing a line starting with `image:`

---

## Usage

```bash
./scripts/update_image.sh <filepath> <image_tag>
```

**Parameters:**

* `<filepath>`: Path to the Kubernetes manifest file (e.g., `manifests/default/svm.yaml`)
* `<image_tag>`: New Docker image tag (e.g., `v1.0.2`)

**Example:**

```bash
./scripts/update_image.sh manifests/default/svm.yaml v1.0.2
```

---

## Script Workflow

1. **Check arguments**
   Ensures both the file path and image tag are provided.

2. **Verify file exists**
   Exits if the manifest file is missing.

3. **Extract current image name**
   Detects the current image name in the manifest (ignores the tag).

4. **Replace old image tag**
   Uses `sed` to replace the current image tag with the new one in the file.

5. **Print output**
   Displays a confirmation of the updated image:

```
✅ Updated image tag in manifests/default/svm.yaml
➡️  New image: myregistry/callcenterai:v1.0.2
```

---

## Notes

* Only updates the first `image:` entry found in the file.
* Script exits on errors (missing file, invalid arguments, or missing image name).
* Can be safely re-run to update image tags for deployment.

---

This ensures your **Kubernetes manifests are always updated** with the correct Docker image version before applying them to the cluster.

---
