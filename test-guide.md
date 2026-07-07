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

```bash
docker build -t helloworld-binary .
```

The multi-stage `Dockerfile` performs two steps:

1. **Builder stage** – installs Nuitka and compiles `helloworld.py` into a
   self-contained native binary (`helloworld.bin`).
2. **Runtime stage** – copies **only** the compiled binary into a minimal
   `debian:bookworm-slim` image.  The Python interpreter and source files are
   never included in this stage.

---

## 2. Run the Container

```bash
docker run --rm helloworld-binary
```

Expected output:

```
Hello, World!
```

---

## 3. Verify No Python Source Code Exists Inside the Image

### 3a. Confirm `helloworld.py` is absent

```bash
docker run --rm --entrypoint sh helloworld-binary -c "find / -name '*.py' 2>/dev/null"
```

Expected output: *(empty – no `.py` files are present)*

### 3b. Confirm no Python interpreter is installed

```bash
docker run --rm --entrypoint sh helloworld-binary -c "which python3 || echo 'python3 not found'"
```

Expected output:

```
python3 not found
```

### 3c. Confirm the binary is an ELF executable, not a Python script

```bash
docker run --rm --entrypoint sh helloworld-binary -c "file /app/helloworld"
```

Expected output (example):

```
/app/helloworld: ELF 64-bit LSB executable, x86-64, ...
```

### 3d. Confirm the image filesystem contains only the binary

```bash
docker run --rm --entrypoint sh helloworld-binary -c "ls -lh /app/"
```

Expected output (example):

```
-rwxr-xr-x 1 root root  <size> Jan 01 00:00 helloworld
```

### 3e. Inspect the image layers (no source code layer)

```bash
docker history helloworld-binary
```

The history should show only layers from `debian:bookworm-slim` and the single
`COPY` instruction that copies the binary.  There is no `COPY helloworld.py`
layer, which confirms the source was never included in the final image.

---

## 4. Summary of Expected Results

| Test | Expected Result |
|------|----------------|
| Container runs and prints output | `Hello, World!` |
| No `.py` files found | Empty output |
| No Python interpreter | `python3 not found` |
| `/app/helloworld` is an ELF binary | `ELF 64-bit LSB executable` |
| Image history has no source layer | Only `debian` base + binary `COPY` |

All five checks passing together prove that the Python source code (`helloworld.py`)
is completely invisible to anyone interacting with the distributed Docker image.
