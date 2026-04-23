# ATP Engineering Notes

## 1. `lake exe cache get` Fails but `lake build` Succeeds

现象：

- `doctor` 日志里反复出现 `cache get failed with code 1`
- 但 `lake build` 随后仍然成功

实际原因：

- 当前项目根目录的 `lean-toolchain` 是 `leanprover/lean4:v4.24.0-rc1`
- `.lake/packages/mathlib/lean-toolchain` 是 `leanprover/lean4:v4.24.0`
- `lake exe cache get` 对 toolchain 完全一致有要求，因此拒绝使用缓存
- `lake build` 依然可以正常从源码构建，所以本地 Lean / mathlib 环境本身并没有坏

直接复现结果：

```text
Dependency Mathlib uses a different lean-toolchain
  Project uses leanprover/lean4:v4.24.0-rc1
  Mathlib uses leanprover/lean4:v4.24.0
```

当前处理：

- ATP 把“cache 失败但 build 成功”视为可继续运行
- `doctor` 仍会把这个现象保留在报告中，便于后续统一修复 toolchain

## 2. `llm_ping` 的 `'str' object has no attribute 'model_dump'`

现象：

- `doctor` 的 `llm_ping` 可能报 `AttributeError: 'str' object has no attribute 'model_dump'`
- 正式 `run test` 里则可能表现为 `'str' object has no attribute 'choices'`

定位结果：

- 问题不在 Lean，也不在 ATP 的归档逻辑
- 当前 `base_url` 若只写成站点首页，例如 `https://api.whatai.cc`
- LangChain / OpenAI SDK 会把它当作 API 根地址使用
- 但该地址实际返回的是网页内容，而不是 OpenAI 兼容 JSON 响应
- 底层收到字符串后再去访问 `.model_dump` 或 `.choices`，于是报出看似离谱的 AttributeError

当前处理：

- `doctor` 会优先提示“这像是把 `base_url` 指到了网站根目录”
- `run` 也会把这类异常翻译成更可读的说明

## 3. OpenAI-Compatible Relay Often Needs `/v1`

在调试 OpenAI 兼容中转时，一个很容易忽略的细节是：

- 站点首页 URL 不一定等于 API 根路径
- 许多服务要求显式写成 `https://host/v1`

实验中观察到：

- `https://api.whatai.cc` 返回网页内容
- `https://api.whatai.cc/v1` 才能返回标准 API 错误 JSON

这说明路径本身就是关键差异点。

## 4. `/v1` Correct but Token Still Invalid

进一步测试后还发现另一个边界：

- 当 `base_url` 改成 `/v1` 之后，接口开始返回结构化 JSON
- 但如果 token 不是该供应商接受的 token，仍会返回认证错误

这意味着：

- “路径不对”与“密钥不对”是两个独立问题
- 第一步应先保证 `base_url` 指向真正的 API
- 第二步再验证 `OPENAI_API_KEY` 是否适用于该中转或代理服务

## 5. Shared LLM Defaults Matter

最初 `doctor` 与正式实验各自维护了一份 LLM 配置。这样短期能跑，但长期容易漂移：

- `doctor` 通过了，不代表正式实验也在用同一接口
- 正式实验改了模型，不代表 `doctor` 会同步

现在已改成：

- 两者默认共用 `ax_prover_profiles.yaml` 中的 `llm_runtime.shared_profile`
- 如需分流，再单独改 `doctor_profile` 或 `experiment_profile`

## 6. Empty `base_url` Should Mean “Use Provider Default”

另一个细节是“留空”到底怎么解释。

如果把空字符串原样传给 LangChain，行为并不稳定；更合理的语义是：

- `null` 或空字符串表示“不传这个参数”
- provider 自动使用自己的官方默认端点

ATP 现在已经在运行前清理这些空值键。

## 7. LangSmith Noise Was a Separate Source of Confusion

现象：

- 即使主要任务与 LangSmith 无关，运行过程中仍可能出现 trace 上传报错

处理：

- ATP 在进程内主动清空 `LANGSMITH_API_KEY` 与 `LANGCHAIN_API_KEY`
- 同时把 tracing 标志设为 `false`
- 并清理 ax-prover 内部 LangSmith 聚合器缓存

