# ATP Configuration Wiki

本文档描述当前 ATP 的简化配置结构。  
当前目标是把 ATP 保持成一个“基于 ax-prover 的薄包装层”，因此配置分工尽量清楚：

- ATP 自己的行为放在 `project.yaml`
- ax-prover 的正式实验 / doctor 运行参数放在 `ax_prover_experiment.yaml` / `ax_prover_doctor.yaml`
- 模型供应商、模型名、接口地址、思考模式放在 `ax_prover_profiles.yaml`

## 1. 配置链路

当前读取顺序是：

1. [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml)  
   负责 ATP 自己的总设置，例如归档目录、默认 ax YAML、是否恢复模板文件、是否启用简单 ETA。
2. [ax_prover_experiment.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_experiment.yaml)  
   正式实验使用的 ax-prover 配置。
3. [ax_prover_doctor.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_doctor.yaml)  
   doctor 使用的 ax-prover 配置。
4. [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)  
   共享模型档案。

运行时，ATP 会：

1. 让 ax-prover 自己合并这些 YAML
2. 仅把当前场景 prompt 追加进 `prover.user_comments`
3. 清理空字符串 / `null` 的 provider 参数
4. 把 YAML 中的 `api_key` 同步到当前进程环境变量

## 2. LLM 档案结构

现在 `ax_prover_profiles.yaml` 里默认提供四个常用档案：

- `llm_profiles.openai`
- `llm_profiles.deepseek`
- `llm_profiles.anthropic`
- `llm_profiles.gemini`

不再额外拆出：

- `openai_default`
- `openai_reasoning_high`
- `openai_reasoning_xhigh`

这类“同一个 provider 再按思考模式拆 profile”的结构。

思考模式现在作为 provider 内部参数存在。例如 OpenAI：

```yaml
llm_profiles:
  openai:
    model: openai:gpt-5.3-codex
    provider_config:
      base_url: https://codeflow.asia/v1
      use_responses_api: true
      reasoning:
        effort: high
```

也就是说：

- “用哪个 provider” 由 profile 决定
- “这个 provider 是否开启思考、思考强度多大” 由 `provider_config` 决定

## 3. `shared_profile / experiment_profile / doctor_profile`

当前仍保留：

```yaml
llm_runtime:
  shared_profile: ${llm_profiles.openai}
  experiment_profile: ${llm_runtime.shared_profile}
  doctor_profile: ${llm_runtime.shared_profile}
```

它的目的不是再复制一套模型配置，而是保留一个简单切换口：

- 想让 doctor 和 experiment 共用同一模型，只改 `shared_profile`
- 想让 doctor 单独换模型，只改 `doctor_profile`
- 想让正式实验单独换模型，只改 `experiment_profile`

## 4. `base_url / api_key / model` 在哪里改

通常只需要改：

- [ax_prover_profiles.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_profiles.yaml)

最常用的是：

- `model`
- `provider_config.api_key`
- `provider_config.api_key_env`
- `provider_config.base_url`
- `provider_config.use_responses_api`
- `provider_config.reasoning`

例如：

```yaml
llm_profiles:
  openai:
    model: openai:gpt-5.3-codex
    provider_config:
      api_key: sk-xxx
      base_url: https://codeflow.asia/v1
      use_responses_api: true
      reasoning:
        effort: high
```

如果你不想把密钥直接写进 YAML，也可以使用 ATP 扩展字段：

```yaml
llm_profiles:
  openai:
    model: openai:deepseek-ai/DeepSeek-R1-0528
    provider_config:
      api_key: null
      api_key_env: NEBIUS_API_KEY
      base_url: https://api.tokenfactory.nebius.com/v1
      use_responses_api: false
      reasoning: null
```

这里的 `api_key_env` 是 ATP 自己识别的辅助字段：

- ATP 会先从这个环境变量里读取密钥
- 再自动同步到 provider 默认期待的环境变量里
- 最后在真正创建 SDK / LangChain provider 之前，把 `api_key_env` 从 `provider_config` 中移除

因此它不会变成传给 `ChatOpenAI` 的未知参数。

## 5. 空 `base_url` 的语义

ATP 会自动移除空的 provider 参数，因此：

- `base_url: null`
  表示不传，交给 provider 使用默认官方端点
- `base_url: ""`
  也视为未配置
- 只有写成非空 URL 才会真正传给 SDK

这条规则同样适用于其他可空参数。

## 6. OpenAI 兼容中转的注意事项

如果你使用 OpenAI 兼容中转：

- `model` 仍应写成 `openai:<model_name>`
- `base_url` 应写成 API 根路径，例如 `https://host/v1`
- 不要写成最终 endpoint，例如：
  - `https://host/v1/chat/completions`

否则 SDK 仍会继续拼资源路径，可能出现：

```text
/v1/chat/completions/responses
```

这类错误。

## 6.1 Nebius DeepSeek-R1-0528 示例

如果你想把下面这种 Python 调用：

