from argparse import ArgumentParser
import subprocess
from garisom_tools.sa import (
    SensitivityAnalysisConfig,
    SensitivityAnalysis
)
from garisom_tools import GarisomModel
import pandas as pd
import os
from datetime import datetime
import json
from typing import Any

# For regression
import statsmodels.formula.api as smf


class CustomGarisomModel(GarisomModel):
    def __init__(self, run_kwargs: dict[str, Any] = {}, eval_kwargs: dict[str, Any] = {}):
        super().__init__(run_kwargs, eval_kwargs)

    @classmethod
    def launch_model(
        cls,
        model_dir: str,
        param_file: str,
        config_file: str,
        population: int,
        save_location: str,
        out: int = subprocess.DEVNULL,
        err: int = subprocess.DEVNULL,
        return_on_fail: bool = False,
        verbose: bool = False
    ) -> pd.DataFrame | None:

        output = super().launch_model(
            model_dir, param_file, config_file, population, save_location, out, err, return_on_fail, verbose
        )

        results = []

        if output is not None:

            output = output.iloc[:-1]

            for julian_day, group in output.groupby("julian-day"):
                model = smf.ols("leaftemp ~ Q('T-air')", data=group).fit()
                conf_int = model.conf_int()

                results.append({
                    "julian-day": julian_day,
                    "beta": model.params["Q('T-air')"],
                    "intercept": model.params['Intercept'],
                    "rsquared": model.rsquared,
                    "beta-low": conf_int.loc["Q('T-air')", 0],
                    "beta-high": conf_int.loc["Q('T-air')", 1]
                })

        result_df = pd.DataFrame(results).set_index("julian-day")
        return result_df


def get_ground_truth(population: int):
    ground_dir = "../../data/ground"
    match population:
        case 1:
            ground = pd.read_csv(os.path.abspath(f"{ground_dir}/ccr_hourly_data.csv"))
        case 2:
            ground = pd.read_csv(os.path.abspath(f"{ground_dir}/jla_hourly_data.csv"))
        case 3:
            ground = pd.read_csv(os.path.abspath(f"{ground_dir}/nrv_hourly_data.csv"))
        case 4:
            ground = pd.read_csv(os.path.abspath(f"{ground_dir}/tsz_hourly_data.csv"))
        case _:
            raise Exception("Incorrect POP_NUM!")

    return ground


def get_parameter_and_configuration_files(base_dir: str) -> tuple[str, pd.DataFrame]:
    return os.path.abspath(os.path.join(base_dir, "configuration.csv")), \
        pd.read_csv(os.path.join(base_dir, "parameters.csv"))


def main():
    parser = ArgumentParser()
    parser.add_argument(
        "--input", "-i",
        help="File path to sensitivity analysis input file.",
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
    parser.add_argument(
        "--param", "-p",
        help="Directory path to JSON file containing 'parameters' key.",
        required=False,
        type=str
    )
    parser.add_argument(
        "--param_dir", "-pd",
        help="Directory path that holds configuration and parameter files.",
        default="../DBG/",
        type=str
    )
    parser.add_argument(
        "--verbose", "-v",
        help="Enable printing model fail return.",
        action="store_true"
    )

    args = parser.parse_args()

    model_dir = os.path.abspath(args.model)
    rand_dir = datetime.now().strftime('%Y%m%d_%H%M%S')

    out_dir = os.path.join(os.path.abspath(args.output), rand_dir)
    os.makedirs(out_dir, exist_ok=True)
    config_file = os.path.join(out_dir, "config.json")

    # Get configuration and save
    config = SensitivityAnalysisConfig.from_json(args.input)
    # Copy the input config file to the output config_file path
    with open(args.input, "r") as src, open(config_file, "+x") as dst:
        dst.write(src.read())

    # Get ground truth values
    ground = get_ground_truth(config.pop)

    # Get original parameter and configuration files
    model_config, params = get_parameter_and_configuration_files(args.param_dir)

    # Overwrite base parameters if param file passed in
    if args.param:
        with open(args.param, "+r") as f:
            f = json.load(f)

            if "parameters" in f:
                for param, value in f['parameters'].items():
                    print(f"Overwritting {param} with {value}.")
                    params[param] = value
            else:
                raise Exception("No parameters found in JSON object.")

    run_kwargs = {
        'config_file': model_config,
        'params': params,
        'model_dir': model_dir,
        'population': config.pop,
        'verbose': args.verbose,
        'return_on_fail': True
    }

    eval_kwargs = {
        'ground': ground,
        'start_day': config.start_day,
        'end_day': config.end_day,
    }

    model = CustomGarisomModel(
        run_kwargs=run_kwargs,
        eval_kwargs=eval_kwargs
    )

    sa = SensitivityAnalysis(
        model=model,
        config=config
    )

    sa.run(out_dir)


if __name__ == "__main__":
    main()
