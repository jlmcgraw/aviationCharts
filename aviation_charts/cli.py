"""CLI entrypoint for the aviation charts pipeline."""

from __future__ import annotations

import argparse
from pathlib import Path

from aviation_charts.pipeline import PIPELINE_STEPS, PipelineConfig, run_pipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Aviation charts pipeline")
    parser.add_argument(
        "--charts-base-directory",
        type=Path,
        required=True,
        help="Root directory where chart data is stored",
    )
    parser.add_argument(
        "--enroute-cycle",
        required=True,
        help="Enroute cycle (e.g. 12-10-2015)",
    )
    parser.add_argument(
        "--chart-types",
        nargs="+",
        default=[],
        help="Chart types to process (e.g. sectional enroute tac)",
    )
    parser.add_argument(
        "--enable-mbtiles",
        action="store_true",
        help="Enable MBTiles generation",
    )
    parser.add_argument(
        "--enable-tile-optimization",
        action="store_true",
        help="Enable per-tile PNG optimization",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("all", help="Run the full pipeline")
    steps_parser = subparsers.add_parser("steps", help="Run selected steps")
    steps_parser.add_argument(
        "steps",
        nargs="+",
        choices=[step.name for step in PIPELINE_STEPS],
        help="Pipeline steps to run in order",
    )

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    config = PipelineConfig(
        charts_base_directory=args.charts_base_directory,
        enroute_cycle=args.enroute_cycle,
        chart_types=list(args.chart_types),
        enable_mbtiles=bool(args.enable_mbtiles),
        enable_tile_optimization=bool(args.enable_tile_optimization),
    )

    if args.command == "all":
        run_pipeline(config)
    elif args.command == "steps":
        run_pipeline(config, steps=args.steps)
    else:
        parser.error("Unknown command")


if __name__ == "__main__":
    main()
