# ---------- Stage 1: builder (installs dependencies) ----------
FROM python:3.12-alpine AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: final runtime image (small) ----------
FROM python:3.12-alpine
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

# Non-root user for security
RUN adduser -D -u 10001 appuser
WORKDIR /home/appuser/app

COPY --from=builder /install /usr/local
COPY app/main.py .

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["gunicorn", "-b", "0.0.0.0:8000", "main:app"]
