# PySBOM
# Copyright (C) 2026-present Anton Lydell
# SPDX-License-Identifier: GPL-3.0-or-later

"""PySBOM — Automated discovery and SBOM generation for Python environments

PySBOM (Python Software Bill of Materials) is a CLI tool that discovers Python
environments on servers and generates standardized SBOM files for each of them.
"""

# Local
from pysbom.metadata import (
    __release_date__,
    __version__,
    __version_info__,
)

# The Public API
__all__ = [
    # metadata
    '__release_date__',
    '__version__',
    '__version_info__',
]
