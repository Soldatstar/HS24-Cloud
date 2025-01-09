import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

cpu_file = "cpu_usage.csv"
mem_file = "mem_usage.csv"

cpu_df = pd.read_csv(cpu_file, sep=';', parse_dates=["Time"], dayfirst=True)
cpu_df.iloc[:, 1:] = cpu_df.iloc[:, 1:].replace({r'%': ''}, regex=True).astype(float)
print("CPU Dataframe head:")
print(cpu_df.head())
mem_df = pd.read_csv(mem_file, sep=';', parse_dates=["Time"], dayfirst=True)
mem_df.iloc[:, 1:] = mem_df.iloc[:, 1:].replace({r' MiB': ''}, regex=True).astype(float)

frameworks = ["spring-native-simple", "quarkus-jvm", "quarkus-native", "micronaut-native", "micronaut-jvm", "spring-jvm-simple"]
palette = sns.color_palette("tab10", n_colors=len(frameworks))
color_dict = {framework: palette[i] for i, framework in enumerate(frameworks)}
#Original
#plt.figure(figsize=(12, 6), dpi=200)
#for column in cpu_df.columns[1:]:
#    plt.plot(cpu_df["Time"], cpu_df[column], label=column)
#plt.title("CPU Usage Over Time")
#plt.xlabel("Time")
#plt.ylabel("CPU Usage (%)")
#plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
#plt.grid()
#plt.tight_layout()
#plt.show()



#Original
#plt.figure(figsize=(12, 6), dpi=200)
#for column in mem_df.columns[1:]:
#    plt.plot(mem_df["Time"], mem_df[column], label=column)
#plt.title("Memory Usage Over Time")
#plt.xlabel("Time")
#plt.ylabel("Memory Usage (MiB)")
#plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
#plt.grid()
#plt.tight_layout()
#plt.show()

cpu_smoothed_df = cpu_df.copy()
cpu_smoothed_df.iloc[:, 1:] = cpu_df.iloc[:, 1:].rolling(window=6, center=True).mean()

plt.figure(figsize=(12, 6), dpi=200)
for column in cpu_smoothed_df.columns[1:]:
    plt.plot(cpu_smoothed_df["Time"], cpu_smoothed_df[column], label=column,color=color_dict[column])
plt.title("Smoothed CPU Usage Over Time")
plt.xlabel("Time")
plt.ylabel("CPU Usage (%)")
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.grid()
plt.tight_layout()
plt.xlim(cpu_smoothed_df["Time"].min(), cpu_smoothed_df["Time"].max())
plt.show()

mem_smoothed_df = mem_df.copy()
mem_smoothed_df.iloc[:, 1:] = mem_df.iloc[:, 1:].rolling(window=14, center=True).mean()

plt.figure(figsize=(12, 6), dpi=200)
for column in mem_smoothed_df.columns[1:]:
    plt.plot(mem_smoothed_df["Time"], mem_smoothed_df[column], label=column, color=color_dict[column])
plt.title("Smoothed Memory Usage Over Time")
plt.xlabel("Time")
plt.ylabel("Memory Usage (MiB)")
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.grid()
plt.tight_layout()
plt.xlim(mem_smoothed_df["Time"].min(), mem_smoothed_df["Time"].max())
plt.show()

cpu_stats = cpu_df.describe()
print("CPU Usage Statistics:")
print(cpu_stats)

mem_stats = mem_df.describe()
print("\nMemory Usage Statistics:")
print(mem_stats)

cpu_median = cpu_df.median()
cpu_std = cpu_df.std()

print("\nCPU Usage Median:")
print(cpu_median)
print("\nCPU Usage Standard Deviation:")
print(cpu_std)

mem_median = mem_df.median()
mem_std = mem_df.std()

print("\nMemory Usage Median:")
print(mem_median)
print("\nMemory Usage Standard Deviation:")
print(mem_std)

cpu_avg = cpu_df.mean()
print("\nAverage CPU Usage:")
print(cpu_avg)

mem_avg = mem_df.mean()
print("\nAverage Memory Usage:")
print(mem_avg)


