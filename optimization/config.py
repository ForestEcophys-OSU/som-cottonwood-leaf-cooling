# Typing stuff
from dataclasses import dataclass, asdict
import json
from typing import Callable, Any

# Calculations
import numpy as np

# Sampling distributions
from optuna.distributions import FloatDistribution
from scipy.special import ndtri
from scipy.stats import truncnorm, norm

# Metrics
from metric import Metric, Mode

# TODO, refactor SpaceConfig and ParamResults into proper dataclasses
SpaceConfig = dict[str, tuple[Callable, list[float]]]
ParamResults = dict[str, tuple[dict[str, Any], dict[str, float]]]
EvalResults = dict[np.ndarray]


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
            "uniform": FloatDistribution,
            "normal": TruncatedNormalDistribution,
        }
        space_config = {}
        for k, v in data.items():
            dist_type = v[0].lower()
            params = v[1]
            if dist_type not in mapping:
                raise ValueError(f"Unknown distribution type: {dist_type}")
            space_config[k] = (mapping[dist_type], params)
        return space_config


class NormalDistribution(FloatDistribution):
    def __init__(self, mu, sigma):
        self.mu = mu
        self.sigma = sigma
        # For internal uniform sampling, map [low, high] to [0, 1]
        self.low = 1e-8
        self.high = 1 - 1e-8
        super().__init__(self.low, self.high)

    def single(self) -> bool:
        return False

    def _contains(self, param):
        return isinstance(param, float) and self.low <= param <= self.high

    def _sample(self, rng):
        # Sample p ~ Uniform(0,1)
        p = rng.uniform(self.low, self.high)
        # Transform to normal
        return self.mu + self.sigma * ndtri(p)

    def to_internal_repr(self, param):
        # Transform normal value back to uniform p for internal sampler state
        p = norm.cdf(param, loc=self.mu, scale=self.sigma)
        return p

    def to_external_repr(self, internal_param):
        # Transform uniform p to normal value
        return self.mu + self.sigma * ndtri(internal_param)


class TruncatedNormalDistribution(FloatDistribution):
    def __init__(self, mu, sigma, a=1, b=1e12):
        self.mu = mu
        self.sigma = sigma
        self.a = a
        self.b = b

        # Calculate standardized bounds for truncnorm
        self._a_std = (a - mu) / sigma
        self._b_std = (b - mu) / sigma

        # Internal uniform sampling bounds in (0,1)
        self.low = 1e-8
        self.high = 1 - 1e-8

        super().__init__(self.low, self.high)

    def single(self) -> bool:
        return False

    def _contains(self, param):
        return isinstance(param, float) and self.a <= param <= self.b

    def _sample(self, rng):
        # Uniform p in [low, high]
        p = rng.uniform(self.low, self.high)
        # Sample from truncated normal using inverse CDF
        return truncnorm.ppf(p, self._a_std, self._b_std, loc=self.mu, scale=self.sigma)

    def to_internal_repr(self, param):
        # Map external value to internal uniform p
        p = truncnorm.cdf(param, self._a_std, self._b_std, loc=self.mu, scale=self.sigma)
        return min(max(p, self.low), self.high)

    def to_external_repr(self, internal_param):
        # Map internal uniform p to truncated normal value
        return truncnorm.ppf(internal_param, self._a_std, self._b_std, loc=self.mu, scale=self.sigma)
