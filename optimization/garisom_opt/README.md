# garisom-opt

Parameter optimization tools for the GARISOM model.

## Features
- Parameter optimization routines
- Model wrapper for running in Python
- Model evaluation tools
- Optimization configuration management

## Installation

You can install this package using pip (with a compatible Python version):

```bash
pip install .
```

Or using the new build system:

```bash
pip install --upgrade build
python -m build
```

## Usage

Import the package in your Python code:

```python
from garisom_opt import optimizer, model, config
```

## Requirements
- numpy
- pandas
- scipy
- matplotlib
- scikit-learn
- ray[tune]

## License
MIT
