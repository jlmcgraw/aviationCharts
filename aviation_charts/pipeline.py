"""Pipeline orchestration for chart processing."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from aviation_charts.paths import ensure_directories


@dataclass(frozen=True)
class PipelineStep:
    name: str
    description: str


@dataclass(frozen=True)
class PipelinePaths:
    """Filesystem layout for chart processing."""

    charts_root: Path
    normalized_root: Path
    clipped_root: Path
    warped_root: Path
    tiles_root: Path
    mbtiles_root: Path

    @classmethod
    def from_base(cls, base_dir: Path) -> "PipelinePaths":
        return cls(
            charts_root=base_dir,
            normalized_root=base_dir / "2_normalized",
            clipped_root=base_dir / "4_clippedRasters",
            warped_root=base_dir / "5_warpedRasters",
            tiles_root=base_dir / "6_tiles",
            mbtiles_root=base_dir / "7_mbtiles",
        )


@dataclass(frozen=True)
class PipelineConfig:
    """Configuration for running the pipeline."""

    charts_base_directory: Path
    enroute_cycle: str
    chart_types: list[str]
    enable_mbtiles: bool
    enable_tile_optimization: bool

    def paths(self) -> PipelinePaths:
        return PipelinePaths.from_base(self.charts_base_directory)


PIPELINE_STEPS = (
    PipelineStep("download", "Download chart archives"),
    PipelineStep("unpack", "Unzip and normalize chart filenames"),
    PipelineStep("process", "Expand, clip, and reproject charts"),
    PipelineStep("insets", "Extract and georeference inset charts"),
    PipelineStep("tiles", "Generate map tiles"),
    PipelineStep("mbtiles", "Package tiles into MBTiles"),
    PipelineStep("merge", "Merge tilesets"),
    PipelineStep("overviews", "Generate overviews"),
)


def run_pipeline(config: PipelineConfig, *, steps: list[str] | None = None) -> None:
    """Run pipeline steps sequentially.

    This is intentionally synchronous and simple. Each step will be filled in
    with concrete implementations as the shell/perl scripts are replaced.
    """

    ensure_directories(config.paths())
    selected = steps or [step.name for step in PIPELINE_STEPS]
    for step in selected:
        _run_step(step, config)


def _run_step(step: str, config: PipelineConfig) -> None:
    """Placeholder for a pipeline step implementation."""

    print(f"[pipeline] step={step} charts_base={config.charts_base_directory}")
    if step not in {item.name for item in PIPELINE_STEPS}:
        raise ValueError(f"Unknown pipeline step: {step}")

    if step == "download":
        _todo("download", config.charts_base_directory)
    elif step == "unpack":
        _todo("unpack", config.charts_base_directory)
    elif step == "process":
        _todo("process", config.charts_base_directory)
    elif step == "insets":
        _todo("insets", config.charts_base_directory)
    elif step == "tiles":
        _todo("tiles", config.charts_base_directory)
    elif step == "mbtiles":
        _todo("mbtiles", config.charts_base_directory)
    elif step == "merge":
        _todo("merge", config.charts_base_directory)
    elif step == "overviews":
        _todo("overviews", config.charts_base_directory)


def _todo(label: str, charts_root: Path) -> None:
    """Emit a placeholder message for unimplemented steps."""

    print(f"[pipeline] TODO={label} charts_root={charts_root}")