这样做的收益是把“模型接口问题”和“tracing 噪声”分离开，不再互相干扰判断。

## 8. Temporary Proposal Files Would Otherwise Be Lost

ax-prover 在 builder 节点测试失败后会删除临时文件。如果不做补救：

- 每一轮尝试过什么
- 哪一轮开始走偏
- 哪一轮最接近成功

都会一起丢失。

当前处理：

- proposer 每生成一轮 proposal，ATP 立刻重建完整 Lean 文件
- 每轮文件独立归档到 `artifacts/.../iterations/`
- 运行结束后再把反馈信息回填到该轮 JSON 元数据

## 9. Why the Source File Is Not Moved Out of `temTH`

考虑过把目标文件从 `temTH` 直接搬到运行目录，再在结束后移回。但最终没有采用：

- Lean 的模块路径依赖仓库内相对位置
- 真实移动会把“证明实验”变成“路径迁移实验”
- 对中断恢复并没有决定性优势

当前方案：

- 原地运行
- 运行前保存原始快照
- 运行中保存每轮快照
- `finally` 中恢复模板
- 再保存恢复后快照

## 10. `base_url` Should Be API Root, Not Final Endpoint

后续又遇到一个很典型的 OpenAI 兼容接口问题：

- 用户把 `base_url` 写成了 `https://codeflow.asia/v1/chat/completions`
- `doctor` 报错中出现了 `POST /v1/chat/completions/responses`

这不是 ATP 手写拼接出来的，而是当前本地 `langchain-openai` / `openai` SDK 的正常行为：

- `base_url` 被当作 API 根地址保存
- 资源路径由 SDK 自己再追加
- 如果模型触发了 Responses API 分支，SDK 就会再拼 `/responses`

因此：

- 正确的 `base_url` 通常应写成 `https://codeflow.asia/v1`
- 不应写成最终 endpoint `https://codeflow.asia/v1/chat/completions`

## 11. `codex` Model Names Prefer Responses API in Current LangChain

本地安装的 `langchain-openai` 里，`ChatOpenAI._use_responses_api()` 会在以下情况优先走 Responses API：

- 显式设置了 `use_responses_api: true`
- 使用了某些 responses-only 参数
- 模型名命中内部“更偏好 Responses API”的判断

其中一个直接命中条件就是：

- 模型名包含 `codex`

这意味着对 `gpt-5.2-codex` 这样的模型，如果不额外设置：

```yaml
use_responses_api: false
```

它就很可能默认去走 `/responses`，即使你的中转平台文档只列出了 `/v1/chat/completions`。

## 12. YAML Can Now Carry API Keys Too

最初 ATP 只把 `model` 与 `base_url` 放在 YAML 里，而 API key 仍依赖外部环境变量。后来发现这会让用户在“框架内配置”和“外部运行环境配置”之间来回跳转，体验不统一。

现在 ATP 已支持：

- 在 `provider_config.api_key` 中直接写密钥
- 运行时自动把它同步到当前进程环境变量
- 再继续交给 ax-prover / LangChain 正常消费

这样一来，接口的关键配置现在可以完整地放进同一份 YAML：

- `model`
- `api_key`
- `base_url`
- `use_responses_api`

## 13. Removing All `import` Statements from `temTH` Is Not Safe

后续又检查了一个容易误判的问题：`ATP/temTH` 里的 `import` 能不能全部删掉。

结论是：不能直接全删。

抽样实验中，把 `T5/Disable.lean` 的所有 `import` 行去掉后，Lean 立即报出：

- `unknown namespace BigOperators`
- `unknown namespace CandidateTheorems.T3`
- `unknown namespace CandidateTheorems.T5`

这说明这些模板里的 `import` 不只是“可有可无的提示”，而是在提供：

- 支持性定义
- 命名空间
- 记号与 scoped notation
- 类型类实例

因此，当前不应批量移除 `temTH` 下的全部 `import`。

## 14. Failing at the Iteration Limit but Keeping the Last Attempt

另一个工程需求是：达到最大调试轮次后自动停止，并把最后一次失败产物保留下来。

ax-prover 本身已经会在 `max_iterations` 达到上限时停止继续尝试。ATP 这边补充了一个项目级开关：

```yaml
execution:
  persist_last_attempt_on_failure: true
```

