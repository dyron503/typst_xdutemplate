#!/usr/bin/env python
# coding: utf-8

import csv
import numpy as np
from scipy import stats
import pandas as pd
import logging
import os

# --- Logger Setup ---
LOG_FILE_NAME = 'processing_log.txt'
# Ensure the log file is in the same directory as the script or data files
# Assuming script is in Data directory or one level up and Data folder exists
log_file_path = os.path.join(os.path.dirname(__file__), LOG_FILE_NAME) 
# If Data folder is fixed relative to script, adjust as: 
# script_dir = os.path.dirname(__file__)
# log_file_path = os.path.join(script_dir, '..', 'Data', LOG_FILE_NAME) # If script is one level below Data
# For this case, assuming Data folder is where CSVs are, and log should go there too.
# The user's current file path is c:\Users\dyrn5\OneDrive\桌面\毕业设计\typist\typst_xdutemplate\Data\analyze_latency.py
# So, os.path.dirname(__file__) will be c:\Users\dyrn5\OneDrive\桌面\毕业设计\typist\typst_xdutemplate\Data

logger = logging.getLogger('LatencyAnalysis')
logger.setLevel(logging.INFO) # Set to DEBUG for more verbose logging

# Create file handler
fh = logging.FileHandler(log_file_path, mode='w') # 'w' to overwrite log each run
fh.setLevel(logging.INFO)

# Create console handler (optional, if you want logs in console too)
# ch = logging.StreamHandler()
# ch.setLevel(logging.INFO)

# Create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
# ch.setFormatter(formatter)

# Add the handlers to the logger
logger.addHandler(fh)
# logger.addHandler(ch) 

# --- End Logger Setup ---

def parse_log_line(line):
    """解析单条日志行以提取相关数据。"""
    logger.debug(f"尝试解析行: {line}")
    try:
        if "LATENCY_LOG," not in line:
            logger.info(f"跳过行: 未找到 'LATENCY_LOG,'。行: {line}")
            return None
        
        data_str = line.split("LATENCY_LOG,", 1)[1]
        data_parts = data_str.split(',')
        
        if len(data_parts) < 4:
            logger.info(f"跳过格式错误的行 (LATENCY_LOG, 后部分不足): {line}")
            return None
            
        action = data_parts[0].strip()
        prev_end_ts = float(data_parts[1].strip())
        curr_end_ts = float(data_parts[2].strip())
        logged_interval_seconds = float(data_parts[3].strip())

        if curr_end_ts <= prev_end_ts:
            logger.info(f"因时间戳无效 (CurrEnd_TS <= PrevEnd_TS) 跳过行: {line}")
            return None 
        
        parsed_result = {
            "action": action,
            "prev_end_ts": prev_end_ts,
            "curr_end_ts": curr_end_ts,
            "interval_ms": logged_interval_seconds * 1000 # 转换为毫秒
        }
        logger.debug(f"成功解析行: {line}. 结果: {parsed_result}")
        return parsed_result
    except Exception as e:
        logger.error(f"解析行时出错: {line}. 错误: {e}", exc_info=True)
        return None

def process_csv_file(file_path):
    """处理单个CSV文件并提取延迟数据。"""
    logger.info(f"开始处理文件: {file_path}")
    valid_intervals = []
    actions_data = {}
    line_count = 0
    parsed_count = 0
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line_count += 1
                line = line.strip() 
                if not line: 
                    logger.debug(f"跳过空行，行号: {line_count}")
                    continue
                
                parsed_data = parse_log_line(line)
                if parsed_data:
                    parsed_count += 1
                    valid_intervals.append(parsed_data["interval_ms"])
                    action = parsed_data["action"]
                    if action not in actions_data:
                        actions_data[action] = []
                    actions_data[action].append(parsed_data["interval_ms"])
        logger.info(f"文件处理完成: {file_path}. 总行数: {line_count}, 解析行数: {parsed_count}, 有效间隔数: {len(valid_intervals)}")
    except FileNotFoundError:
        logger.error(f"文件未找到: {file_path}")
        print(f"错误: 文件未找到 {file_path}") # 保留控制台输出以处理关键错误
    except Exception as e:
        logger.error(f"处理文件 {file_path} 时出错: {e}", exc_info=True)
        print(f"处理文件 {file_path} 时出错: {e}") # 保留控制台输出
                
    return valid_intervals, actions_data

