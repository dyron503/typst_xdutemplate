ControllerInput.csv KeyboardInput.csv

LogBlueprintUserMessages: [BP_LatencyLogger_C_1] LATENCY_LOG,Move,0.021,0.038,0.017

我们可以将这条日志分解为以下几个部分及其含义：

LogBlueprintUserMessages:

含义： 这是Unreal Engine的標準前綴，表明這條消息是通過藍圖中的 Print String 節點輸出的（如果使用的是默認設置）。

[BP_LatencyLogger_C_1]

含义： 這是生成這條日誌消息的 конкре的藍圖Actor實例的名稱。

BP_LatencyLogger_C 通常表示名為 BP_LatencyLogger 的藍圖類。

_1 (或其他數字) 是引擎為該類的實例自動生成的後綴，用以區分場景中的多個實例。

LATENCY_LOG

含义： 这是一个您在 BP_LatencyLogger 蓝图中的 Build String (Advanced) 节点中定义的 自定义前缀或标签。它的作用是帮助您在大量的日志中轻松识别和筛选出这些特定的延迟测量条目。

{Action} (在示例中是 Move)

含义： 表示当前正在计时和记录的 具体游戏操作或输入事件的名称。这个名称是您在调用 BP_LatencyLogger 中的接口函数（如 EndActionTimerAndLog）时作为参数传递的 ActionName。

{PrevEnd_TS} (在示例中是 0.021)

含义： 这是 上一个相同 {Action} 完成处理并记录其结束时间的时间戳。

单位： 秒 (来自于蓝图中的 Get Accurate Real Time Seconds 节点)。

来源： 这个值是从 BP_LatencyLogger Actor 内部存储的 LastActionEndTimes Map 中，根据当前的 {Action} 名称查找得到的。

{CurrEnd_TS} (在示例中是 0.038)

含义： 这是 当前这个 {Action} 完成处理并记录其结束时间的时间戳。

单位： 秒 (来自于蓝图中的 Get Accurate Real Time Seconds 节点)。

{Logged_Interval_Seconds} (在示例中是 0.017)

含义： 这是由您的蓝图逻辑计算并记录下来的 时间间隔，单位是秒。

正常情况： 当 CurrEnd_TS > PrevEnd_TS 时，这个值应该是 CurrEnd_TS - PrevEnd_TS。例如，在 LATENCY_LOG,Move,0.021,0.038,0.017 中，0.038 - 0.021 = 0.017。这是我们进行统计分析时真正关心的值（在脚本中会转换为毫秒）。

重置或异常情况： 当 CurrEnd_TS <= PrevEnd_TS 时（例如，您日志中出现的 LATENCY_LOG,Move,1.617,0.022,1.595），这通常表示游戏的实时时钟（Get Accurate Real Time Seconds 的返回值）可能发生了重置（比如重新加载关卡、重启游戏会话，或者PIE (Play In Editor) 结束并重新开始）。

在这种情况下，{PrevEnd_TS} (如 1.617) 是上一个计时会话残留的值，而 {CurrEnd_TS} (如 0.022) 是新会话从接近0开始的值。

此时，{Logged_Interval_Seconds} (如 1.595) 可能是 abs(CurrEnd_TS - PrevEnd_TS)，或者是蓝图特殊处理后的值。这类日志条目会被Python分析脚本识别并过滤掉，因为它们不代表在同一个稳定计时周期内两次连续事件的有效间隔。脚本通过检查 CurrEnd_TS > PrevEnd_TS 来确保只处理有效的连续数据点。

在下一条恢复。