打开后，即使该场景最终没有成功，ATP 也不会在 `finally` 中把模板文件恢复成原始 `sorry` 版本，而是保留最后一次失败尝试的文件内容。

## 15. Responses API Can Produce Loud but Cosmetic Pydantic Warnings

在使用 OpenAI 兼容模型，尤其是 `gpt-5.*` / `codex` 这类更偏向 Responses API 的模型时，`langchain-openai` 会把结构化输出、parsed 字段和响应内容块重新序列化成普通 Python 字典。

这一步在当前依赖版本组合下会触发一类很吵的告警：

- `PydanticSerializationUnexpectedValue`
- `serialized value may not be as expected`

目前确认这类输出主要是序列化层噪声，不等于真正的 proving 失败。它会夹杂在题目之间，把批量运行日志冲得很乱，所以 ATP 运行层现在会定向屏蔽这类已知噪声告警，但不会吞掉真实异常。

## 16. Our Wrapper Initially Missed ax-prover's Default `memory.llm`

后来排查发现，批量实验里很多题目之所以“只跑了一轮”并不是因为 `prover.max_iterations` 生效，而是第一次 proposal 或 build 失败后，ax-prover 准备进入 `memory_processor` 时直接报了：

```text
AttributeError: 'NoneType' object has no attribute 'ainvoke'
```

根因是：

- ATP 最初是从 ax-prover 的 dataclass `Config()` 起步再叠加 YAML
- 但 ax-prover 官方 `default.yaml` 里还额外给 `ExperienceProcessor` 配了
  `memory_config.init_args.llm_config: ${prover.prover_llm}`
- 这个默认值并不在 dataclass 默认字段里

结果就是：

- 一次成功的题目看不出问题
- 一旦进入失败后的“经验总结”节点，`memory.llm` 就是 `None`
- 流程因此提前崩溃，看起来像“只尝试了一轮”

ATP 现在会在构建 ax-prover 配置时自动补齐这一缺省项，使失败场景也能继续进入下一轮内部迭代。

## 17. `unknown target` on Temporary Lean Files Is Usually Not an Environment Failure

后续又确认了一类很容易误判成“Lean 环境坏了”的日志：

```text
'lake build ATP.temTH....tmp_xxx' failed: unknown target.
Falling back to 'lake env lean ATP/temTH/.../tmp_xxx.lean'
```

这类日志通常不是环境损坏。

根因是：

- ax-prover 会把 proposal 先写入临时 Lean 文件
- 然后优先尝试 `lake build <临时模块名>`
- 但这些临时模块本来就不是 Lake 正式 target
- 因此 `lake build` 报 `unknown target`
- 随后它自己再自动回退到 `lake env lean <临时文件路径>`

也就是说，这是“检测临时文件时的正常回退路径”，不是 Lean / mathlib / Lake 配置坏了。

## 18. We Can Improve Terminal UX Without Editing ax-prover Source

这次又验证了一个工程边界：即使不修改 ax-prover 内部文件，ATP 这一层仍然可以显著改善终端体验。

目前 ATP 已在包装层实现：

- ax-prover 日志颜色化
- 已知噪声 warning 的过滤
- 每题分隔条
- 欢迎横幅
- 每题结束后的时间、请求数、token 数状态输出
- 基于历史均值与本次运行观测值的动态 ETA

这说明很多“看起来像必须改底层库”的展示问题，其实可以通过：

- logging handler / formatter / filter
- LangChain chat model 调用钩子
- ATP 自己的运行状态持久化

在上层安全解决。

## 19. `Config()` Does Not Carry ax-prover's Default Search Tools

这次又确认了一类很容易被忽略、但对成功率影响很大的配置差异：

- ATP 当前是从 ax-prover 的 dataclass `Config()` 起步，再叠加自己的 YAML
- 但 ax-prover 官方 `default.yaml` 里还额外配置了：
  - `proposer_tools.search_lean`
  - `proposer_tools.search_web`
- 这些默认搜索工具并不在 dataclass 默认字段里

结果就是：

- 如果 ATP 只拿 `Config()` 合并，而不显式补齐这一层
- 最终传给 ax-prover 的 `proposer_tools` 就可能是空字典
- 模型会更频繁地“猜” Lean 引理名和 API，而不是先查找

