# PySBOM
# Copyright (C) 2026-present Anton Lydell
# SPDX-License-Identifier: GPL-3.0-or-later

"""Metadata about the PySBOM package."""

# Standard library
from datetime import date

__version_info__ = (0, 1, 0)
"""PySBOM version as a comparable tuple (MAJOR, MINOR, PATCH), following SemVer."""

__version__ = '.'.join(str(v) for v in __version_info__)
"""The PySBOM version string."""

__release_date__ = date(2026, 2, 14)
"""The release date of the current version."""
