from garisom_tools.montecarlo import Sim, GarisomMonteCarloConfig
from garisom_tools import GarisomModel
import os
import pandas as pd
from argparse import ArgumentParser
from datetime import datetime


def get_parameter_and_configuration_files() -> tuple[str, pd.DataFrame]:
    return os.path.abspath("../DBG/configuration.csv"), \
        pd.read_csv("../DBG/parameters.csv")


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

    config_file = os.path.join(res_dir, "config.json")

    # Get optimization config and save in output directory
    mc_config = GarisomMonteCarloConfig.from_json(args.input)
    X = mc_config.parameters  # Get passed in default param replacements

    # Copy the input config file to the output config_file path
    with open(args.input, "r") as src, open(config_file, "+x") as dst:
        dst.write(src.read())

    # Get MonteCarloConfig, model, and model config/parameters
    model = GarisomModel()

    model_config, params = get_parameter_and_configuration_files()

    # Set run kwargs for model
    run_kwargs = {
        'config_file': model_config,
        'params': params,
        'model_dir': model_dir,
        'population': mc_config.population,
        'return_on_fail': True  # Needed to compute statistics
    }

    # Get other arguments
    num_samples = mc_config.num_samples
    workers = mc_config.num_worker

    # These are index columns that will not change between samples and therefore
    # need to be excluded from any statistic calculations
    index_columns = ['year', 'julian-day', 'standard-time', 'solar', 'rain', 'wind', 'T-air', 'T-soil', 'D-MD']

    # Instantiate Sim class, run, and analyze results
    sim = Sim(model, mc_config, run_kwargs=run_kwargs)
    outputs = sim.run(num_samples, workers=workers, X=X)
    stats = sim.analyze(outputs, index_columns=index_columns)

    stats.save(res_dir)


if __name__ == "__main__":
    main()