这一点非常容易和“memory 失效”混淆，因为表面现象都是：

- 多轮之间跳动很大
- 经常反复尝试不存在的 lemma 名
- 强模型也不稳定

ATP 现在会在 `proposer_tools` 为空时自动恢复官方默认的 `search_lean`。

对于 `search_web`，ATP 采用更保守的策略：

- 若检测到 `TAVILY_API_KEY`，则一并恢复 `search_web`
- 若没有 Tavily key，则默认不启用 `search_web`

这样做的原因是：

- ax-prover 的 `search_web` 工具本身不会因无 key 崩溃
- 但模型一旦调用它，只会收到 “TAVILY_API_KEY not found” 一类错误文本
- 这会浪费工具轮次与 token，而不是提供有效帮助

## 20. LeanSearch Global Session Can Break Across Multiple `asyncio.run(...)` Calls

在把 `search_lean` 补回 ATP 默认配置之后，又暴露出一个只会在“同一 Python 进程连续跑多个场景”时出现的问题：

```text
LeanSearch error: RuntimeError - Event loop is closed
Unclosed client session
```

根因是：

- ax-prover 的 LeanSearch 工具内部维护了一个全局 `aiohttp.ClientSession`
- ATP 这层是“每个场景一次 `asyncio.run(...)`”
- 第一题结束后，旧事件循环关闭
- 第二题如果复用上一个全局 session，就会把旧 loop 一起带进来

这不是 LeanSearch 服务本身不可用，而是一个“跨场景复用异步会话”的生命周期问题。

ATP 现在会在每个场景开始前和结束后，主动关闭并清空 LeanSearch 全局 session，避免下一题复用一个绑定旧事件循环的 `aiohttp` 会话。

## 21. Free Mode Should Not Leak Route Labels or Route Instructions

回看早期运行后发现一个 prompt 设计问题：自由模式虽然名义上是 free，但 ATP 之前仍然会把同一题的路线概览放进 prompt，例如“换元路线”“正交路线”等。

这会带来两个问题：

- 模型会被路线文本诱导，而不是只根据 Lean 目标证明
- 模型会根据自然语言路线猜测一些看起来合理、但本地 mathlib 根本不存在的 lemma 名

现在 ATP 的自由模式改为更干净的 prompt：

- 不再注入 routeA / routeB 概览
- 只为当前题目的当前模式注入对应的 theorem-level `user_comments`
- 自由模式只读取当前题目的 `free_instruction`
- 只提供目标文件、真实 Lean theorem 骨架、现有 imports、全局证明纪律和当前场景附加说明

引导模式仍然保留对应路线指示，因为它用于测试“给定证明方向后模型是否能完成”的能力。禁用模式仍保留禁用说明，因为它用于测试某类证明方向被 block 后模型是否能寻找替代路线。

## 22. Unknown Lemma Hallucination Is a Prompt Discipline Problem Before It Is a Tool Problem

这次也进一步确认：即使 `search_lean` 已经挂上，模型仍可能先尝试一个“看起来很对”的名字，例如：

- `MulChar.sum_eq_zero_of_ne_one`
- `Character.sum_eq_zero_of_ne_one`
- `character_sum_eq_zero_of_ne_one`

如果这些名字在当前 Lean 环境里不存在，Lean 会反馈 `unknown identifier` 或 `unknown constant`。理想行为是下一轮不要继续重复同一个名字，而是先检索或转向手写证明。

在不改 ax-prover 内部迭代图的前提下，ATP 现在先做了一个非侵入式约束：

- 全局协议要求模型不要发明看似合理的 theorem 名
- 如果 Lean 已经报告某个名字 unknown，后续轮次不得继续使用同名 lemma，除非先通过 LeanSearch 或本地 imports 确认它存在

更严格的“失败次数达到阈值后动态禁用某个 lemma 名”需要接管 ax-prover 的 memory / feedback 节点，或实现一个 ATP 自定义 memory processor。这个可以作为后续增强项处理。

## 23. Include the Lean Statement, Existing Imports, and Per-Scenario Instructions in the Prompt

过去 prompt 里只有题号和自然语言标题时，模型容易根据题意猜 lemma 名，而不是先看真实 Lean 目标。

现在 ATP 会从目标 Lean 模板中自动提取：