def calculate_statistics(intervals, data_label="Overall"):
    """计算间隔列表的描述性统计数据。"""
    logger.info(f"为 '{data_label}' 计算统计数据，数据点数量: {len(intervals)}.")
    if not intervals:
        logger.info(f"未提供 '{data_label}' 的间隔数据，返回 NaN 统计信息。")
        return {
            "count": 0,
            "mean": np.nan,
            "median": np.nan,
            "std_dev": np.nan,
            "min": np.nan,
            "max": np.nan,
            "q1": np.nan,
            "q3": np.nan,
            "cv": np.nan # 变异系数
        }
    
    data = np.array(intervals)
    mean = np.mean(data)
    median = np.median(data)
    std_dev = np.std(data)
    min_val = np.min(data)
    max_val = np.max(data)
    q1 = np.percentile(data, 25)
    q3 = np.percentile(data, 75)
    cv = (std_dev / mean) * 100 if mean != 0 else np.nan
    
    stats_results = {
        "count": len(data),
        "mean": mean,
        "median": median,
        "std_dev": std_dev,
        "min": min_val,
        "max": max_val,
        "q1": q1,
        "q3": q3,
        "cv": cv
    }
    logger.info(f"'{data_label}' 的统计结果: 计数={stats_results['count']}, 平均值={stats_results['mean']:.2f}, 中位数={stats_results['median']:.2f}, CV={stats_results['cv']:.2f}%")
    return stats_results

def print_statistics(label, stats_data, action_stats_data=None):
    logger.info(f"开始打印 {label} 的整体统计信息")
    print(f"\n--- {label} 统计信息 (整体) ---")
    if stats_data["count"] > 0:
        logger.info(f"{label} 的整体统计数据: {stats_data}") 
        print(f"  有效条目数: {stats_data['count']}")
        print(f"  平均延迟: {stats_data['mean']:.2f} ms")
        print(f"  中位数延迟: {stats_data['median']:.2f} ms")
        print(f"  标准差: {stats_data['std_dev']:.2f} ms")
        print(f"  最小延迟: {stats_data['min']:.2f} ms")
        print(f"  最大延迟: {stats_data['max']:.2f} ms")
        print(f"  25百分位数 (Q1): {stats_data['q1']:.2f} ms")
        print(f"  75百分位数 (Q3): {stats_data['q3']:.2f} ms")
        print(f"  变异系数 (CV): {stats_data['cv']:.2f}% (越低越稳定)")
    else:
        logger.info(f"未找到 {label} 的有效整体数据。")
        print("  未找到有效数据。")

    if action_stats_data:
        logger.info(f"开始打印 {label} 的各操作类型统计信息")
        print(f"\n--- {label} 统计信息 (按操作类型) ---")
        for action, data in action_stats_data.items():
            action_label = f"{label} - 操作: {action}"
            action_s = calculate_statistics(data, data_label=action_label) # 传递特定于操作的标签
            if action_s["count"] > 0:
                logger.info(f"{action_label} 的统计数据: {action_s}")
                print(f"  操作: {action}")
                print(f"    有效条目数: {action_s['count']}")
                print(f"    平均延迟: {action_s['mean']:.2f} ms")
                print(f"    中位数延迟: {action_s['median']:.2f} ms")
                print(f"    标准差: {action_s['std_dev']:.2f} ms")
                print(f"    变异系数: {action_s['cv']:.2f}% ")
            else:
                logger.info(f"未找到 {action_label} 的有效数据。")
                print(f"  操作: {action} - 未找到有效数据。")
    logger.info(f"完成打印 {label} 的统计信息")

