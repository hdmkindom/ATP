# 2026-04-11 实验日报

本文汇总 2026-04-11 在 ATP + ax-prover 框架上完成的关键排查与阶段性结论，供项目汇报使用。

## 1. 今日目标

今日排查的核心问题有两项：

1. `gpt-5.3-codex` 在当前实验中是否真正开启了高思考模式。
2. `T1.free` 长期失败，究竟是因为模型没有搜索、搜索不可用，还是搜索结果没有被正确转化为 Lean 证明。

## 2. 关键结论

### 2.1 先前默认实验并未显式开启高思考模式

通过专项脚本：

- [check_reasoning_mode.py](/Users/hdm/math/elementary-number-theory/ATP/scripts/check_reasoning_mode.py)

对当前配置与高思考配置进行对照，得到以下结果：

- 旧默认配置下，LLM 请求参数中没有显式 `reasoning` 字段。
- 对照实验中，旧默认配置的 `reasoning_tokens = 0`。
- 切换到 `provider_config.reasoning.effort = high` 后，`reasoning_tokens > 0`，且单次请求耗时明显上升。

这说明：此前“模型运行过快、几乎不像在认真思考”的观察是成立的，且确实与配置有关。

相关证据文件：

- [20260411_current_vs_high.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/reasoning_probe/20260411_current_vs_high.json)
- [reasoning-mode-check-20260411.md](/Users/hdm/math/elementary-number-theory/ATP/doc/reasoning-mode-check-20260411.md)

### 2.2 切换到高思考模式后，`T1.free` 已显著改变行为

本日新增实验：

- `T1.free + openai_reasoning_high`

运行目录：

- [20260411_t1_free_reasoning_high](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high)

该轮实验的中间状态表明：

- 模型不再像此前那样几乎完全不搜索。
- 在运行到第 4 轮附近时，LeanSearch 已累计调用 `30` 次。
- 单轮 proposer 阶段持续时间显著增加，说明模型确实在进行更长时间的检索与尝试。

相关证据文件：

- [index.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high/scenarios/T1_free/attempt_01/leansearch/index.json)
- [04112309_iter01.lean](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high/scenarios/T1_free/attempt_01/iterations/04112309_iter01.lean)
- [04112310_iter02.lean](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high/scenarios/T1_free/attempt_01/iterations/04112310_iter02.lean)
- [04112314_iter03.lean](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high/scenarios/T1_free/attempt_01/iterations/04112314_iter03.lean)
- [04112316_iter04.lean](/Users/hdm/math/elementary-number-theory/ATP/artifacts/runs/20260411_t1_free_reasoning_high/scenarios/T1_free/attempt_01/iterations/04112316_iter04.lean)

结论是：高思考模式对 agent 行为有实质影响，它显著提高了搜索意愿和搜索密度。

### 2.3 当前主要瓶颈已从“不会搜索”转向“不会正确落地搜索结果”

高思考模式下，`T1.free` 的失败形态发生了变化。

此前的主要问题更接近：

- 不主动调用 LeanSearch；
- 直接凭空猜 theorem 名；
- 很快结束一轮。

而今天的高思考实验显示，新瓶颈更接近：

- 会主动搜索；
- 能找到接近目标的 theorem，例如 `sum_hom_units_eq_zero`；
- 但在 import、适用对象、类型桥接这一步仍然经常失败。

举例来说：

- `sum_hom_units_eq_zero` 在本地 mathlib 中确实存在；
- 但当前目标里的 `Character G` 是项目本地定义的 `G →* ℂˣ`；
- 模型尚未稳定处理“把搜索到的 theorem 签名正确迁移到当前对象环境”这一层。

因此，本日的排查结果并不支持“LeanSearch 本身坏了”这一判断。更合理的结论是：

- 搜索已能工作；
- 但搜索结果采用机制还不够稳。

## 3. 配置层面的调整

为避免继续在不合理默认值上做实验，今日已完成两项配置调整：

### 3.1 正式实验默认切换为高思考 profile

配置位置：

- [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)

当前正式实验默认值为：

- `llm_runtime.experiment_profile = llm_profiles.openai_reasoning_high`

说明：

- 正式实验默认使用 `gpt-5.3-codex + reasoning.effort=high`
- `doctor` 仍保持原共享默认配置，避免每次环境检查都付出高思考成本

### 3.2 正式实验默认禁用 `search_web`

配置位置：

- [ax_prover_experiment.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_experiment.yaml)

当前正式实验的默认 `proposer_tools` 只保留：

- `search_lean`

这样做的原因是：

- 本项目当前最核心的外部检索依赖是 LeanSearch；
- 未配置 Tavily key 时，`search_web` 只会返回 Unauthorized；
- 在高思考模式下，模型会更积极地调用工具，保留无效 `search_web` 只会放大 token 与时间浪费。

## 4. 对前八题失败原因的阶段性理解

截至 2026-04-11，前八题失败的原因已不宜再简单归结为“模型能力不够”。更准确的阶段性判断是：

1. 先前默认配置没有显式开启高思考模式，这会压低搜索密度与推理深度。
2. 即使开启高思考，模型仍然容易在“搜索结果适用性验证”上失败。
3. 因此，当前实验尚处于“系统与任务耦合调校阶段”，不能直接把所有失败全部解读为模型本身的极限。

## 5. 下一步建议

基于今天的结果，下一步更值得做的是：

1. 在保持 `openai_reasoning_high` 的前提下，继续以 `T1.free` 做小规模对照实验。
2. 增加一层轻量本地校验，重点关注：
   - theorem 所需 import 是否已给出；
   - theorem 签名是否真的适用于当前对象；
   - 搜索结果是否只是“名字相似”，而非真正可用。
3. 在确认 `T1.free` 行为稳定改善后，再把同样配置推广到 `T2-T8`。

## 6. 总结

今天最重要的收获不是“题目已经解决”，而是成功缩小了问题范围：

- 先前实验偏快，确实与 reasoning mode 未显式开启有关；
- 切换高思考后，`T1.free` 已经开始密集调用 LeanSearch；
- 因而当前的关键瓶颈，已经从“不会搜索”转向“搜索结果的本地化落地与类型适配”。

这意味着项目已经找到了更接近问题核心的方向，后续优化将更有针对性。
