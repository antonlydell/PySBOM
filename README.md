# 🛡️ PySBOM

[![PyPI](https://img.shields.io/pypi/v/PySBOM?color=%23F37726&logo=pypi&logoColor=white)](https://pypi.org/project/PySBOM/)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue?logo=python&logoColor=white)](https://pypi.org/project/PySBOM/)
[![License](https://img.shields.io/github/license/antonlydell/PySBOM?color=blue&logoColor=white)](https://github.com/antonlydell/PySBOM/blob/main/LICENSE)

---


*Automatically discover Python environments and generate CycloneDX SBOMs at scale — built for security teams.*

**PySBOM** (Python Software Bill of Materials) is a CLI tool that discovers Python environments on
servers and generates standardized SBOM files for each of them.

It targets operational infrastructure where multiple `venv` and `conda` environments exist across
systems and manual tracking becomes impractical.

PySBOM produces SBOMs in the [CycloneDX](https://cyclonedx.org) format, an OWASP-supported industry
standard for software bill of materials.

---


## ✨ Why PySBOM?

Security teams need reliable visibility into what is installed in production and server environments:

- 🔍 Dependency visibility across systems
- 📦 Standardized SBOM generation
- 🔐 Supply chain transparency
- 📜 License awareness
- ⚙️ Controlled, repeatable automation

PySBOM focuses on deterministic environment discovery (you define the search scope) and scalable SBOM
generation across many environments.

---


## ⚙️ How It Works

1. You provide one or more **glob patterns** that define where environments may exist.
2. PySBOM discovers matching `venv` and `conda` environments within that scope.
3. It extracts installed package metadata from each discovered environment.
4. It generates **one CycloneDX SBOM per environment**.

This approach ensures predictable, repeatable SBOM generation aligned with your defined infrastructure
boundaries.

---


## 🔎 How PySBOM Differs from Project-Level SBOM Tools

Project-level tools generate SBOMs for a single application or environment.

PySBOM complements them by automatically discovering Python environments across servers and generating
SBOMs at infrastructure scale — helping security teams maintain supply chain visibility across operational
systems.

---


## 📦 Installation

Install from [PyPI](https://pypi.org/project/PySBOM/):

```bash
pip install PySBOM
```

---


## 🚀 Example Usage

Provide glob patterns as positional arguments:

```bash
pysbom scan "/opt/*/venv" "/opt/conda/envs/*" "/home/*/miniconda3/envs/*"
```

### Recursive discovery with `**`

Use `**` to match at arbitrary nesting depths (useful when layouts vary between hosts):

```bash
pysbom scan "/srv/**/venv" "/home/**/miniconda3/envs/*"
```

**Pattern tips:**
- Prefer a small set of known roots (e.g. `/opt`, `/srv`, `/home`) to keep discovery controlled.
- Quote patterns to prevent your shell from expanding them before PySBOM receives them.
- Use `**` when you expect inconsistent nesting, but keep the root tight (e.g. `/srv/**/venv`, not `/**/venv`).

---


## ⚠️ Project Status

PySBOM is under active development and not yet production-ready.
Interfaces and behavior may change until the first stable release.

---


## 📄 License

PySBOM is distributed under the [GNU General Public License v3.0 ](https://www.gnu.org/licenses/gpl-3.0-standalone.html)
(GPL-3.0-or-later). See the `LICENSE` file for details.
