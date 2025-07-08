# Raytune
import ray
from ray import tune

# Basic data utils
import pandas as pd
import numpy as np
import json
from typing import Callable

# For model evaluation
import os
import subprocess
from tempfile import TemporaryDirectory
from functools import partial

# Arguments and output
from argparse import ArgumentParser
from datetime import datetime

# Optimizer
from optimizer import Optimizer
from config import OptimizationConfig, EvalResults


def launch_garisom(
    model_dir: str,
    param_file: str,
    config_file: str,
    population_num: int,
    save_location: str,
    out: int = subprocess.DEVNULL
) -> pd.DataFrame | None:

    params = pd.read_csv(param_file)

    p = subprocess.run(
        [
            "./run",
            param_file,
            config_file,
            str(population_num),
            save_location
        ],
        cwd=model_dir,
        stdout=out,
        stderr=out
    )

    if p.returncode != 0:
        return None

    # Get species, region, and site to determine output file
    species = params.at[population_num - 1, 'i_sp']
    region = params.at[population_num - 1, 'i_region']
    site = params.at[population_num - 1, 'i_site']

    output_file = os.path.join(
        save_location, f"timesteps_output_{species}_{region}_{site}.csv"
    )
    if not os.path.exists(output_file):
        raise FileNotFoundError(
            f"Expected output file not found: {output_file}"
        )

    out = pd.read_csv(output_file)

    return out


def evaluate_model(
    ground,
    pred,
    config: OptimizationConfig
) -> EvalResults:

    metrics = config.metric.metrics
    modes = config.metric.modes
    start_day = config.start_day
    end_day = config.end_day

    errors = {}
    for idx, (metric, mode) in enumerate(zip(metrics, modes)):

        output_name = metric.output_name
        optim_name = metric.name
        eval_func = metric.func

        if pred is None:
            err = float('inf') if mode == 'min' else -float('inf')
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


def run_model_and_get_results(
    X: dict[str, float],
    config: OptimizationConfig,
    ground: pd.DataFrame,
    params: pd.DataFrame,
    **kwargs
) -> EvalResults:
    in_names = config.space.keys()
    out_names = [metric.output_name for metric in config.metric.metrics]
    population_num = config.population

    with TemporaryDirectory() as tmp:
        # Get unique TMP_DIR and make directory for specific process
        TMP_PARAM_FILE = f"{tmp}/params.csv"

        # Overwrite parameters with sample params
        for i, name in enumerate(in_names):
            params.at[population_num - 1, name] = X[name]

        # Setup parameter, configuration, and output files
        params.to_csv(TMP_PARAM_FILE, index=False)

        output = launch_garisom(
            population_num=population_num,
            param_file=TMP_PARAM_FILE,
            save_location=tmp,
            **kwargs
        )

        pred = output[out_names].to_numpy(dtype=float) if output is not None else None

        eval_res = evaluate_model(ground, pred, config)

    return eval_res


def get_ground_truth(config: OptimizationConfig):
    match config.population:
        case 1:
            ground = pd.read_csv(os.path.abspath("../data/ccr_hourly_data.csv"))
        case 2:
            ground = pd.read_csv(os.path.abspath("../data/jla_hourly_data.csv"))
        case 3:
            ground = pd.read_csv(os.path.abspath("../data/tsz_hourly_data.csv"))
        case 4:
            ground = pd.read_csv(os.path.abspath("../data/nrv_hourly_data.csv"))
        case _:
            raise Exception("Incorrect POP_NUM!")

    return ground


def get_parameter_and_configuration_files() -> tuple[str, pd.DataFrame]:
    return os.path.abspath("../DBG/configuration.csv"), \
           pd.read_csv("../DBG/parameters.csv")


def get_objective(
    config: OptimizationConfig,
    **kwargs
) -> Callable:
    return partial(
        run_model_and_get_results,
        config=config,
        **kwargs
    )


def setup_model_and_return_callable(
    config: OptimizationConfig,
    **kwargs
) -> Callable:

    objective = get_objective(config, **kwargs)

    def wrapped_model(config: dict) -> None:
        res = objective(config)
        tune.report(res)

    return wrapped_model


def main():
    parser = ArgumentParser()
    parser.add_argument(
        "--input", "-i",
        help="File path to optimization file.",
        required=True,
        type=str
    )
    parser.add_argument(
        "--output", "-o",
        help="Directory path for output files.",
        default=".",
        type=str
    )
    parser.add_argument(
        "--model", "-m",
        help="Directory path to model executable.",
        required=True,
        type=str
    )
    args = parser.parse_args()

    # Setup output directories and files
    out_dir = os.path.join(args.output)
    rand_dir = datetime.now().strftime('%Y%m%d_%H%M%S')
    run_name = args.input.split(".json")[0]
    if i := run_name.rfind("/"):
        run_name = run_name[i+1:]

    res_dir = os.path.join(out_dir, run_name, rand_dir)
    model_dir = os.path.abspath(args.model)
    os.makedirs(res_dir, exist_ok=True)

    results_file = os.path.join(res_dir, "results.json")
    config_file = os.path.join(res_dir, "config.json")

    # Get config and save in output directory
    config = OptimizationConfig.from_json(args.input)
    # Copy the input config file to the output config_file path
    with open(args.input, "r") as src, open(config_file, "+x") as dst:
        dst.write(src.read())

    # Get ground truth values
    ground = get_ground_truth(config)

    # Get original parameter and configuration files
    model_config, params = get_parameter_and_configuration_files()

    kwargs = {
        'ground': ground,
        'config_file': model_config,
        'params': params,
        'model_dir': model_dir
    }

    # Run model
    ray.init(num_cpus=config.num_worker)
    model = setup_model_and_return_callable(
        config,
        **kwargs
    )
    optim = Optimizer(config, model)
    results = optim.run()

    # Save results
    with open(results_file, "+x") as f:
        json.dump(results, f)


if __name__ == "__main__":
    main()
