# Typing stuff
from dataclasses import dataclass, asdict
import json

# Calculations
import numpy as np

# Sampling distributions
from optuna.distributions import FloatDistribution, BaseDistribution
from .distributions import (
    NormalDistribution,
    TruncatedNormalDistribution
)

# Metrics
from .metric import Metric, Mode


EvalResults = dict[np.ndarray]


@dataclass
class MetricResult:
    scores: dict[str, float]
    parameters: dict[str, float]

    def to_dict(self): return asdict(self)


class ParamResults(dict[str, MetricResult]):
    def to_dict(self):
        return {k: v.to_dict() for k, v in self.items()}

    def to_json(self, outfile: str):
        with open(outfile, "+x") as f:
            json.dump(self.to_dict(), f)


@dataclass
class SampleSpace:
    distribution: BaseDistribution
    parameters: tuple[float]

    def unpack(self):
        return (self.distribution, self.parameters)


SpaceConfig = dict[str, SampleSpace]


def parse_space(data: dict) -> SpaceConfig:
    mapping = {
        "uniform": FloatDistribution,
        "norm": NormalDistribution,
        "truncnorm": TruncatedNormalDistribution,
    }
    space_config = {}
    for k, v in data.items():
        dist_type = v[0].lower()
        params = v[1]
        if dist_type not in mapping:
            raise ValueError(f"Unknown distribution type: {dist_type}")
        space_config[k] = SampleSpace(
            distribution=mapping[dist_type],
            parameters=tuple(params)
        )
    return SpaceConfig(space_config)


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
        data['space'] = parse_space(data['space']) if 'space' in data else None
        return cls(**data)

    def to_json(self, outfile: str):
        """
        Serializes the object to a JSON file.

        Args:
            outfile (str): The path to the output file where the JSON representation will be saved.

        Notes:
            The method uses the object's __dict__ attribute for serialization,
            which means all instance attributes will be included in the JSON output.
        """
        with open(outfile, "+x") as f:
            json.dump(asdict(self), f)


@dataclass
class GarisomOptimizationConfig(OptimizationConfig):
    population: int = 1
    start_day: int = 201
    end_day: int = 236