- 已有 `import` 行
- `namespace` / `open` / `variable` 上下文
- 带 `by sorry` 的目标 theorem 骨架

这样模型看到的是接近真实文件环境的 Lean 目标，而不是只看到一个自然语言题名。

同时，`theorem_catalog.yaml` 现在把候选题 prompt 入口固定为四个字段：

- `free_instruction`
- `disable_instruction`
- `route_a`
- `route_b`

ATP 会根据“当前题目 + 当前模式”只选取其中一个字段，写入 ax-prover 的 `prover.user_comments`。这些文本是按场景注入的附加说明，不再保留额外的 theorem 级 prompt 扩展字段。

## 24. 2026-04-11: LeanSearch 实测未被 `T1.free` 调用，且 `T2` 到 `T8` 当前首先受 `.olean` 缺失影响

本次新增了 LeanSearch 调用归档后，对 `T1.free` 重新跑了一次：

```bash
python ATP/scripts/atp_axbench.py run T1.free --skip-prebuild
```

结果目录中的 `leansearch/index.json` 明确显示：

```json
{
  "search_count": 0,
  "records": []
}
```

这说明当前版本的 `T1.free` 不是“LeanSearch 调用了但 ATP 没保存”，而是 proposer 在 6 轮中一次 LeanSearch 都没有发起。

与此同时，直接用 `lake env lean` 检查模板文件时发现：

- `ATP/temTH/CandidateTheorems/T1/Free.lean` 可以正常进入 theorem 体
- `ATP/temTH/CandidateTheorems/T2/Free.lean` 到 `T8/Free.lean` 会先因 `CandidateTheorems.T*.Support` 或 `CandidateTheorems.T3.PrimitiveRoot` 的 `.olean` 缺失失败
- `ATP/temTH/CandidateTheorems/T9/Free.lean` 和 `T10/Free.lean` 可以正常进入 theorem 体

进一步直接执行：

```bash
lake build CandidateTheorems.T2.Support
lake build CandidateTheorems.T3.PrimitiveRoot
```

发现 Lake 试图到：

```text
AtpSummary/CandidateTheorems/...
```

下面去找源码，而真实 `CandidateTheorems` 源码实际位于仓库根目录。说明当前 `lakefile.lean` 中 `AtpSummary` 的 `srcDir` 与 `CandidateTheorems` 源码布局之间存在错位。

也就是说，前八题失败里至少有两类问题：

- `T2` 到 `T8`：首先受构建 / 模块路径问题污染
- `T1`：能进入真实 proof loop，但 free 模式下模型不主动用 LeanSearch，而是继续猜 theorem 名

更完整的统计与结论已整理到：

- `ATP/doc/experiment-analysis-20260411.md`

## 25. 2026-04-11: `CandidateTheorems` 与 `temTH` 的 Lake 源码根需要拆开映射

在继续排查 `T1` 的 LeanSearch 行为之前，又确认了一个更基础的工程问题：

- `CandidateTheorems` 的真实源码位于仓库根目录 `CandidateTheorems/`
- `temTH` 的真实源码位于 `ATP/temTH/`

但旧的 `lakefile.lean` 把两者都挂在：

```lean
lean_lib «AtpSummary» where
  srcDir := "AtpSummary"
  roots := #[
    `CandidateTheorems,
    `temTH.CandidateTheoremsTemplate,
    ...
  ]
```

这会导致 Lake 去错误的目录查找 `CandidateTheorems.T2.Support`、`CandidateTheorems.T3.PrimitiveRoot` 等模块源码，从而让 `T2` 到 `T8` 的模板文件在 theorem 体真正开始前就因为缺少 `.olean` 失败。

修复方式不需要改 ATP 主体逻辑，也不需要复制一套新的 Lean / mathlib 环境。只需要把源码根拆开：

- 新增一个单独的 `lean_lib` 承载仓库根目录下的 `CandidateTheorems`
- 让 `AtpSummary` 的 `srcDir` 改为 `ATP`，专门承载 `ATP/temTH/...`

修复后已经确认：

```bash
lake build temTH.CandidateTheoremsTemplate
```

可以完整通过；同时：

```bash
lake env lean ATP/temTH/CandidateTheorems/T1/Free.lean
...
lake env lean ATP/temTH/CandidateTheorems/T10/Free.lean
```

