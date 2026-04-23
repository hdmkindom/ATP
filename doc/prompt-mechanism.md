# ATP / ax-prover Prompt 注入机制

本文档说明两件事：

1. ax-prover 原生 prompt 是怎么构造的；
2. ATP 现在如何在不改写 prover 机制的前提下，向其中追加我们自己的场景提示。

## 1. 结论

当前 ATP 采用的是“薄包装”策略：

- ax-prover 自己负责 system prompt、输出格式约束、工具调用协议和 prover 主流程；
- ATP 不再重写这些 prompt；
- ATP 只把场景对应的简短提示，作为 `prover.user_comments` 追加给 ax-prover。

因此，当前链路可以概括为：

```text
theorem_catalog.yaml
  -> TheoremSpec.free_instruction / disable_instruction / route instruction
     (测试场景则直接使用 ScenarioSpec.user_comments)
  -> ATP/prompts.py: render_user_comments(...)
  -> prover.user_comments
  -> ax-prover 在 proposer prompt 中追加 <user-comments> ... </user-comments>
```

## 2. ax-prover 原生 prompt 在哪里

ax-prover 原生 prover prompt 的核心代码在安装环境中：

- [agent.py](/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/prover/agent.py)
- [prompts.py](/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/prover/prompts.py)

当前实现里，ax-prover 会：

1. 读取自己的 system prompt 常量  
   例如 `PROPOSER_SYSTEM_PROMPT` / `PROPOSER_SYSTEM_PROMPT_SINGLE_SHOT`
2. 读取待证明目标对应的完整 Lean 文件
3. 在有 `user_comments` 时，把它追加到 proposer prompt 中
4. 再把完整 prompt 发给模型

所以，ATP 不需要也不应该复制一份 ax-prover 的 system prompt。  
只要通过 `user_comments` 做“附加提示”即可。

## 3. `user_comments` 在 ax-prover 中的含义

`user_comments` 是 ax-prover 原生配置项，不是 ATP 发明的字段。

在 ax-prover 语义里，它的作用是：

- 给 prover 默认 prompt 追加一段额外说明；
- 这段说明不会替换 system prompt；
- 它只是附加信息。

这也是为什么 ATP 现在推荐把：

- [ax_prover_experiment.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_experiment.yaml)
- [ax_prover_doctor.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_doctor.yaml)

中的 `prover.user_comments` 保持为 `null`。

原因很简单：

- YAML 里的静态 `user_comments` 更像“全局 prompt”
- ATP 的实验是按题目、按模式变化的
- 所以更合理的做法是：运行时由 ATP 动态覆盖这个字段

## 4. ATP 现在怎么注入 prompt

ATP 当前的 prompt 注入很简单，只有三步。

### 4.1 `theorem_catalog.yaml` 提供场景提示来源

文件：

- [theorem_catalog.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/theorem_catalog.yaml)

旧版四模式配置里，会自动派生出：

- `free_instruction -> T?.free`
- `disable_instruction -> T?.disable`
- `route_a.instruction -> T?.routeA`
- `route_b.instruction -> T?.routeB`

这些内容不会被复制成全局 prompt，也不会常驻在场景对象里作为独立 prompt 副本；
ATP 会在运行时根据“当前题目 + 当前模式”动态选出对应文本，写入 ax-prover 的
`prover.user_comments`。

对应解析代码在：

- [catalog.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/catalog.py)

### 4.2 ATP 不再自己拼复杂 prompt

当前 ATP 的 prompt 适配器在：

- [prompts.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/prompts.py)

现在它的行为是：

- 对正式候选题：
  - `free -> theorem.free_instruction`
  - `disable -> theorem.disable_instruction`
  - `guided -> theorem.routes[route_hint].instruction`
- 对 smoke/test 这类测试场景：
  - 直接返回 `scenario.user_comments`
- 不再附加自定义 mode banner
- 不再额外注入 LeanSearch 使用规则
- 不再拼 theorem 骨架、禁用 regex、路线判定提示等包装层逻辑

也就是说，ATP 现在只做一件事：

```text
把“当前场景对应的那一段 theorem-level 指令文本”原样交给 ax-prover
```

### 4.3 `runner.build_ax_config(...)` 在运行时覆盖 `prover.user_comments`

ATP 运行场景时，会在合并 ax-prover 配置时叠加一层运行时覆盖：

```python
{"prover": {"user_comments": user_comments}}
```

这里的 `user_comments` 就是：

- `render_user_comments(scenario)`

对应代码在：

- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)

## 5. 现在是否还需要 ATP 自己写复杂 prompt

当前判断是：**通常没有必要。**

更准确地说，ATP 仍然需要“场景提示”，但不需要重写 prover prompt 本体。

推荐边界是：

- ax-prover 负责：
  - system prompt
  - 输出结构
  - 工具调用协议
  - proposer / builder / reviewer / memory 流程
- ATP 负责：
  - 把每个实验场景的简短意图，写在 theorem catalog 的 `free_instruction / disable_instruction / route_*`
    或测试场景的 `user_comments` 中
  - 在运行时通过 `user_comments` 附加给 ax-prover

这样有几个好处：

1. ATP 不会和 ax-prover 的原生 prompt 演化相冲突
2. 我们更容易判断问题到底出在 prover，还是出在实验提示
3. ATP 代码会更薄、更稳定

## 6. `free / disable / guided` 三种模式现在分别是什么

当前 ATP 的三种模式，本质上只是三种不同的 `user_comments` 文本来源：

- `free`
  来自 `free_instruction`
- `disable`
  来自 `disable_instruction`
- `guided`
  来自对应路线的 `instruction`

也就是说：

- ATP 仍保留三种实验模式
- 但 ATP 不再在代码里对这些模式附加二次推理规则
- 这些模式的差异尽量回到 theorem catalog 的文本配置中

## 7. 对 `user_comments` 的建议

建议分两种情况理解。

### 7.1 在 ATP CLI 链路下

例如：

```bash
python ATP/scripts/atp_axbench.py run T1.free
```

此时真正生效的 `user_comments`，来自：

- theorem catalog
- `render_user_comments(...)`

而不是 `ax_prover_experiment.yaml` 里手写的静态值。

### 7.2 在不经过 ATP 的原生 ax-prover 链路下

如果你直接使用 ax-prover 自己的 YAML，那么：

- `prover.user_comments` 就是一个普通的全局附加 prompt

所以可以把它理解成：

- 对 ax-prover 来说，它是“全局附加提示”
- 对 ATP 来说，它是“每个场景的动态注入口”

## 8. 当前简化后的设计原则

这次 ATP prompt 机制调整后，原则是：

1. ATP 不复制 ax-prover 的 system prompt
2. ATP 不在代码里再做复杂 prompt 拼装
3. ATP 只把场景提示通过 `user_comments` 追加进去
4. 实验差异尽量写在 YAML，而不是写死在 Python 逻辑里

## 9. 相关文件

- [theorem_catalog.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/theorem_catalog.yaml)  
  场景 prompt 文本来源
- [catalog.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/catalog.py)  
  将 theorem catalog 解析成 `ScenarioSpec`
- [prompts.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/prompts.py)  
  当前只负责按场景挑出对应的 theorem-level 指令文本并透传
- [runner.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/runner.py)  
  在运行时把 prompt 写入 `prover.user_comments`
- [agent.py](/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/prover/agent.py)  
  ax-prover 原生 proposer prompt 组装位置
- [prompts.py](/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/prover/prompts.py)  
  ax-prover 原生 system prompt 常量
