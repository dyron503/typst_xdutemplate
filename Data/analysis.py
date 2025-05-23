import pandas as pd
import numpy as np
from scipy import stats
import os

# --- Configuration ---
# Path for the controller data (assuming it's the file you showed snippets from)
controller_file_path = "ControllerInput.csv" # Or "input_file_0.csv" if that's the actual name

# Path for the keyboard data - YOU MUST UPDATE THIS
keyboard_file_path = "KeyboardInput.csv" # <<< IMPORTANT: UPDATE THIS PATH to your keyboard log data file

ARTIFACT_LATENCY_THRESHOLD_MS = 500 # Latencies above this on a suspected segment reset line will be filtered (e.g., 500ms)
RESET_DROP_SECONDS = 0.5 # Absolute drop in input_ts to suspect a reset
RESET_FACTOR = 0.5       # Relative drop in input_ts to suspect a reset (e.g., current < previous * 0.5)

equivalence_delta = 3.0 # Equivalence margin in ms for TOST
alpha = 0.05 # Significance level

report_sections = []
filtered_counts = {"controller": 0, "keyboard": 0}

def add_to_report(title, content):
    report_sections.append(f"\n--- {title} ---\n{content}")

def parse_latency_log_file(filepath, device_name):
    latencies_ms = []
    previous_input_ts = None
    processed_lines = 0
    valid_latency_lines = 0

    if not os.path.exists(filepath):
        add_to_report(f"错误 - {device_name} 数据文件未找到", f"文件路径 '{filepath}' 无效或文件不存在。")
        return pd.Series([], dtype=float)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                processed_lines += 1
                try:
                    if "LATENCY_LOG," in line:
                        parts = line.split("LATENCY_LOG,")
                        if len(parts) > 1:
                            data_part = parts[1].strip()
                            values = data_part.split(',')
                            # Expected: Operation, InputTS, ResponseTS, LatencyDuration
                            if len(values) == 4 and values[0].strip().lower() == "move":
                                op_type = values[0].strip()
                                current_input_ts = float(values[1].strip())
                                response_ts = float(values[2].strip()) # Now used for filtering
                                latency_s = float(values[3].strip())

                                # Sanity check (optional, but good for understanding logs)
                                # calculated_latency_s = abs(response_ts - current_input_ts)
                                # if abs(calculated_latency_s - latency_s) > 0.001 : # epsilon
                                #     print(f"Warning ({device_name}): Line {i+1}: Discrepancy in calculated latency. Provided: {latency_s:.3f}, Calc: {calculated_latency_s:.3f}")

                                potential_artifact = False
                                
                                # Check Condition 1: InputTS sequence reset
                                if previous_input_ts is not None:
                                    if current_input_ts < previous_input_ts * RESET_FACTOR and \
                                       (previous_input_ts - current_input_ts) > RESET_DROP_SECONDS:
                                        if (latency_s * 1000) > ARTIFACT_LATENCY_THRESHOLD_MS:
                                            potential_artifact = True
                                            # Optional: print(f"Debug ({device_name}): Line {i+1}: Potential artifact (type 1: InputTS sequence reset) {latency_s*1000:.2f}ms. PrevInputTS: {previous_input_ts:.3f}, CurrInputTS: {current_input_ts:.3f}")

                                # Check Condition 2: Intra-line reset (ResponseTS <= InputTS), only if not already flagged
                                if not potential_artifact: 
                                    if response_ts <= current_input_ts: # Changed to '<=' and removed inner latency check
                                        potential_artifact = True
                                        # Optional: print(f"Debug ({device_name}): Line {i+1}: Potential artifact (type 2: Intra-line reset RspTS <= InpTS). InputTS: {current_input_ts:.3f}, RspTS: {response_ts:.3f}, Latency: {latency_s*1000:.2f}ms")
                                
                                # Final decision based on whether any check flagged it as an artifact
                                if potential_artifact:
                                     filtered_counts[device_name.lower()] += 1
                                else:
                                    latencies_ms.append(latency_s * 1000) # Convert to ms
                                    valid_latency_lines +=1
                                
                                previous_input_ts = current_input_ts
                except ValueError:
                    # print(f"Warning ({device_name}): Could not parse numeric value from line {i+1}: {line.strip()}")
                    pass # Silently skip lines with parsing errors for numeric values
                except Exception as e_line:
                    # print(f"Warning ({device_name}): Error processing line {i+1} '{line.strip()}': {e_line}")
                    pass
    except Exception as e_file:
        add_to_report(f"错误 - 读取或解析 {device_name} 文件时出错",
                      f"处理文件 '{filepath}' 时发生错误: {e_file}")
        return pd.Series([], dtype=float)

    if not latencies_ms:
        add_to_report(f"警告 - {device_name} 数据提取",
                      f"未能从文件 '{filepath}' 中提取任何有效的 'Move' 操作延迟数据 (after filtering).\n"
                      f"Processed lines: {processed_lines}. Valid latency lines added: {valid_latency_lines}. Filtered artifacts: {filtered_counts[device_name.lower()]}.\n"
                      f"确保文件包含 'LATENCY_LOG,Move,InputTS,ResponseTS,LatencyValue' 格式的行。")
    return pd.Series(latencies_ms, dtype=float)


