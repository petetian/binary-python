# Test Guide – Verifying Python Source Code Is Invisible to End Users

This guide walks through building the Docker image, running the container, and
confirming that no Python source code is accessible inside the final image.

---

## Prerequisites

| Tool   | Version |
|--------|---------|
| Docker | 20.10 + |

---

## 1. Build the Docker Image

Set target platform to Linux (`linux/amd64`) so the produced binary is always a Linux executable.

### 1a. Windows (PowerShell)

```powershell
docker buildx build --load `
   --platform linux/amd64 `
   --build-arg TARGETPLATFORM=linux/amd64 `
   -t helloworld-binary .
```

### 1b. macOS (zsh/bash)

```bash
docker buildx build --load \
   --platform linux/amd64 \
   --build-arg TARGETPLATFORM=linux/amd64 \
   -t helloworld-binary .
```

### 1c. Linux (bash)

```bash
docker buildx build --load \
   --platform linux/amd64 \
   --build-arg TARGETPLATFORM=linux/amd64 \
   -t helloworld-binary .
```

The multi-stage `Dockerfile` performs two steps:

1. **Builder stage** (`$BUILDPLATFORM`) – copies `app/helloworld.py`, installs Nuitka, and compiles
   `helloworld.py` into a
   self-contained native binary (`helloworld.bin`).
2. **Runtime stage** (`$TARGETPLATFORM`) – copies **only** the compiled binary into a minimal
   `debian:bookworm-slim` image.  The Python interpreter and source files are
   never included in this stage.

---

## 2. Run the Container

### 2a. Windows (PowerShell)

```powershell
docker run --rm helloworld-binary
```

### 2b. macOS / Linux (zsh/bash)

```bash
docker run --rm helloworld-binary
```

Expected output:

```
Hello, World!
```

---

## 3. Verify No Python Source Code Exists Inside the Image

### 3a. Confirm source `.py` files are absent

Windows (PowerShell):

```powershell
docker run --rm --entrypoint sh helloworld-binary -c "find /app -name '*.py' 2>/dev/null"
```

macOS / Linux (zsh/bash):

```bash
docker run --rm --entrypoint sh helloworld-binary -c "find /app -name '*.py' 2>/dev/null"
```

Expected output: *(empty – no `.py` files are present)*

### 3b. Confirm no Python interpreter is installed

Windows (PowerShell):

```powershell
docker run --rm --entrypoint sh helloworld-binary -c "which python3 || echo 'python3 not found'"
```

macOS / Linux (zsh/bash):

```bash
docker run --rm --entrypoint sh helloworld-binary -c "which python3 || echo 'python3 not found'"
```

Expected output:

```
python3 not found
```

### 3c. Confirm the binary is an ELF executable, not a Python script

Windows (PowerShell):

```powershell
docker run --rm --entrypoint sh helloworld-binary -c "file /app/helloworld"
```

macOS / Linux (zsh/bash):

```bash
docker run --rm --entrypoint sh helloworld-binary -c "file /app/helloworld"
```

Expected output (example):

```
/app/helloworld: ELF 64-bit LSB executable, x86-64, ...
```

### 3d. Confirm the image filesystem contains only the binary

Windows (PowerShell):

```powershell
docker run --rm --entrypoint sh helloworld-binary -c "ls -lh /app/"
```

macOS / Linux (zsh/bash):

```bash
docker run --rm --entrypoint sh helloworld-binary -c "ls -lh /app/"
```

Expected output (example):

```
-rwxr-xr-x 1 root root  <size> Jan 01 00:00 helloworld
```

### 3e. Inspect the image layers (no source code layer)

Windows (PowerShell):

```powershell
docker history helloworld-binary
```

macOS / Linux (zsh/bash):

```bash
docker history helloworld-binary
```

The history should show only layers from `debian:bookworm-slim` and the single
`COPY` instruction that copies the binary.  There is no source-file copy such as
`COPY app/helloworld.py` in the runtime stage image history.

Because `TARGETPLATFORM=linux/amd64`, the resulting binary is explicitly built for Linux amd64.

---

## 4. Summary of Expected Results

| Test | Expected Result |
|------|----------------|
| Container runs and prints output | `Hello, World!` |
| No `.py` files found | Empty output |
| No Python interpreter | `python3 not found` |
| `/app/helloworld` is an ELF binary | `ELF 64-bit LSB executable` |
| Image history has no source layer | Only `debian` base + binary `COPY` |

All five checks passing together prove that the Python source code (`app/helloworld.py`)
is completely invisible to anyone interacting with the distributed Docker image.
