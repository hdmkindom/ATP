# T1.free Short Probe 2026-04-12

本文记录 2026-04-12 对 `T1.free` 做的一次低轮数 short probe，用于回答一个更具体的问题：

- 当前在 `openai_reasoning_high + search_lean only` 条件下，`T1.free` 是不是“搜索定理然后卡住”。

## 1. 本次 probe 配置

本次运行基于当前正式实验默认配置：

- `experiment_profile = openai_reasoning_high`
- `proposer_tools = ['search_lean']`

另叠加 probe 配置：

- [t1_free_short_probe.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/probes/t1_free_short_probe.yaml)

其作用是：

- `max_iterations = 3`
- `runtime.max_tool_calling_iterations = 3`
- `summarize_output.enabled = false`

运行命令为：

```bash
source ~/ax-prover-env/bin/activate
python ATP/scripts/atp_axbench.py run T1.free \
  --skip-prebuild \
  --ax-config ATP/config/probes/t1_free_short_probe.yaml \
  --output-dir ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule
```

输出目录：

- [20260412_t1_free_short_reasoning_rule](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule)

## 2. 本次额外加入的轻量规则

本次 probe 前，对 prompt 增加了一条很轻的 LeanSearch 结果采用规则：

- 先确认所需 import 是否存在
- 再确认 theorem 签名是否匹配当前对象、定义域和值域
- 如果这两点不清楚，则先不要引用该 theorem

代码位置：

- [prompts.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/prompts.py)

这一规则已经出现在当前 `T1.free` 的实际 prompt 中。

## 3. 运行过程观察

### 3.1 运行初期确实进入了 LeanSearch

从终端日志看：

- 00:39:30 开始 `iteration 1`
- 00:39:39 得到第 1 次 LeanSearch 结果
- 00:39:46 得到第 2 次 LeanSearch 结果
- 00:39:53 得到第 3 次 LeanSearch 结果

LeanSearch 归档也一致显示：

- `search_count = 3`

对应文件：

- [index.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule/scenarios/T1_free/attempt_01/leansearch/index.json)

### 3.2 搜索内容体现出规则有一定作用

三次搜索内容分别更偏向：

1. 带有当前对象形状的整体查询  
   例：`Mathlib Character G := G →* ℂˣ theorem sum_eq_zero nontrivial character finite group`
2. 追问 `sum_hom_units_eq_zero` 的 import
3. 继续确认 `Character G := G →* ℂˣ` 相关定义

对应文件：

- [04120039_search01.txt](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule/scenarios/T1_free/attempt_01/leansearch/04120039_search01.txt)
- [04120039_search02.txt](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule/scenarios/T1_free/attempt_01/leansearch/04120039_search02.txt)
- [04120039_search03.txt](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260412_t1_free_short_reasoning_rule/scenarios/T1_free/attempt_01/leansearch/04120039_search03.txt)

这说明：

- 新规则至少影响了查询方式；
- agent 不再只是一味搜索 theorem 名字本身，而开始显式带上对象类型 `Character G := G →* ℂˣ`。

## 4. “是不是搜索后卡住”的结论

### 4.1 本次更像“搜索后等待 LLM 响应”，不是“无限搜索”

本次运行有一个非常关键的现象：

- 在 00:39:53 之后，没有新的 LeanSearch 文件继续写入；
- 但直到 00:43 之后，仍然没有出现 `Generated proof`；
- 同时也没有任何 `iter01.lean` 或 `iter01.json` 被生成。

也就是说：

- 它不是一直在继续搜索；
- 也不是已经进入 Lean 编译；
- 而是停在“搜索完成之后、正式生成 proposal 之前”这一步。

### 4.2 进程采样支持这个判断

对运行中的 Python 进程进行了 `sample` 采样，结果显示：

- 主线程主要停在事件循环的 `kevent` 等待上；
- 没有看到持续密集的本地计算活动；
- 结合文件系统没有继续新增搜索结果，可以判断它更像是在等待外部请求返回，而不是在本地无限处理 LeanSearch 结果。

这说明：

- 当前卡顿点更像是“模型请求/响应阶段”
- 而不是 LeanSearch 工具本身陷入死循环

## 5. 本次 probe 的阶段性结论

本次 short probe 支持以下判断：

1. 在 `openai_reasoning_high + search_lean only` 下，`T1.free` 已经会进入 LeanSearch。
2. 新增的轻量规则对查询行为有一定影响，至少让搜索词更接近当前对象类型。
3. 当前这轮卡顿并不是“无限 LeanSearch”，而更像是“LeanSearch 返回之后，等待模型继续生成 proposal 的阶段耗时过长或挂起”。

## 6. 下一步最值得尝试的方向

基于这次数据，下一步最值得做的不是再继续加强搜索，而是：

1. 保持：
   - `openai_reasoning_high`
   - `search_lean only`
2. 在 probe 配置里增加 LLM 超时参数，例如：
   - `provider_config.timeout = 90` 或 `120`
3. 继续只跑 `T1.free` 的 2 到 3 轮 short probe

这样做的价值是：

- 如果模型只是“思考很久但最终能返回”，超时值可以帮助我们量化真实耗时；
- 如果模型请求确实在某些轮次挂起，那么超时能把“卡住”转化成一个明确可归档的错误，而不是无限等待；
- 在这个问题没弄清之前，再盲目提高搜索次数或提高轮次，收益不高。
