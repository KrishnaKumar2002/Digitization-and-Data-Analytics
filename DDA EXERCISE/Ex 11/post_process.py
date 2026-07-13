import pandas as pd
import matplotlib.pyplot as plt
import sys

if len(sys.argv) < 3:
    raise Exception("Script requires two arguments (in order): <results_file> <destination_image_file>")

results_file=sys.argv[1]
image_file_dir=sys.argv[2]

# Processing time
df_init = pd.read_csv(results_file, header=None, names=['nodes','time','cpus','pi'])

#########################################################
# Task:
# Modify following to calculate horizontal and/or verticle
# scaling
#########################################################
# Calculating average of similar configuration, if more than one runs are used
df = df_init.groupby('nodes').mean().reset_index()

# Calulate Speedup
base_time = df[df['nodes'] == df['nodes'].min()]['time'].values[0]
df['speedup'] = base_time / df['time']

# Plotting
# Create the figure and the first axis
fig, ax1 = plt.subplots()

# Plot Number of nodes vs processing time (on the first y-axis)
ax1.plot(df['nodes'], df['time'], 'g-', marker='o', label='Processing Time')
ax1.set_xlabel('Number of Nodes')
ax1.set_ylabel('Processing Time (s)', color='g')

# Plot Number of nodes vs speedup time (on the second y-axis)
ax2 = ax1.twinx()
ax2.plot(df['nodes'], df['speedup'], 'b-', marker='s', label='Speedup')
ax2.set_ylabel('Speedup', color='b')

# Legend
fig.legend(loc='upper left', bbox_to_anchor=(0.355,0.97))

# Save the plot as png
fig.tight_layout()
plt.savefig(f"{image_file_dir}/results.png",dpi=100)