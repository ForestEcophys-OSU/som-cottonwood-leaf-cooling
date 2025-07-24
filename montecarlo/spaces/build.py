"""
Script to copy optimization results parameters into configuration files.

This script takes optimization results from a results.json file and copies
the parameters for a specified key into the parameters section of a
configuration file.

Usage:
    python build.py <config_file> <results_file> <key>

Example:
    python build.py config.json ../optimization/output/pressures/20250723_221432/results.json P-PD.a
"""

import json
import sys
import os
import argparse


def load_json_file(filepath):
    """Load and parse a JSON file."""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in file '{filepath}': {e}")
        sys.exit(1)


def save_json_file(filepath, data):
    """Save data to a JSON file with pretty formatting."""
    try:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=4)
    except Exception as e:
        print(f"Error: Could not save file '{filepath}': {e}")
        sys.exit(1)


def copy_parameters(config_file, results_file, key):
    """
    Copy parameters from results file to configuration file.

    Args:
        config_file (str): Path to the configuration file
        results_file (str): Path to the optimization results file
        key (str): Key to select which parameter set to copy
    """
    # Load the configuration file
    print(f"Loading configuration from: {config_file}")
    config = load_json_file(config_file)

    # Load the results file
    print(f"Loading optimization results from: {results_file}")
    results = load_json_file(results_file)

    # Check if the key exists in the results
    if key not in results:
        available_keys = list(results.keys())
        print(f"Error: Key '{key}' not found in results file.")
        print(f"Available keys: {available_keys}")
        sys.exit(1)

    # Check if the selected key has parameters
    if 'parameters' not in results[key]:
        print(f"Error: No 'parameters' section found for key '{key}'.")
        sys.exit(1)

    # Copy the parameters
    parameters_to_copy = results[key]['parameters']

    # Update the configuration
    config['parameters'] = parameters_to_copy

    # Save the updated configuration
    print(f"Saving updated configuration to: {config_file}")
    save_json_file(config_file, config)

    print("Parameters copied successfully!")


def main():
    """Main function to handle command line arguments and execute the copy operation."""
    parser = argparse.ArgumentParser(
        description="Copy optimization results parameters into configuration files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
                Example:
                python build.py config.json ../optimization/output/pressures/20250723_221432/results.json P-PD.a

                This script takes optimization results from a results.json file and copies
                the parameters for a specified key into the parameters section of a
                configuration file.
            """
    )

    parser.add_argument(
        'config_file',
        help='Path to the configuration file (e.g., config.json)'
    )

    parser.add_argument(
        'results_file',
        help='Path to the optimization results file'
    )

    parser.add_argument(
        'key',
        help='Key to select which parameter set to copy from the results file'
    )

    args = parser.parse_args()

    # Validate that files exist
    if not os.path.exists(args.config_file):
        print(f"Error: Configuration file '{args.config_file}' does not exist.")
        sys.exit(1)

    if not os.path.exists(args.results_file):
        print(f"Error: Results file '{args.results_file}' does not exist.")
        sys.exit(1)

    # Perform the copy operation
    copy_parameters(args.config_file, args.results_file, args.key)


if __name__ == "__main__":
    main()