十道题的 `Free.lean` 都可以正常进入 theorem 体，只剩 `sorry` warning。

这意味着从这次修复开始，`T2` 到 `T8` 的后续实验结果才更接近“模型能力”而不是“构建环境缺依赖”。

## 26. 2026-04-11: `T1.free` 的主要问题不是 LeanSearch 坏了，而是 free 模式下模型没有主动使用它

对运行目录：

- `ATP/artifacts/runs/20260411_170838`

做专项分析后确认：

- `T1.free` 跑满 30 轮，但 `leansearch/index.json` 中 `search_count = 0`
- 总请求数为 `61`，几乎正好等于 `30` 次 proposer + `30` 次 memory + `1` 次 summary，进一步说明没有发生工具回合

随后又做了一个低成本 probe：

- 同一个 theorem
- 同一个模型
- 只跑 2 轮
- 关闭 summary
- 仅在 `user_comments` 中加入“当 theorem 名不确定时，必须先调用 `search_lean`”这一条中性工具纪律

结果：

- `search_count = 2`

因此当前更准确的判断是：

1. LeanSearch 服务和 ATP 的 LeanSearch 归档都正常；
2. free 模式下不给任何额外提示时，模型默认不会主动搜索；
3. 即使强制搜索，模型也可能直接照抄一个“近似但不适用”的 theorem 名，因此后续还需要考虑搜索结果适用性校验。

完整分析已写入：

- `ATP/doc/run-analysis-20260411_170838.md`

## 27. 2026-04-11: `20260411_214642` 已不是“不搜索”，而是“搜索结果采用失败”

对运行目录：

- `ATP/artifacts/runs/20260411_214642`

做逐轮复测后确认：

- `T1.free` 共调用 LeanSearch `7` 次；
- 10 轮 proposal 在 4 个家族之间切换：
  - `MulChar.sum_eq_zero_of_ne_one`
  - `sum_hom_units_eq_zero / sum_hom_units`
  - `Character.sum_eq_zero_of_ne_one`
  - 手工平移换元路线

其中几个关键结论：

1. `MulChar.sum_eq_zero_of_ne_one`
   - 本地 mathlib 确实存在；
   - 但需要正确 import，且 theorem 对象不是当前的 `Character G := G →* ℂˣ`。
2. `sum_hom_units_eq_zero`
   - 本地 mathlib 也存在；
   - 但需要导入 `Mathlib.RingTheory.IntegralDomain`；
   - 同样还需要解决 `Character G` 到 theorem 期望对象的类型桥接。
3. `Character.sum_eq_zero_of_ne_one`
   - 本地不存在。
4. `Mathlib.RepresentationTheory.Character.Basic`
   - 本地不存在；第 10 轮属于错误模块路径。

所以这轮更准确的根因是：

- LeanSearch 返回了候选；
- 但 agent 没有稳定完成“补 import + 验证 theorem 适用性 + 正确桥接类型”这几步。

完整分析见：

- `ATP/doc/run-analysis-20260411_214642.md`

## 28. 2026-04-11: 搜索工具参数已迁到 experiment YAML，且做了一次低成本 `T1.free` probe

本轮还做了两个小改动：

1. 把正式实验的 proposer 搜索工具参数移到：
   - `ATP/config/ax_prover_experiment.yaml`
2. 让 prompt 在保留 `prompt_seed` 的同时，把当前题目当前模式对应的 theorem-level 指令注入给 ax-prover

为了避免把无效工具暴露给 prover，ATP 现在会在没有 `TAVILY_API_KEY` 时自动移除 `search_web`。

随后用低成本 overlay：

- `ATP/config/probes/t1_free_short_probe.yaml`

跑了一次 3 轮 probe，结果在：

- `ATP/artifacts/runs/20260411_t1_free_short_probe`

这次 probe 的正向信号是：

- LeanSearch 调用数达到 `4`
- 查询开始围绕 `CandidateTheorems.T1.exists_value_ne_one` 展开

说明这次小改动至少已经把搜索行为往更贴近本地辅助 lemma 的方向推了一步。

但 probe 也说明问题还没完全解决：