```python
client = OpenAI(
    base_url="https://api.tokenfactory.nebius.com/v1/",
    api_key=os.environ.get("NEBIUS_API_KEY"),
)
```

映射到 ATP，推荐写成：

```yaml
llm_profiles:
  openai:
    model: openai:deepseek-ai/DeepSeek-R1-0528
    provider_config:
      api_key: null
      api_key_env: NEBIUS_API_KEY
      base_url: https://api.tokenfactory.nebius.com/v1
      use_responses_api: false
      reasoning: null
      temperature: null
```

这里有三个关键点：

- `model` 仍写成 `openai:...`，因为 Nebius 这条链路对 ATP 来说是 OpenAI 兼容接口
- `base_url` 写 API 根路径 `https://api.tokenfactory.nebius.com/v1`
- `use_responses_api` 必须设为 `false`，因为你给出的示例明确走的是 `chat.completions`

## 7. 为什么要把 `memory_config` 写回 YAML

当前 ATP 不再在 Python 里偷偷补 ax-prover 的 memory 默认值。  
现在正式实验和 doctor 都在 YAML 里显式声明：

```yaml
prover:
  memory_config:
    class_name: ExperienceProcessor
    init_args:
      llm_config: ${prover.prover_llm}
```

这样做的好处是：

1. ATP 更薄，少做隐式修补
2. 配置来源更清楚
3. 更贴近 ax-prover 官方 `default.yaml` 的写法

## 8. 搜索工具配置

当前 LeanSearch 完全交给 ax-prover 的 `prover.proposer_tools` 配置管理。  
ATP 不再在 Python 里做 fallback tool 注入或按环境裁剪搜索工具。

正式实验默认配置在：

- [ax_prover_experiment.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_experiment.yaml)

当前默认只保留：

```yaml
prover:
  proposer_tools:
    search_lean: ${tool_configs.search_lean}
```

也就是说：

- LeanSearch 仍由 ax-prover 原生使用
- ATP 只做旁路归档，不接管搜索决策
- `search_lean.max_results` 当前恢复为 ax-prover 官方默认值 `6`

## 9. ATP 自己的配置现在还剩什么

`project.yaml` 现在只保留 ATP 真正需要的部分：

- `execution`
  - 是否预构建
  - 是否恢复模板文件
  - 是否保存快照
  - 是否限制单次场景尝试的模型请求次数
- `console`
  - 是否彩色输出
  - 是否显示 banner
  - 是否隐藏已知 build fallback 噪声
- `runtime_status`
  - 是否启用简单 ETA
  - 是否显示时间信息
  - 历史文件路径
  - 默认估时秒数

CLI 运行时还会自动把终端输出同步保存到：

- `runs/<timestamp>/terminal.log`
- `doctor/<timestamp>/terminal.log`

因此即使中途 `Ctrl+C`，已经打印出来的日志也会保留下来。

不再保留：

- 全局 policy
- route 合规检查
- token/request 展示开关
- EWMA 细粒度时间参数

其中 `execution.max_llm_requests_per_attempt` 的语义是：

- `0`
  表示不限制单次场景尝试中的真实 LLM 请求次数
- 正整数
  表示 ATP 在当前场景尝试中，监控到第 `N + 1` 次真实模型请求即中断本次尝试

这个限制与 ax-prover 自己的：

- `prover.max_iterations`
- `runtime.max_tool_calling_iterations`

不是一回事。前两者是 prover 主循环与单轮工具循环上限；`max_llm_requests_per_attempt` 是 ATP 额外加的一层“真实 API 请求硬上限”。

## 10. 运行时 ETA

当前 `runtime_monitor` 已简化为“简单平均时间预测”：

- 若本次运行已经有正式题完成，就使用本次平均值估剩余时间
- 否则使用历史平均
- 再否则使用 `default_seconds_per_formal_scenario`

历史文件现在的核心字段是：

```json
{
  "version": 2,
  "seconds_per_formal_scenario": 180.0,
  "recorded_formal_runs": 3,
  "recent_formal_runs": []
}
```

## 11. Prompt 相关配置该怎么理解

如果你想控制实验模式提示，优先改：

- [theorem_catalog.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/theorem_catalog.yaml)

如果你想理解 ATP 怎么把这些提示交给 ax-prover，看：

- [prompt-mechanism.md](/Users/hdm/math/elementary-number-theory/ATP/doc/prompt-mechanism.md)

当前 ATP 不再自己拼一套复杂 prompt；它只会把“当前题目当前模式”的指令文本作为 `user_comments` 追加给 ax-prover。

## 12. 推荐原则

当前推荐的使用原则是：

- 改长期默认值：直接改 YAML
- 改单次实验差异：用 `--ax-config`
- ATP 尽量只负责：
  - 场景选择
  - 快照归档
  - 终端输出
  - 简单 ETA
- theorem proving、搜索、memory、prompt 主流程尽量交给 ax-prover 本体
