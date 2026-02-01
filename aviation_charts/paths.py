"""Path helpers for aviation charts processing."""

from __future__ import annotations

from pathlib import Path

from aviation_charts.pipeline import PipelinePaths


def ensure_directories(paths: PipelinePaths) -> None:
    """Create required output directories if they do not exist."""

    for path in (
        paths.normalized_root,
        paths.clipped_root,
        paths.warped_root,
        paths.tiles_root,
        paths.mbtiles_root,
    ):
        path.mkdir(parents=True, exist_ok=True)


def charts_dir(paths: PipelinePaths, chart_type: str) -> Path:
    """Return the directory containing source charts for a type."""

    return paths.charts_root / chart_type
