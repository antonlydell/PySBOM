# PySBOM
# Copyright (C) 2026-present Anton Lydell
# SPDX-License-Identifier: GPL-3.0-or-later

"""The entry point of the PySBOM CLI."""

# Third party
import click

# Local
from pysbom.cli.scan import scan
from pysbom.metadata import __release_date__


@click.group(
    name='pysbom',
    context_settings={'help_option_names': ['-h', '--help'], 'max_content_width': 1000},
)
@click.version_option(
    message=(
        f'%(prog)s, version: %(version)s, release date: {__release_date__}, maintainer: Anton Lydell'
    )
)
@click.pass_context
def main(ctx: click.Context) -> None:
    """PySBOM - Python Software Bill of Materials (SBOM)"""


for cmd in (scan,):
    main.add_command(cmd)

if __name__ == '__main__':
    main()
