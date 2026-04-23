# 推理模式检查：`gpt-5.3-codex` 是否真的开启了思考模式

## 1. 结论

结论非常明确：

- ATP 当前默认实验配置 **没有显式开启** `gpt-5.3-codex` 的 reasoning mode。
- 我做了真实对照调用，结果显示：
  - 当前配置：`reasoning = null`，`reasoning_tokens = 0`，耗时约 `4.7s`
  - 临时加上 `reasoning: {effort: high}`：`reasoning_tokens = 461`，耗时约 `11.4s`

因此，你之前观察到的：

- 每轮响应时间偏短
- `T1.free` 十次尝试总耗时大约 3 分钟

和“没有显式开启高思考模式”是高度一致的。

## 2. 本地代码层面的直接证据

我先检查了 ATP 当前 experiment 配置实际合并出的 `provider_config`：

```json
{
  "temperature": 0,
  "base_url": "https://codeflow.asia/v1",
  "use_responses_api": true
}
```

关键点：

- 没有 `reasoning`
- 也没有 `reasoning_effort`

再继续看 ax-prover 实际创建出来的 LangChain 对象：

- LLM 类：`langchain_openai.chat_models.base.ChatOpenAI`
- `llm.reasoning = None`
- `llm.reasoning_effort = None`
- `llm._default_params = {"model": "gpt-5.3-codex", "stream": false}`

这说明：

- ATP 当前默认配置并没有把 reasoning 参数送进 LangChain/OpenAI 客户端。

## 3. 真实 API 对照实验

使用脚本：

- [check_reasoning_mode.py](/Users/hdm/math/elementary-number-theory/ATP/scripts/check_reasoning_mode.py)

做了两组真实调用对照。

### 3.1 当前默认配置

结果文件：

- [20260411_current_vs_high.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/reasoning_probe/20260411_current_vs_high.json)

当前配置部分显示：

- `_default_params` 中没有 `reasoning`
- 实际响应耗时：约 `4.732s`
- `usage_metadata.output_token_details.reasoning = 0`

这说明：

- 这次请求没有使用 reasoning tokens。

### 3.2 临时覆盖成 `reasoning: {effort: high}`

同一份结果文件中的对照部分显示：

- `_default_params` 中出现：

```json
"reasoning": {
  "effort": "high"
}
```

- 实际响应耗时：约 `11.420s`
- `usage_metadata.output_token_details.reasoning = 461`

这说明：

- reasoning 参数已经真正传到模型；
- 模型确实进入了有思考 token 的运行状态。

## 4. 一个很关键的附带发现

这次 live 对照里，同一题的回答质量也出现了明显差异。

测试题是：

> 求最小正整数 `n` 使得 `n^2 ≡ -1 (mod 221)`

结果：

- 当前默认配置给出的最小值是 `30`
- `high reasoning` 给出的最小值是 `21`

而正确答案确实是：

- `21`

因为：

```text
21^2 = 441 ≡ 220 ≡ -1 (mod 221)
```

这说明 reasoning mode 对结果质量也确实产生了影响，而不只是“单纯更慢”。

## 5. 为什么当前配置看起来像“没开思考”

当前 ATP 默认 profile 在：

- [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)

它使用的是：

- `openai:gpt-5.3-codex`

但默认 `provider_config` 里只有：

- `temperature`
- `api_key`
- `base_url`
- `use_responses_api`

没有：

- `reasoning`

所以 ATP 当前更像是在用：

- `gpt-5.3-codex` 的“普通请求模式”

而不是显式的高思考配置。

## 6. 一个容易误判的点：`temperature: 0`

这次检查还发现了另一个细节：

- YAML 里虽然写了 `temperature: 0`
- 但 LangChain 实际对象上的 `temperature` 仍然是 `None`

这说明：

- 对当前 `gpt-5.3-codex + Responses API` 组合来说，`temperature` 并不是一个可靠的“已生效参数”指示器；
- 真正有区分度的，是 `reasoning` 是否进入 `_default_params`，以及返回的 `reasoning_tokens` 是否大于 0。

## 7. 当前栈里应该怎么传 reasoning

这里还有一个兼容性坑：

- `reasoning_effort: high`
  - 在当前本地 `langchain-openai` 中，实例化时能接受；
  - 但真实调用 Responses API 时会报：
    - `Responses.create() got an unexpected keyword argument 'reasoning_effort'`

- `reasoning: {effort: high}`
  - 当前栈里可以正常工作；
  - 能真实产出 reasoning tokens。

因此，在你当前环境中，更稳的配置方式是：

```yaml
provider_config:
  use_responses_api: true
  reasoning:
    effort: high
```

而不是：

```yaml
provider_config:
  reasoning_effort: high
```

## 8. 我做了哪些改动

### 8.1 新增 reasoning 检查脚本

- [check_reasoning_mode.py](/Users/hdm/math/elementary-number-theory/ATP/scripts/check_reasoning_mode.py)

功能：

- 打印当前 experiment 配置实际传给 LangChain 的参数
- 可选做一次真实 live 调用
- 可选对照 `--compare-effort high`
- 输出结构化 JSON 报告

### 8.2 新增 reasoning probe 工具模块

- [reasoning_probe.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/reasoning_probe.py)

### 8.3 新增可选 reasoning profile

在：

- [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)

中新增：

- `openai_reasoning_high`
- `openai_reasoning_xhigh`

注意：

- 我没有直接把默认 `shared_profile` 切过去；
- 因为这会明显增加耗时和 token 成本。

## 9. 建议

如果你的目标是优先验证“高思考是否是破局关键”，最稳的下一步不是立刻大规模重跑 10 题，而是：

1. 先把 `shared_profile` 或 `experiment_profile` 切到 `openai_reasoning_high`
2. 只重跑：
   - `T1.free`
   - `T1.disable`
   - `T2.free`
3. 对比：
   - LeanSearch 调用次数
   - 单题耗时
   - reasoning tokens
   - 最终成功率

这样能最快判断：

- 之前的问题是不是主要因为 reasoning 没开
- 还是 reasoning 开了之后，依然主要卡在 theorem 采用和 import/type 桥接

## 10. 相关文件

- [check_reasoning_mode.py](/Users/hdm/math/elementary-number-theory/ATP/scripts/check_reasoning_mode.py)
- [reasoning_probe.py](/Users/hdm/math/elementary-number-theory/ATP/src/atp_axbench/reasoning_probe.py)
- [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)
- [20260411_current_vs_high.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/reasoning_probe/20260411_current_vs_high.json)

外部资料：

- OpenAI 最新模型指南（reasoning effort / GPT-5.3 Codex）：
  <https://platform.openai.com/docs/guides/latest-model>