- agent 仍然会先尝试 `sum_hom_units_eq_zero`
- 即使比 `MulChar` 更接近本地 theorem，也依然没有自动补上 `Mathlib.RingTheory.IntegralDomain`
- 后续仍会回摆到 `MulChar.sum_eq_zero_of_ne_one`

因此当前最值得继续加强的仍然是：

- 搜索结果的本地 import 校验
- theorem 对象类型匹配校验

## 29. 2026-04-11: `gpt-5.3-codex` 默认 profile 并没有显式开启 reasoning mode

用户注意到一个非常有价值的异常信号：

- `T1.free` 这类题目十次重复总耗时只有大约 3 分钟；
- 对一个具备显式 reasoning 能力的模型来说，这个耗时偏短。

专项排查后确认：

1. 当前 ATP 默认 profile：
   - `llm_profiles.openai_default`
2. 其 `provider_config` 中只有：
   - `temperature`
   - `api_key`
   - `base_url`
   - `use_responses_api`
3. 并没有：
   - `reasoning`
   - `reasoning_effort`

进一步用脚本：

- `ATP/scripts/check_reasoning_mode.py`

做真实对照调用后，拿到了非常直接的证据：

- 当前默认配置：
  - `llm.reasoning = None`
  - `_default_params` 中没有 `reasoning`
  - `reasoning_tokens = 0`
  - 响应耗时约 `4.7s`
- 临时覆盖为：
  - `reasoning: {effort: high}`
  之后：
  - `_default_params` 中出现 `reasoning`
  - `reasoning_tokens = 461`
  - 响应耗时约 `11.4s`

这说明：

- 当前默认 ATP 实验并没有显式请求 `gpt-5.3-codex` 的高思考模式；
- 用户观察到的“整体运行过快”是合理警报，而且很可能确实影响了 theorem proving 质量。

额外还发现一个兼容性坑：

- 在当前本地 `langchain-openai + Responses API` 组合下，
  - `reasoning_effort: high`
  会在真实调用时触发
  - `Responses.create() got an unexpected keyword argument 'reasoning_effort'`
- 因此当前更稳的写法应当是：

```yaml
provider_config:
  reasoning:
    effort: high
```

而不是顶层：

```yaml
provider_config:
  reasoning_effort: high
```

为方便后续实验，现已新增两个可选 profile：

- `llm_profiles.openai_reasoning_high`
- `llm_profiles.openai_reasoning_xhigh`

但默认 `shared_profile` 没有直接切过去，因为这会显著增加时间与 token 成本。更稳妥的下一步，是先只拿 `T1.free / T1.disable / T2.free` 做一轮 reasoning 高强度对照。

## 30. 2026-04-11: 正式实验默认切到 `openai_reasoning_high`，并默认禁用 `search_web`

在完成 reasoning mode 实测后，为了避免后续实验继续建立在“未显式开启高思考”的默认值上，现已做两项配置调整：

1. 正式实验默认 profile：
   - 从共享默认档案切到
   - `llm_profiles.openai_reasoning_high`
2. 正式实验默认 proposer tools：
   - 仅保留 `search_lean`
   - 不再默认暴露 `search_web`

这样处理的原因是：

- `T1.free` 的高思考实验已经表明，模型在 reasoning 高强度下会更积极地使用工具；
- 若继续保留未配置 Tavily key 的 `search_web`，高思考模式只会更频繁地触发 Unauthorized 错误，造成额外 token 与时间浪费；
- 当前项目真正需要优先保真的工具仍然是 LeanSearch。

注意：

- 此次只调整了 `experiment_profile`；
- `doctor_profile` 仍保持共享默认档案，避免环境检查也被拉到高成本模式。

与这项变更对应的实验总结见：

- [teacher-report-20260411.md](/Users/hdm/math/elementary-number-theory/ATP/doc/teacher-report-20260411.md)

## 31. 2026-04-12: `search_web` 误触发的根因是用户级 `.env.secrets` 中的 Tavily 模板值

在高思考版 `T1.free` 实验中，虽然 shell 环境里看起来没有 `TAVILY_API_KEY`，但运行日志仍然出现了：

- `Search failed: Unauthorized: missing or invalid API key.`

最终定位到的根因不是高思考模式本身，而是 ax-prover 的 secrets 加载顺序：