def compare_platforms(stats1, label1, stats2, label2, intervals1, intervals2):
    logger.info(f"开始在 {label1} 和 {label2} 之间进行平台比较。")
    print("\n--- 平台比较 --- ")
    if stats1['count'] == 0 or stats2['count'] == 0:
        logger.warning(f"无法执行平台比较: 一个或两个数据集没有有效数据。{label1} 计数: {stats1['count']}, {label2} 计数: {stats2['count']}.")
        print("无法执行比较: 一个或两个数据集没有有效数据。")
        return
        
    # 统计检验
    data1 = np.array(intervals1)
    data2 = np.array(intervals2)
    
    # 独立样本t检验
    t_stat, p_value = stats.ttest_ind(data1, data2, equal_var=False)
    
    # Mann-Whitney U检验（非参数检验）
    u_stat, p_value_mw = stats.mannwhitneyu(data1, data2)
    
    print(f"独立样本t检验: t={t_stat:.3f}, p={p_value:.5f}")
    print(f"Mann-Whitney U检验: U={u_stat:.1f}, p={p_value_mw:.5f}")
    
    # 新增分段分析功能
    def analyze_segments(data):
        segments = []
        current_segment = []
        
        for interval in data:
            if interval < 100:  # 有效间隔阈值(ms)
                current_segment.append(interval)
            else:
                if current_segment:
                    segments.append(current_segment)
                    current_segment = []
        
        if current_segment:
            segments.append(current_segment)
        
        return segments
    
    print("\n--- 分段分析结果 ---")
    print(f"{label1} 分段统计:")
    for i, seg in enumerate(analyze_segments(data1)):
        print(f"段{i+1}: {len(seg)}个样本, 均值={np.mean(seg):.1f}ms")
    
    print(f"\n{label2} 分段统计:")
    for i, seg in enumerate(analyze_segments(data2)):
        print(f"段{i+1}: {len(seg)}个样本, 均值={np.mean(seg):.1f}ms")

    comparison_details = f"比较 {label1} (N={stats1['count']}) vs {label2} (N={stats2['count']}):\n"
    comparison_details += f"  平均延迟: {label1} = {stats1['mean']:.2f} ms, {label2} = {stats2['mean']:.2f} ms\n"
    comparison_details += f"  中位数延迟: {label1} = {stats1['median']:.2f} ms, {label2} = {stats2['median']:.2f} ms\n"
    comparison_details += f"  标准差: {label1} = {stats1['std_dev']:.2f} ms, {label2} = {stats2['std_dev']:.2f} ms\n"
    comparison_details += f"  变异系数: {label1} = {stats1['cv']:.2f}%, {label2} = {stats2['cv']:.2f}%"
    logger.info(comparison_details)
    print(comparison_details)

    if stats1['count'] > 0 and stats2['count'] > 0:
        logger.info(f"在 {label1} 和 {label2} 之间执行 Mann-Whitney U 检验。")
        try:
            u_statistic, p_value = stats.mannwhitneyu(intervals1, intervals2, alternative='two-sided')
            mwu_results = f"\n  Mann-Whitney U 检验 (比较中位数/分布):\n"
            mwu_results += f"    U统计量: {u_statistic:.2f}\n"
            mwu_results += f"    P值: {p_value:.4f}\n"
            interpretation = "显著差异" if p_value < 0.05 else "无显著差异"
            mwu_results += f"    解释: 两个平台之间存在{interpretation} (p {'<' if p_value < 0.05 else '>='} 0.05)。"
            logger.info(f"{label1} vs {label2} 的 Mann-Whitney U 检验: U={u_statistic:.2f}, P值={p_value:.4f}. 解释: {interpretation}")
            print(mwu_results)
        except ValueError as e:
            logger.error(f"无法为 {label1} vs {label2} 执行 Mann-Whitney U 检验: {e}", exc_info=True)
            print(f"    无法执行 Mann-Whitney U 检验: {e}")
            print("    如果一个样本中的所有值都相同，或者样本量太小，则可能发生这种情况。")
    logger.info(f"完成在 {label1} 和 {label2} 之间的平台比较。")