def describe_data(series, name):
    # (Function remains the same as your provided working version)
    if series.empty or len(series) < 2 :
        return (f"  有效条目数: {len(series)}\n"
                f"  数据不足，无法计算完整的描述性统计。")
    # ... (rest of the describe_data function as in your provided output script) ...
    q1 = series.quantile(0.25)
    q3 = series.quantile(0.75)
    median = series.median()
    cv = (series.std() / series.mean()) * 100 if series.mean() != 0 else 0
    iqr = q3 - q1
    # Handle cases where IQR might be 0 to avoid division by zero or nonsensical bounds
    if iqr == 0:
        # If IQR is 0, outlier bounds are typically Q1 and Q3 themselves.
        # For this specific case, we'll define bounds that are slightly offset if Q1=Q3
        # or simply state that any deviation is an outlier.
        # Given the previous output, this method makes sense.
        lower_bound_outlier = q1 
        upper_bound_outlier = q3
        if q1 == q3:
             outlier_desc = f"any value != {q1:.2f} ms (since Q1=Q3)"
        else:
             outlier_desc = f"< {lower_bound_outlier:.2f} ms or > {upper_bound_outlier:.2f} ms (IQR=0)"

    else:
        lower_bound_outlier = q1 - 1.5 * iqr
        upper_bound_outlier = q3 + 1.5 * iqr
        outlier_desc = f"< {lower_bound_outlier:.2f} ms or > {upper_bound_outlier:.2f} ms (1.5*IQR rule)"

    outliers = series[(series < lower_bound_outlier) | (series > upper_bound_outlier)]
    # Specific fix for when Q1=Q3, then outliers are anything not equal to Q1/Q3
    if q1 == q3:
        outliers = series[series != q1]


    return (
        f"  有效条目数: {len(series)}\n"
        f"  平均延迟: {series.mean():.2f} ms\n"
        f"  中位数延迟: {median:.2f} ms\n"
        f"  标准差: {series.std():.2f} ms\n"
        f"  最小延迟: {series.min():.2f} ms\n"
        f"  最大延迟: {series.max():.2f} ms\n"
        f"  25百分位数 (Q1): {q1:.2f} ms\n"
        f"  75百分位数 (Q3): {q3:.2f} ms\n"
        f"  四分位数间距 (IQR): {iqr:.2f} ms\n"
        f"  变异系数 (CV): {cv:.2f}% (越低越稳定)\n"
        f"  离群点识别界限: {outlier_desc}\n"
        f"  识别出的潜在离群点数量: {len(outliers)} (示例值: {list(np.unique(outliers.values[:5])) if not outliers.empty else 'N/A'}{'...' if len(np.unique(outliers.values)) > 5 else ''})"
    )

