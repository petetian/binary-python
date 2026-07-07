# binary-python

An MVP framework for compiling a Python script with [Nuitka](https://nuitka.net/) and
packaging the resulting binary inside a minimal Docker image — **no Python source code
is shipped to end users**.

---

## Repository Contents

| File | Purpose |
|------|---------|
| `helloworld.py` | Hello World Python source script |
| `Dockerfile` | Multi-stage build: compile with Nuitka → copy binary only |
| `test-guide.md` | Step-by-step guide to verify source code is invisible |

---

## Quick Start

### Build the image

```bash
docker build -t helloworld-binary .
```

### Run the container

```bash
docker run --rm helloworld-binary
# Hello, World!
```

---

## How It Works

1. **Builder stage** (`python:3.12-slim`) – Nuitka compiles `helloworld.py` into a
   single self-contained native binary using `--onefile`.
2. **Runtime stage** (`debian:bookworm-slim`) – only the compiled binary is copied
   into this minimal image.  The Python interpreter, Nuitka, and all `.py` source
   files are left behind in the builder stage and are never included in the final
   image.

---

## Verifying Source Code Is Invisible

See [`test-guide.md`](test-guide.md) for a complete walk-through that demonstrates
no Python source code or Python interpreter exists inside the distributed image.
