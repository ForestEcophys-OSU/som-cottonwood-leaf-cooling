# Raytune
import ray

# Arguments and output
from argparse import ArgumentParser
from datetime import datetime
import pandas as pd

# Optimization stuff
from garisom_tools import GarisomModel
from garisom_tools.optimization import Optimizer, GarisomOptimizationConfig
import os


def get_ground_truth(population: int):
    ground_dir = "../data/ground"
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
    parser.add_argument(
        "--verbose", "-v",
        help="Set Raytune verbosity level: 0 (silent), 1 (default), 2 (debug).",
        choices=[0, 1, 2],
        type=int,
        default=1
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

    # Get optimization config and save in output directory
    optim_config = GarisomOptimizationConfig.from_json(args.input)
    # Copy the input config file to the output config_file path
    with open(args.input, "r") as src, open(config_file, "+x") as dst:
        dst.write(src.read())

    # Get ground truth values
    ground = get_ground_truth(optim_config.population)

    # Get original parameter and configuration files
    model_config, params = get_parameter_and_configuration_files()

    run_kwargs = {
        'config_file': model_config,
        'params': params,
        'model_dir': model_dir,
        'population': optim_config.population
    }

    eval_kwargs = {
        'ground': ground,
        'start_day': optim_config.start_day,
        'end_day': optim_config.end_day,
    }

    # Run model
    if optim_config.num_worker == -1:
        ray.init()
    else:
        ray.init(num_cpus=optim_config.num_worker)
    print(ray.cluster_resources())  # show resources available

    model = GarisomModel(run_kwargs, eval_kwargs)
    optim = Optimizer(model, optim_config, args.verbose)
    results = optim.run()

    # Save results
    results.to_json(results_file)


if __name__ == "__main__":
    main()
