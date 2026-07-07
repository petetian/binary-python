# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Uses a full Python image to install Nuitka and compile the script into a
# self-contained native binary (--onefile produces a single executable file).
FROM python:3.12-slim AS builder

WORKDIR /build

# Install system dependencies required by Nuitka for compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        patchelf \
    && rm -rf /var/lib/apt/lists/*

# Install Nuitka
RUN pip install --no-cache-dir nuitka

# Copy only the source file that needs to be compiled
COPY helloworld.py .

# Compile to a single self-contained binary.
# --onefile        → bundle everything into one executable
# --output-dir     → place the output binary in /build/dist
# --assume-yes-for-downloads → accept any Nuitka dependency downloads non-interactively
RUN python -m nuitka \
        --onefile \
        --output-dir=/build/dist \
        --assume-yes-for-downloads \
        helloworld.py

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# Uses a minimal image that contains NO Python interpreter and NO source code –
# only the compiled binary produced in the builder stage.
FROM debian:bookworm-slim AS runtime

WORKDIR /app

# Copy only the compiled binary from the builder stage.
# The Python source file is intentionally NOT copied.
COPY --from=builder /build/dist/helloworld.bin /app/helloworld

RUN chmod +x /app/helloworld

ENTRYPOINT ["/app/helloworld"]
