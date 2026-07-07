# Build stage: compile the Python program into a standalone binary
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
RUN pyinstaller --onefile --name app main.py

# Runtime stage: copy only the compiled binary
FROM debian:bookworm-slim AS runtime

WORKDIR /app

COPY --from=builder /app/dist/app .

ENTRYPOINT ["/app/app"]