# --- Main script execution ---
try:
    add_to_report("数据加载与预处理",
                  f"尝试从以下路径加载、解析和过滤数据:\n"
                  f"  手柄: {controller_file_path}\n"
                  f"  键盘: {keyboard_file_path} (请确保此路径正确并指向格式相似的文件)\n"
                  f"潜在的跨段伪影延迟值 (InputTS重置时 > {ARTIFACT_LATENCY_THRESHOLD_MS}ms) 将被过滤。")

    controller_latency = parse_latency_log_file(controller_file_path, "Controller")
    keyboard_latency = parse_latency_log_file(keyboard_file_path, "Keyboard")

    add_to_report("预处理总结 - 伪影过滤",
                  f"  手柄: {filtered_counts['controller']} 个潜在的伪影延迟值被过滤。\n"
                  f"  键盘: {filtered_counts['keyboard']} 个潜在的伪影延迟值被过滤。")

    if controller_latency.empty:
        add_to_report("手柄数据问题", "未能从手柄数据文件中加载任何有效延迟数据。后续分析可能不完整或失败。")
    if keyboard_latency.empty:
        add_to_report("键盘数据问题", "未能从键盘数据文件中加载任何有效延迟数据。后续分析可能不完整或失败。")

    # --- Descriptive Statistics ---
    add_to_report("手柄输入 描述性统计 (过滤后)", describe_data(controller_latency, "手柄"))
    add_to_report("键盘输入 描述性统计 (过滤后)", describe_data(keyboard_latency, "键盘"))

    if len(controller_latency) < 20 or len(keyboard_latency) < 20: # Increased threshold for meaningful analysis
        add_to_report("分析警示", "一个或两个数据集的数据量较少 (少于20个有效条目)。统计结果的可靠性可能较低。")
        if len(controller_latency) < 2 or len(keyboard_latency) < 2:
             raise ValueError("数据不足，无法进行完整的推断性统计分析。")


    # --- Assumption Checking for t-test ---
    # Shapiro-Wilk test might be slow/unreliable for very large N, but let's keep it as per previous script
    shapiro_controller_stat, shapiro_controller_p = stats.shapiro(controller_latency) if len(controller_latency) < 5000 else (np.nan, np.nan)
    shapiro_keyboard_stat, shapiro_keyboard_p = stats.shapiro(keyboard_latency) if len(keyboard_latency) < 5000 else (np.nan, np.nan)
    normality_note = "(注: p < {alpha} 表明数据显著偏离正态分布。对于大样本(N > ~50)，此检验非常敏感；对于N>5000，已跳过检验。建议结合直方图/QQ图判断。)" if len(controller_latency) >=5000 or len(keyboard_latency) >=5000 else "(注: p < {alpha} 表明数据显著偏离正态分布。对于大样本(N > ~50)，此检验非常敏感。)"

    normality_report = (
        f"  手柄 - Shapiro-Wilk: W={shapiro_controller_stat:.4f}, p={shapiro_controller_p:.4e} "
        f"({'不满足正态性' if shapiro_controller_p < alpha else '近似正态分布' if not np.isnan(shapiro_controller_p) else '跳过 (N>5000)'})\n"
        f"  键盘 - Shapiro-Wilk: W={shapiro_keyboard_stat:.4f}, p={shapiro_keyboard_p:.4e} "
        f"({'不满足正态性' if shapiro_keyboard_p < alpha else '近似正态分布' if not np.isnan(shapiro_keyboard_p) else '跳过 (N>5000)'})\n"
        f"{normality_note}"
    )
    add_to_report("正态性检验 (Shapiro-Wilk)", normality_report)

    levene_stat, levene_p = stats.levene(controller_latency, keyboard_latency)
    homogeneity_report = (
        f"  Levene's Test: W={levene_stat:.4f}, p={levene_p:.4e} "
        f"({'方差不齐性' if levene_p < alpha else '满足方差齐性'})\n"
        f"(注: p < {alpha} 表明两组方差不相等)"
    )
    add_to_report("方差齐性检验 (Levene's Test)", homogeneity_report)

    # --- Inferential Statistics ---
    inferential_results = []
    equal_var_flag = levene_p >= alpha
    t_stat, t_p_value = stats.ttest_ind(controller_latency, keyboard_latency, equal_var=equal_var_flag, nan_policy='omit')
    inferential_results.append(
        f"  独立样本 t-检验 (equal_var={equal_var_flag}):\n"
        f"    t-statistic = {t_stat:.3f}\n"
        f"    p-value = {t_p_value:.4e}\n"
        f"    解释: {'差异不显著' if t_p_value >= alpha else '均值存在显著差异'} (p {'<' if t_p_value < alpha else '>='} {alpha})"
    )

    u_stat, u_p_value = stats.mannwhitneyu(controller_latency, keyboard_latency, alternative='two-sided', nan_policy='omit')
    inferential_results.append(
        f"\n  Mann-Whitney U 检验:\n"
        f"    U-statistic = {u_stat:.1f}\n"
        f"    p-value = {u_p_value:.4e}\n"
        f"    解释: {'分布无显著差异' if u_p_value >= alpha else '分布存在显著差异'} (p {'<' if u_p_value < alpha else '>='} {alpha})"
    )
    add_to_report("推断性统计检验 (过滤后数据)", "\n".join(inferential_results))

    # --- Effect Size Calculation ---
    effect_size_results = []
    n1, n2 = len(controller_latency), len(keyboard_latency)
    m1, m2_val = controller_latency.mean(), keyboard_latency.mean()
    s1, s2 = controller_latency.std(ddof=1), keyboard_latency.std(ddof=1) # ddof=1 for sample std dev

    if (n1 + n2 - 2) > 0:
         pooled_std = np.sqrt(((n1 - 1) * s1**2 + (n2 - 1) * s2**2) / (n1 + n2 - 2)) if (n1 + n2 - 2) > 0 else 0
         cohen_d = (m1 - m2_val) / pooled_std if pooled_std != 0 else 0
    else:
        cohen_d = 0
        pooled_std = 0
    effect_size_results.append(
        f"  Cohen's d (针对t检验的均值差异):\n"
        f"    d = {cohen_d:.3f} (池化标准差: {pooled_std:.2f} ms)\n"
        f"    解释指南: |d|≈0.2 '小效应', |d|≈0.5 '中效应', |d|≈0.8 '大效应'"
    )

    mean_U = n1 * n2 / 2.0
    std_U = np.sqrt(n1 * n2 * (n1 + n2 + 1) / 12.0) if (n1 + n2 + 1) > 0 else 0
    # Adjust U for Z calculation: U for Z should be min(U1, U2) or use direct Z from scipy if available.
    # Scipy's u_stat for two-sided is U1 = R1 - n1(n1+1)/2.
    # Z = (U1 - n1*n2/2) / std_U
    z_mw = (u_stat - mean_U) / std_U if std_U !=0 else 0
    r_biserial_abs = np.abs(z_mw) / np.sqrt(n1 + n2) if (n1 + n2) > 0 else 0

    effect_size_results.append(
        f"\n  Rank Biserial Correlation (r) (针对Mann-Whitney U的分布差异):\n"
        f"    (基于计算的Z值: {z_mw:.3f})\n"
        f"    |r| = {r_biserial_abs:.3f} (绝对值)\n"
        f"    解释指南: |r|≈0.1 '小效应', |r|≈0.3 '中效应', |r|≈0.5 '大效应'"
    )
    add_to_report("效应量计算 (过滤后数据)", "\n".join(effect_size_results))

    # --- Equivalence Testing (TOST) for means ---
    d_obs = m1 - m2_val
    tost_report_parts = [f"  等效边界 (Delta): +/- {equivalence_delta:.2f} ms"]
    tost_report_parts.append(f"  观察到的平均值差异 (手柄 - 键盘): {d_obs:.2f} ms")
    
    df_tost = n1+n2-2
    if df_tost > 0 :
        s_p_squared = ((n1 - 1) * s1**2 + (n2 - 1) * s2**2) / df_tost
        if (1/n1 + 1/n2) > 0 and s_p_squared >=0:
            se_diff = np.sqrt(s_p_squared * (1/n1 + 1/n2))
        else:
            se_diff = 0
    else:
        se_diff = 0

    if se_diff > 0:
        t_lower = (d_obs - (-equivalence_delta)) / se_diff
        p_lower = 1 - stats.t.cdf(t_lower, df=df_tost)

        t_upper = (d_obs - equivalence_delta) / se_diff
        p_upper = stats.t.cdf(t_upper, df=df_tost)

        tost_report_parts.append(f"  TOST p-value (下边界): {p_lower:.4e} (检验 手柄均值-键盘均值 > -{equivalence_delta:.2f} ms)")
        tost_report_parts.append(f"  TOST p-value (上边界): {p_upper:.4e} (检验 手柄均值-键盘均值 < +{equivalence_delta:.2f} ms)")

        equivalence_achieved = (p_lower < alpha) and (p_upper < alpha)
        tost_report_parts.append(f"  等效性结论 (基于alpha={alpha}): {'达到等效性' if equivalence_achieved else '未达到等效性'}")

        conf_level_tost = 1 - 2 * alpha
        t_crit_tost = stats.t.ppf(1 - alpha, df=df_tost)
        ci_lower = d_obs - t_crit_tost * se_diff
        ci_upper = d_obs + t_crit_tost * se_diff
        tost_report_parts.append(f"  均值差值的 {conf_level_tost*100:.0f}% 置信区间: [{ci_lower:.2f} ms, {ci_upper:.2f} ms]")
        ci_within_bounds = (ci_lower > -equivalence_delta) and (ci_upper < equivalence_delta)
        tost_report_parts.append(f"  该置信区间是否完全落在 [+/-{equivalence_delta:.2f} ms] 内: {ci_within_bounds}")
    else:
        tost_report_parts.append("  无法计算TOST (标准误差为0或自由度不足)。")
    add_to_report("等效性检验 (TOST) - 比较平均值 (过滤后数据)", "\n".join(tost_report_parts))

except ValueError as ve: # Catch the specific error for insufficient data
     add_to_report("分析中止", str(ve))
except Exception as e:
    add_to_report("脚本执行时发生主要意外错误", f"错误信息: {str(e)}\n请检查数据文件和脚本逻辑。")

# --- Generate Full Report ---
print("="*80)
print("数据分析报告 (已改进伪影过滤)")
print("="*80)
for section_content in report_sections:
    print(section_content)
    print("-"*80)

print("\n报告结束。")