def main():
    logger.info("=== 脚本执行开始 ===")
    controller_file = r'c:\Users\dyrn5\OneDrive\桌面\毕业设计\typist\typst_xdutemplate\Data\ControllerInput.csv'
    keyboard_file = r'c:\Users\dyrn5\OneDrive\桌面\毕业设计\typist\typst_xdutemplate\Data\KeyboardInput.csv'

    logger.info(f"手柄数据文件: {controller_file}")
    print(f"处理 {controller_file}...")
    controller_intervals, controller_actions_data = process_csv_file(controller_file)
    controller_stats = calculate_statistics(controller_intervals, data_label="手柄输入整体")
    print_statistics("手柄输入", controller_stats, controller_actions_data)

    logger.info(f"键盘数据文件: {keyboard_file}")
    print(f"\n处理 {keyboard_file}...")
    keyboard_intervals, keyboard_actions_data = process_csv_file(keyboard_file)
    keyboard_stats = calculate_statistics(keyboard_intervals, data_label="键盘输入整体")
    print_statistics("键盘输入", keyboard_stats, keyboard_actions_data)

    logger.info("执行整体平台比较。")
    if controller_stats['count'] > 0 and keyboard_stats['count'] > 0:
        compare_platforms(controller_stats, "手柄", keyboard_stats, "键盘", controller_intervals, keyboard_intervals)
    else:
        logger.warning("因一个或两个平台数据缺失，跳过整体平台比较。")
        print("\n--- 平台比较 ---")
        print("因数据缺失，跳过比较。")

    logger.info("评估平台稳定性。")
    print("\n--- 平台稳定性评估 ---")
    print("通过变异系数 (CV) 和标准差评估稳定性。")
    print("CV越低表示稳定性越高 (相对于平均值的变异性较小)。")
    if controller_stats['count'] > 0:
        logger.info(f"手柄输入稳定性: CV={controller_stats['cv']:.2f}%, 标准差={controller_stats['std_dev']:.2f} ms")
        print(f"  手柄输入稳定性 (CV): {controller_stats['cv']:.2f}% (标准差: {controller_stats['std_dev']:.2f} ms)")
    else:
        logger.info("手柄输入: 无数据可评估稳定性。")
        print("  手柄输入: 无数据可评估稳定性。")
    if keyboard_stats['count'] > 0:
        logger.info(f"键盘输入稳定性: CV={keyboard_stats['cv']:.2f}%, 标准差={keyboard_stats['std_dev']:.2f} ms")
        print(f"  键盘输入稳定性 (CV): {keyboard_stats['cv']:.2f}% (标准差: {keyboard_stats['std_dev']:.2f} ms)")
    else:
        logger.info("键盘输入: 无数据可评估稳定性。")
        print("  键盘输入: 无数据可评估稳定性。")

    logger.info("执行跨平台一致性的详细操作分解。")
    print("\n--- 跨平台一致性的详细操作分解 ---")
    all_actions = set(controller_actions_data.keys()).union(set(keyboard_actions_data.keys()))
    action_comparison_data = []

    for action in sorted(list(all_actions)):
        logger.info(f"比较操作: {action}")
        print(f"\n比较操作: {action}")
        c_intervals = controller_actions_data.get(action, [])
        k_intervals = keyboard_actions_data.get(action, [])
        
        c_stats = calculate_statistics(c_intervals, data_label=f"手柄 - 操作: {action}")
        k_stats = calculate_statistics(k_intervals, data_label=f"键盘 - 操作: {action}")

        action_row = {'操作': action} # Changed 'Action' to '操作' for consistency in Chinese output table

        if c_stats['count'] > 0:
            print(f"  手柄 - {action}: 平均值={c_stats['mean']:.2f}ms, 中位数={c_stats['median']:.2f}ms, 标准差={c_stats['std_dev']:.2f}ms, CV={c_stats['cv']:.2f}%, N={c_stats['count']}")
            action_row['手柄平均值 (ms)'] = c_stats['mean']
            action_row['手柄中位数 (ms)'] = c_stats['median']
            action_row['手柄标准差 (ms)'] = c_stats['std_dev']
            action_row['手柄CV (%)'] = c_stats['cv']
            action_row['手柄N'] = c_stats['count']
        else:
            logger.info(f"手柄 - 操作 {action}: 无数据")
            print(f"  手柄 - {action}: 无数据")
            action_row.update({k: np.nan for k in ['手柄平均值 (ms)', '手柄中位数 (ms)', '手柄标准差 (ms)', '手柄CV (%)', '手柄N']})

        if k_stats['count'] > 0:
            print(f"  键盘 - {action}: 平均值={k_stats['mean']:.2f}ms, 中位数={k_stats['median']:.2f}ms, 标准差={k_stats['std_dev']:.2f}ms, CV={k_stats['cv']:.2f}%, N={k_stats['count']}")
            action_row['键盘平均值 (ms)'] = k_stats['mean']
            action_row['键盘中位数 (ms)'] = k_stats['median']
            action_row['键盘标准差 (ms)'] = k_stats['std_dev']
            action_row['键盘CV (%)'] = k_stats['cv']
            action_row['键盘N'] = k_stats['count']
        else:
            logger.info(f"键盘 - 操作 {action}: 无数据")
            print(f"  键盘 - {action}: 无数据")
            action_row.update({k: np.nan for k in ['键盘平均值 (ms)', '键盘中位数 (ms)', '键盘标准差 (ms)', '键盘CV (%)', '键盘N']})

        if c_stats['count'] > 0 and k_stats['count'] > 0:
            logger.info(f"在手柄和键盘之间为操作 {action} 执行 Mann-Whitney U 检验。")
            try:
                u_stat, p_val = stats.mannwhitneyu(c_intervals, k_intervals, alternative='two-sided')
                interpretation = '显著差异' if p_val < 0.05 else '无显著差异'
                logger.info(f"{action} 的 Mann-Whitney U 检验: p值 = {p_val:.4f} ({interpretation})")
                print(f"    {action} 的 Mann-Whitney U 检验: p值 = {p_val:.4f} ({interpretation})")
                action_row['P值 (Mann-Whitney U)'] = p_val
            except ValueError as e_mwu:
                logger.error(f"无法为操作 {action} 执行 Mann-Whitney U 检验: {e_mwu}", exc_info=True)
                print(f"    无法为操作 {action} 执行 Mann-Whitney U 检验 (例如，所有值相同或样本量小)。")
                action_row['P值 (Mann-Whitney U)'] = np.nan
        else:
             logger.info(f"因一个或两个平台数据不足，跳过操作 {action} 的 Mann-Whitney U 检验。")
             action_row['P值 (Mann-Whitney U)'] = np.nan
        
        action_comparison_data.append(action_row)

    if action_comparison_data:
        logger.info("生成操作比较的摘要表。")
        comparison_df = pd.DataFrame(action_comparison_data)
        if '操作' in comparison_df.columns: # Changed 'Action' to '操作'
            comparison_df = comparison_df.set_index('操作') # Changed 'Action' to '操作'
        print("\n\n--- 摘要表: 跨平台操作比较 ---")
        try:
            df_string = comparison_df.to_string()
            logger.info(f"摘要表:\n{df_string}")
            print(df_string)
        except Exception as e_df:
            logger.error(f"将 comparison_df 转换为字符串时出错: {e_df}", exc_info=True)
            print("生成摘要表字符串时出错。")
    else:
        logger.info("无操作数据可比较以生成摘要表。")
        print("\n无操作数据可比较。")
    logger.info("=== 脚本执行完毕 ===")

if __name__ == '__main__':
    main()