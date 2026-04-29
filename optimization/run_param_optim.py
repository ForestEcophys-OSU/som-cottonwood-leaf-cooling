# Raytune
import ray

# Arguments and output
from argparse import ArgumentParser
from datetime import datetime
import pandas as pd
import numpy as np
import json

# Optimization stuff
from garisom_tools import PotkayModel
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


def get_default_parameters() -> dict:
    """Define default Potkay model parameters."""
    return {
        'V_cmax_25': 93.878e-06,
        'J_max_25': 156.78e-6,
        'emiss': 0.97,
        'alpha': 0.5,
        'theta_c': 0.98,
        'c_a': 419.35e-6,
        'LA': 0.4,
        'omega': 0.01,
        'theta': 0.001,
        'xi': 0.5,
    }


def load_environment_data(dataset_path: str, alpha: float = 0.86) -> pd.DataFrame:
    """Load and transform dataset into Potkay environment inputs."""
    env_data = pd.read_csv(os.path.abspath(dataset_path))

    T_a = env_data['Tair_C']
    e_s = 0.611 * np.exp((17.27 * T_a) / (T_a + 237.3))
    RH_a = 1 - (env_data['D_kPa'] / e_s)
    RH_a = np.clip(RH_a, 0, 1)

    env_data = pd.DataFrame({
        'year': env_data['Year'],
        'julian_day': env_data['Day'],
        'hour': env_data['Hour'],
        'T_a': T_a,
        'RH_a': RH_a,
        'R_abs': env_data['Solar_Wm2'] * alpha,
        'PPFD': env_data['Solar_Wm2'] * 4.57 * 1e-6,
    })

    mask = env_data.notna().all(axis=1)
    env_data = env_data.loc[mask].reset_index(drop=True)

    return env_data


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
        "--env-data", "-e",
        help="Path to source dataset used to build model environment data.",
        default="../DBG/dataset.csv",
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
    os.makedirs(res_dir, exist_ok=True)

    results_file = os.path.join(res_dir, "results.json")
    config_file = os.path.join(res_dir, "config.json")

    # Get optimization config and save in output directory
    optim_config = GarisomOptimizationConfig.from_json(args.input)
    # Copy the input config file to the output config_file path
    with open(args.input, "r") as src, open(config_file, "+x") as dst:
        dst.write(src.read())

    # Load default parameters
    default_params = get_default_parameters()
    ground = get_ground_truth(optim_config.population)
    env_data = load_environment_data(
        args.env_data,
        alpha=default_params.get('alpha', 0.86)
    )

    run_kwargs = {
        'params': default_params,
        'E_range': (0, 1e-2, 1e-4),
        'env_data': env_data
    }

    eval_kwargs = {
        'ground': ground,
        'start_date': optim_config.start_date,
        'end_date': optim_config.end_date,
    }

    # Run model
    if optim_config.num_worker == -1:
        ray.init()
    else:
        ray.init(num_cpus=optim_config.num_worker)
    print(ray.cluster_resources())  # show resources available

    model = PotkayModel(run_kwargs, eval_kwargs)
    optim = Optimizer(model, optim_config, args.verbose)
    results = optim.run()

    # Save results
    try:
        results.to_json(results_file)
    except Exception:
        with open(results_file, 'w') as f:
            json.dump(results, f)


if __name__ == "__main__":
    main()
