FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gdal-bin \
        libgdal-dev \
        libproj-dev \
        proj-bin \
        libgeos-dev \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml README.md /app/
COPY aviation_charts /app/aviation_charts
COPY docs /app/docs

RUN pip install --no-cache-dir .

ENTRYPOINT ["aviation-charts"]
CMD ["--help"]
