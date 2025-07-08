from dataclasses import dataclass, asdict
import json
from typing import Callable, Any
from enum import Enum
from ray import tune
from sklearn.metrics import (
    mean_squared_error,
    r2_score,
    root_mean_squared_error,
    mean_absolute_percentage_error,
    median_absolute_error
)
import numpy as np

type SpaceConfig = dict[str, tuple[Callable, list[float]]]
type ParamResults = dict[str, tuple[dict[str, Any], dict[str, float]]]
type EvalResults = dict[np.ndarray]


@dataclass
class Metric:
    name: str
    output_name: str
    func: Callable

    @staticmethod
    def from_name(metric_name: str, optim_name: str) -> "Metric":
        mapping = {
            "mse": MSE,
            "rmse": RMSE,
            "r2": R2,
            "mape": MAPE,
            "made": MADE,
        }

        # Get metric class
        metric_cls = mapping.get(metric_name.lower())
        if metric_cls is None:
            raise ValueError(f"Unknown metric name: {metric_name}")

        # Check if name is hyphenated, indicating name is different from output
        # Optuna doesn't allow for 'metric' names to be the same, so we need to
        # differentiate between duplicates of outputs when using different
        # metrics. Ex: PD-A and PD-B must both be mapped to PD.
        output_name = optim_name
        if i := optim_name.rfind("-"):
            output_name = optim_name[:i]

        return metric_cls(output_name, optim_name)


# Evaluation Metrics
class MSE(Metric):
    def __init__(self, output_name: str, name: str = "mse"):
        super().__init__(name=name, output_name=output_name, func=mean_squared_error)


class RMSE(Metric):
    def __init__(self, output_name: str, name: str = "rmse"):
        super().__init__(name=name, output_name=output_name, func=root_mean_squared_error)


class R2(Metric):
    def __init__(self, output_name: str, name: str = "r2"):
        super().__init__(name=name, output_name=output_name, func=r2_score)


class MAPE(Metric):
    def __init__(self, output_name: str, name: str = "mape"):
        super().__init__(name=name, output_name=output_name, func=mean_absolute_percentage_error)


class MADE(Metric):
    def __init__(self, output_name: str, name: str = "made"):
        super().__init__(name=name, output_name=output_name, func=median_absolute_error)


# Evaluation Modes
class Mode(str, Enum):
    MAX = "max"
    MIN = "min"

    @staticmethod
    def from_name(name: str) -> "Mode":
        try:
            return Mode(name.lower())
        except ValueError:
            raise ValueError(f"Unknown mode: {name}")


@dataclass
class MetricConfig:
    metrics: list[Metric]
    modes: list[Mode]

    @classmethod
    def from_dict(cls, data: dict):
        params = data.get("params", [])
        metrics = data.get("metrics", [])
        metrics = [Metric.from_name(m, p) for m, p in zip(metrics, params)]
        modes = [Mode.from_name(m) for m in data.get("modes", [])]
        return cls(metrics=metrics, modes=modes)


@dataclass
class OptimizationConfig:
    space: SpaceConfig = None
    metric: MetricConfig = None
    num_worker: int = 4
    num_samples: int = 100
    population: int = 1
    start_day: int = 201
    end_day: int = 236

    @classmethod
    def from_json(cls, infile: str):
        """
        Creates an instance of the class from a JSON file.

        Args:
            infile (str): Path to the JSON file containing the configuration data.

        Returns:
            cls: An instance of the class initialized with data loaded from the JSON file.

        Raises:
            FileNotFoundError: If the specified file does not exist.
            json.JSONDecodeError: If the file is not a valid JSON.
            TypeError: If the data loaded from the file does not match the expected class signature.
        """
        with open(infile, "r") as f:
            data = json.load(f)
        data['metric'] = MetricConfig.from_dict(data["metric"]) if "metric" in data else None
        data['space'] = cls.parse_space(data['space']) if 'space' in data else None
        return cls(**data)

    def to_json(self, outfile):
        """
        Serializes the object to a JSON file.

        Args:
            outfile (str): The path to the output file where the JSON representation will be saved.

        Notes:
            The method uses the object's __dict__ attribute for serialization,
            which means all instance attributes will be included in the JSON output.
        """
        with open(outfile, "+x") as f:
            json.dump(asdict(self), f, indent=2)

    @staticmethod
    def parse_space(data: dict) -> SpaceConfig:
        mapping = {
            "uniform": tune.uniform,
            "normal": tune.randn,
        }
        space_config = {}
        for k, v in data.items():
            dist_type = v[0].lower()
            params = v[1]
            if dist_type not in mapping:
                raise ValueError(f"Unknown distribution type: {dist_type}")
            space_config[k] = (mapping[dist_type], params)
        return space_config
