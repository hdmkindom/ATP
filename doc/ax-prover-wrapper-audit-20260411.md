# ATP 对 ax-prover 的包装层审计（2026-04-11）

## 1. 目的

这个文档回答一个具体问题：

> 现在 `gpt-5.3-codex` 在 `T1` 这类题上表现不理想，是否是 ATP 包装层改坏了 ax-prover 的机制？

结论先说：

- ATP 包装层**确实改动了 ax-prover 的部分默认行为**；
- 但按当前排查结果，`T1.free` 的主要失败仍然更像是：
  - 搜索结果采用不稳定；
  - 本地 import / 类型桥接不到位；
  - prompt 诱导方向还不够精确；
- 没有证据表明 ATP 已把 ax-prover 的核心 prover loop 直接改坏。

## 2. ATP 当前会改哪些东西

### 2.1 动态覆盖 `prover.user_comments`

文件：

- [prompts.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/prompts.py)
- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)

ATP 不直接使用 experiment YAML 里静态写死的 `user_comments`，而是运行时按场景生成 prompt，再写入：

```python
{"prover": {"user_comments": user_comments}}
```

这意味着：

- ATP 会影响 ax-prover 每轮看到的额外提示；
- 但不会替换 ax-prover 自己的 system prompt / 结构化输出协议。

### 2.2 补回 dataclass 配置里缺失的默认项

文件：

- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)

ATP 早期从 dataclass `Config()` 起步合并配置时，漏掉了官方 `default.yaml` 中一些只靠 YAML 才会注入的默认项。现在 ATP 会补两类关键内容：

1. `memory.llm`
2. proposer 搜索工具

这一步的作用是“补齐原本该有的默认值”，不是额外篡改 prover 逻辑。

### 2.3 记录 LeanSearch 与 iteration 快照

文件：

- [leansearch_trace.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/leansearch_trace.py)
- [iteration_archive.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/iteration_archive.py)

ATP 会给 ax-prover 的 LeanSearch 调用包一层归档器，记录：

- query
- result_text
- error
- duration

这层包装是透明的：  
它不会改 LeanSearch 的返回值，只做旁路记录。

### 2.4 关闭 LangSmith tracing

文件：

- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)

ATP 会在进程内清理 LangSmith 相关环境变量，避免外部 tracing 干扰运行。

这会影响观测与日志，但不会改变证明本身的语义。

### 2.5 对 proposer tools 做环境裁剪

现在 experiment YAML 会显式配置：

- `search_lean`
- `search_web`

ATP 在运行前会做一次环境裁剪：

- 没有 `TAVILY_API_KEY` 时自动移除 `search_web`

这会影响“有哪些工具可用”，但这是为了避免暴露必然报错的无效工具。

## 3. ATP 没有改哪些东西

截至目前，ATP 没有去改 ax-prover 的这些核心部分：

- proposer / builder / memory 的状态机结构
- ax-prover 默认的 system prompt 模板
- 结构化输出 schema
- LeanSearch 工具的网络请求逻辑
- builder 真正调用 `lake env lean` / `lake build` 的机制

也就是说：

- ATP 会改“提示词”和“配置默认值”
- ATP 不会直接改“ax-prover 如何做 proposal / feedback / memory 路由”

## 4. 当前最值得警惕的一处历史问题

历史上 ATP 确实引入过一个实质性 bug：

- 早期没有把 `memory.llm` 从官方 `default.yaml` 补回来；
- 导致第一次 build 失败后进入 memory 节点时出现：
  - `AttributeError: 'NoneType' object has no attribute 'ainvoke'`

这个问题后来已经修复。

对应修复逻辑在：

- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)

因此，如果你当前看到的是：

- 搜索已经触发
- memory 继续迭代正常
- 没有 `NoneType.ainvoke`

那就不属于这个旧 bug。

## 5. 为什么现在不像“包装层把系统改坏了”

结合：

- [run-analysis-20260411_210627.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_210627.md)
- [run-analysis-20260411_214642.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_214642.md)

可以看出几件事：

1. 在 `20260411_210627`，LeanSearch 已经被调用 2 次。
2. 在 `20260411_214642`，LeanSearch 已经被调用 7 次。
3. 当前失败主要表现为：
   - theorem 存在但 import 不对；
   - theorem 名存在但对象类型不匹配；
   - theorem 名本地根本不存在；
   - 手工路线缺少 `Finset.mul_sum` / `ring` 等关键上下文。

这些都更像“证明策略与本地环境适配问题”，而不是“ax-prover 主循环失灵”。

如果 ATP 真把核心机制改坏了，更常见的症状应该是：

- 从不进入搜索工具
- memory 节点直接崩掉
- proposal 结构化输出解析失败
- 工具返回值被改坏

当前证据并不支持这些结论。

## 6. ATP 目前最可能影响结果的地方

尽管没有证据表明核心 loop 被改坏，但 ATP 包装层仍然会实质影响结果，主要在两个位置：

### 6.1 `user_comments`

ATP 会把 theorem catalog 里的 prompt 注入给 ax-prover。

这意味着：

- prompt 写得过强，会把模型往某条错误 theorem 家族上推；
- prompt 写得过弱，模型又可能完全不搜索。

所以 prompt 设计确实会显著影响 `T1.free` 的行为。

### 6.2 proposer tools 的可见性

如果 `search_lean` 没挂上，模型几乎必然会更多地猜 theorem 名。

现在这点已经确认恢复正常。

因此当前更值得做的是：

- 精调 prompt 与 search hints
- 提高“搜索结果本地适用性检查”

而不是继续怀疑“工具根本没挂上”。

## 7. 目前的审计结论

一句话总结：

> ATP 包装层会影响 ax-prover 的搜索行为和提示词上下文，但当前没有证据表明它把 ax-prover 的核心机制改坏了；`T1` 系列失败更像是 theorem 采用、import 与类型桥接问题。

## 8. 相关文件

- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)
- [prompts.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/prompts.py)
- [leansearch_trace.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/leansearch_trace.py)
- [iteration_archive.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/iteration_archive.py)
- [run-analysis-20260411_210627.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_210627.md)
- [run-analysis-20260411_214642.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_214642.md)
