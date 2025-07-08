from config import OptimizationConfig, ParamResults
from ray import tune

# Using Optuna to allow for multiple objective optimization
from ray.tune.search.optuna import OptunaSearch

import os
from typing import Callable


class Optimizer():
    def __init__(self, config: OptimizationConfig, model: Callable):
        self.config = config
        self.space = self._get_search_space()
        self.search = self._get_search_alg()
        self.tuner = self._get_tuner(model)

    def _get_search_space(self):
        space = {
            param_name: sampler(*param_vals) for
            param_name, (sampler, param_vals) in self.config.space.items()
        }
        return space

    def _get_search_alg(self):
        return OptunaSearch(
            metric=[metric.name for metric in self.config.metric.metrics],
            mode=self.config.metric.modes,
        )

    def _get_tuner(self, model: Callable):
        return tune.Tuner(
            model,
            tune_config=tune.TuneConfig(
                search_alg=self.search,
                num_samples=self.config.num_samples
            ),
            run_config=tune.RunConfig(
                name="garisom_hyperparam_search",
                storage_path=os.getcwd(),
                verbose=1
            ),
            param_space=self.space
        )

    def run(self) -> ParamResults:
        self.results = self.tuner.fit()
        metric_and_modes = zip(
            self.config.metric.metrics,
            self.config.metric.modes
        )

        res = {}

        for metric, mode in metric_and_modes:
            best_res = self.results.get_best_result(metric.name, mode)
            res[metric.name] = (best_res.metrics, best_res.config)

        return res
