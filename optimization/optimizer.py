from config import OptimizationConfig, ParamResults
from ray import tune

# Using Optuna to allow for multiple objective optimization
from ray.tune.search.optuna import OptunaSearch

import os
from typing import Callable
from collections import defaultdict
from optuna.samplers import TPESampler


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
            space=self.space,
            metric=[metric.name for metric in self.config.metric.metrics],
            mode=self.config.metric.modes,
            sampler=TPESampler(
                n_startup_trials=0
            )
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
            )
        )

    def run(self) -> ParamResults:
        self.results = self.tuner.fit()
        metric_and_modes = zip(
            self.config.metric.metrics,
            self.config.metric.modes
        )

        res = defaultdict(dict)

        # Get best results for each metric and save the corresponding scores
        # and parameters
        for metric, mode in metric_and_modes:
            best_res = self.results.get_best_result(metric.name, mode)
            res['metrics'] = {
                name: score for name, score in best_res.metrics.items()
                if name in [m.name for m in self.config.metric.metrics]
            }
            res['parameters'][metric.name] = best_res.config

        return res
