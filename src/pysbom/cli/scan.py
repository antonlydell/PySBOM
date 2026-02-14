# PySBOM
# Copyright (C) 2026-present Anton Lydell
# SPDX-License-Identifier: GPL-3.0-or-later

"""The entry point of the sub-command `scan`."""

# Third party
import click


@click.command()
@click.pass_context
@click.argument('sources', nargs=-1, type=click.STRING)
def scan(ctx: click.Context, sources: tuple[str, ...] | None) -> None:
    """Discover Python environments and generate CycloneDX SBOMs

    \b
    Examples
    --------
    \b
    Use glob patterns from the configuration file:
        $ pysbom scan

    \b
    Provide glob patterns directly on the command line:
        $ pysbom scan "/opt/*/venv" "/opt/conda/envs/*" "/home/*/miniconda3/envs/*"

    \b
    Use recursive glob patterns:
        $ pysbom scan "/srv/**/venv"
    """
