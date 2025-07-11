# Raytune
from ray import tune

# Basic data utils
import pandas as pd
import numpy as np
from typing import Callable
from abc import abstractmethod, ABC

# For model evaluation
import os
import subprocess
from tempfile import TemporaryDirectory
from functools import partial

# Optimizer stuff
from .config import (
    OptimizationConfig,
    GarisomOptimizationConfig,
    MetricConfig,
    EvalResults
)


class Model(ABC):
    def __init__(
            self,
            optim_config: OptimizationConfig,
            run_kwargs: dict,
            eval_kwargs: dict
    ):
        self.optim_config = optim_config
        self.metric = optim_config.metric
        self.run_kwargs = run_kwargs
        self.eval_kwargs = eval_kwargs

    @staticmethod
    @abstractmethod
    def run(X, *args, **kwargs):
        pass

    @staticmethod
    @abstractmethod
    def launch_model(*args, **kwargs):
        pass

    @staticmethod
    @abstractmethod
    def evaluate_model(*args, **kwargs) -> EvalResults:
        pass

    def get_objective(
        self
    ) -> Callable:
        return partial(
            self.run,
            **self.run_kwargs
        )

    def setup_model_and_return_callable(self) -> Callable:

        objective = self.get_objective()

        def wrapped_model(config: dict) -> None:
            out = objective(config)
            errs = self.evaluate_model(
                out,
                metric_config=self.metric,
                **self.eval_kwargs,
            )
            tune.report(errs)

        return wrapped_model


class GarisomModel(Model):
    def __init__(
            self,
            optim_config: GarisomOptimizationConfig,
            run_kwargs: dict,
            eval_kwargs: dict
    ):
        super().__init__(optim_config, run_kwargs=run_kwargs, eval_kwargs=eval_kwargs)

    @staticmethod
    def run(
        X: dict[str, float],
        params: pd.DataFrame,
        config_file: str,
        population: int,
        model_dir: str,
        **kwargs
    ) -> pd.DataFrame:
        with TemporaryDirectory() as tmp:
            # Get unique TMP_DIR and make directory for specific process
            TMP_PARAM_FILE = f"{tmp}/params.csv"

            # Overwrite parameters with sample params
            for i, name in enumerate(X.keys()):
                params.at[population - 1, name] = X[name]

            # Setup parameter, configuration, and output files
            params.to_csv(TMP_PARAM_FILE, index=False)

            output = GarisomModel.launch_model(
                model_dir=model_dir,
                param_file=TMP_PARAM_FILE,
                config_file=config_file,
                population=population,
                save_location=tmp,
                **kwargs
            )

        return output

    @staticmethod
    def launch_model(
        model_dir: str,
        param_file: str,
        config_file: str,
        population: int,
        save_location: str,
        out: int = subprocess.DEVNULL
    ) -> pd.DataFrame | None:

        params = pd.read_csv(param_file)

        p = subprocess.run(
            [
                "./run",
                param_file,
                config_file,
                str(population),
                save_location
            ],
            cwd=model_dir,
            stdout=out,
            stderr=out
        )

        if p.returncode != 0:
            return None

        # Get species, region, and site to determine output file
        species = params.at[population - 1, 'i_sp']
        region = params.at[population - 1, 'i_region']
        site = params.at[population - 1, 'i_site']

        output_file = os.path.join(
            save_location, f"timesteps_output_{species}_{region}_{site}.csv"
        )
        if not os.path.exists(output_file):
            raise FileNotFoundError(
                f"Expected output file not found: {output_file}"
            )

        out = pd.read_csv(output_file)

        return out

    @staticmethod
    def evaluate_model(
        output,
        ground,
        metric_config: MetricConfig,
        start_day: int,
        end_day: int
    ) -> EvalResults:

        out_names = [metric.output_name for metric in metric_config.metrics]
        pred = output[out_names].to_numpy(dtype=float) if output is not None else None

        metrics = metric_config.metrics
        modes = metric_config.modes

        errors = {}
        for idx, (metric, mode) in enumerate(zip(metrics, modes)):

            output_name = metric.output_name
            optim_name = metric.name
            eval_func = metric.func

            if pred is None:
                err = 1e20 if mode == 'min' else -1e20
            else:
                # Filter ground data based on julian-day and drop NaN values
                col_ground = ground[
                    ground['julian-day'].between(start_day, end_day)
                ][output_name].dropna()

                ground_values = np.array([col_ground.to_numpy()]).squeeze(axis=0)

                # Align predictions with the filtered ground data
                col_pred = pred[:, idx]  # (T)
                col_pred = pd.DataFrame(col_pred)
                pred_values = col_pred.loc[col_ground.index].T.to_numpy().squeeze(axis=0)

                err = eval_func(ground_values, pred_values)

            errors[optim_name] = err

        return errors
