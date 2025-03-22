import os
import sys
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

# pip install pandas matplotlib


def create_chart_from_csv(csv_path, output_dir):
    """
    Reads a CSV file, parses the Timestamp column, and generates a line chart 
    for each numeric column over time.
    """
    if not os.path.exists(csv_path):
        print(f"CSV file not found: {csv_path}")
        return None
    
    # Read the CSV into a DataFrame
    try:
        df = pd.read_csv(csv_path)
    except Exception as e:
        print(f"Error reading {csv_path}: {e}")
        return None
    
    # Check if 'Timestamp' column exists
    if 'Timestamp' not in df.columns:
        print(f"No 'Timestamp' column found in {csv_path}. Skipping chart.")
        return None
    
    # Convert Timestamp to datetime if possible
    try:
        df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    except Exception as e:
        print(f"Could not parse 'Timestamp' as datetime in {csv_path}: {e}")
        return None
    
    # Set Timestamp as the DataFrame index for easy plotting
    df.set_index('Timestamp', inplace=True)
    
    # Filter out non-numeric columns (besides Timestamp)
    numeric_cols = df.select_dtypes(include=['number']).columns
    
    if len(numeric_cols) == 0:
        print(f"No numeric columns to plot in {csv_path}.")
        return None
    
    # Create a plot for all numeric columns in this CSV
    plt.figure(figsize=(10, 6))
    
    # Plot each numeric column
    for col in numeric_cols:
        plt.plot(df.index, df[col], label=col)
    
    # Title and labels
    filename = os.path.basename(csv_path)
    plt.title(f"Chart for {filename}")
    plt.xlabel("Timestamp")
    plt.ylabel("Value")
    plt.legend()
    plt.tight_layout()
    
    # Create output filename (replace .csv with .png)
    base_name = os.path.splitext(filename)[0]
    chart_name = base_name + ".png"
    output_path = os.path.join(output_dir, chart_name)
    
    # Save the figure
    plt.savefig(output_path)
    plt.close()
    
    print(f"Chart saved to: {output_path}")
    return output_path


def main():
    """
    Reads five known CSV files and creates a chart for each.
    """
    # Directory containing your CSVs (adjust if needed)
    artifacts_dir = r"C:\buildAgentFull\artifacts"
    
    # CSV filenames
    csv_files = [
        "performance_results_interaction.csv",
        "performance_results_network.csv",
        "performance_results_overall.csv",
        "performance_results_stability.csv",
        "performance_results_visual.csv"
    ]
    
    # Optional: You can allow a command-line arg for artifacts_dir
    if len(sys.argv) > 1:
        artifacts_dir = sys.argv[1]
    
    # Ensure output directory for charts (could be same as artifacts_dir)
    output_dir = artifacts_dir
    
    for csv_file in csv_files:
        csv_path = os.path.join(artifacts_dir, csv_file)
        create_chart_from_csv(csv_path, output_dir)


if __name__ == "__main__":
    main()