1. ATP 调用 `build_ax_config(...)`
2. `build_ax_config(...)` 内部调用 ax-prover 的 `load_env_secrets(REPO_ROOT)`
3. ax-prover 会继续读取用户级：
   - `~/Library/Application Support/ax-prover/.env.secrets`
4. 该文件中存在：
   - `TAVILY_API_KEY=your-tavily-api-key-here`

旧逻辑只判断“是否存在 `TAVILY_API_KEY`”，因此即使它只是模板值，也会错误保留 `search_web`。

现已在 ATP 中增加更严格的判断：

- 空值视为未配置
- 常见模板占位值（如 `your-tavily-api-key-here`）也视为未配置

修复后，即使用户级 `.env.secrets` 里仍保留示例模板，ATP 也不会再错误暴露 `search_web`。

## 32. 2026-04-12: `T1.free` short probe 显示“搜索后长时间等待”，而不是无限 LeanSearch

在完成 `search_web` 修复后，又进行了一个低成本 `T1.free` probe：

- 正式实验默认仍为 `openai_reasoning_high + search_lean only`
- 额外 overlay：
  - `max_iterations = 3`
  - `max_tool_calling_iterations = 3`
  - `summarize_output.enabled = false`

并且在 prompt 中增加了一条更显眼但仍然很轻的规则：

- 引用 LeanSearch 返回的 theorem 前，先确认 import 存在
- 再确认 theorem 签名与当前对象、定义域和值域匹配

该 probe 的结果很关键：

1. 第一轮确实进入了 LeanSearch；
2. 大约 23 秒内完成了 3 次搜索；
3. 之后没有继续新增搜索文件；
4. 但也没有进入 `Generated proof`，更没有生成 `iter01.lean`；
5. 进程采样显示主线程长期停在事件循环等待状态。

因此，这轮更像是：

- “搜索完成后等待模型返回 proposal”

而不是：

- “LeanSearch 工具本身无限循环”

这说明下一个更值得验证的点，已经不是“要不要继续加强搜索”，而是：

- 是否应该给 OpenAI 兼容接口增加明确的 provider timeout，
- 让“长时间等待”转化成结构化错误，方便进一步定位是模型响应慢、代理链路慢，还是请求在某一步挂起。

## 33. 2026-04-16: ATP 进一步收敛成 ax-prover 的薄包装层

本轮改动的核心目标，是把 ATP 从“带有不少额外实验逻辑的框架”，收敛回“基于 ax-prover 的小型实验包装器”。

这次明确做了几件事：

1. LLM 档案收敛
   - `ax_prover_profiles.yaml` 只保留：
     - `openai`
     - `anthropic`
     - `gemini`
   - 不再拆出多个 OpenAI reasoning profile
   - 思考模式改为 provider 内部参数，例如：
     - `provider_config.reasoning.effort = high`

2. prompt 机制收敛
   - ATP 不再自己拼复杂 prompt
   - `prompts.py` 只负责把 `ScenarioSpec.prompt_seed` 原样传给 ax-prover 的 `prover.user_comments`
   - ax-prover 自己的 system prompt 仍完全由它本体维护

3. policy 逻辑移除
   - 删除了 ATP 自己的 route / policy 后处理
   - `ScenarioResult.valid` 现在直接等于 prover 成功与否
   - ATP 不再额外做“路线合规”或“禁用 regex”判定

4. runtime 逻辑简化
   - `runtime_monitor` 只保留简单 ETA
   - 不再在 ATP 主路径里维护请求数 / token 数统计与 EWMA 细粒度逻辑

5. LeanSearch 边界收紧
   - 搜索工具配置完全交给 ax-prover 的 YAML
   - ATP 主运行链里不再做 fallback tool 注入
   - LeanSearch tracing 模块保留为调试工具，但默认主链不再依赖它改写搜索行为

6. memory 默认值回到 YAML
   - `memory_config.init_args.llm_config` 现在在 experiment / doctor YAML 中显式声明
   - ATP 不再在主运行代码里隐式补齐 ax-prover 默认 memory 配置

这轮调整后的总体原则是：

- ATP 负责：
  - 场景目录
  - prompt_seed 注入
  - 快照归档
  - 彩色终端输出
  - 简单 ETA
- ax-prover 负责：
  - prover prompt
  - memory
  - LeanSearch / tools
  - proving 主流程
