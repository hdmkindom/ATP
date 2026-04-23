# ATP 与 ax-prover 配置对照说明

本文档对比当前 ATP 配置文件与本机已安装的 ax-prover 官方配置，说明：

- 哪些参数与 ax-prover 官方默认一致
- 哪些参数被 ATP 显式修改过
- 哪些 ax-prover 参数当前没有出现在 ATP 配置文件中
- 哪些配置其实属于 ATP 包装层，而不是 ax-prover 本体

本文档基于以下本机环境生成：

- `ax-prover` 版本：`0.1.1`
- `openai` 版本：`2.30.0`
- ax-prover 安装目录：`/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover`

## 1. 对照所用的源文件

### 1.1 ax-prover 官方配置来源

- `ax_prover/configs/default.yaml`
- `ax_prover/configs/llms.yaml`
- `ax_prover/configs/tools.yaml`
- `ax_prover/config.py`
- `ax_prover/main.py`

### 1.2 ATP 当前配置来源

- `ATP/config/ax_prover_experiment.yaml`
- `ATP/config/ax_prover_doctor.yaml`
- `ATP/config/ax_prover_profiles.yaml`
- `ATP/config/project.yaml`

## 2. 最重要的结论

最容易误解的一点是：

- ax-prover 官方 CLI 默认会加载 `default.yaml`
- 但 ATP 运行时并不是直接从 `default.yaml` 起步

ATP 当前的运行链路是：

1. 从 `Config()` dataclass 默认值开始
2. 再叠加 `ATP/config/ax_prover_experiment.yaml` 或 `ATP/config/ax_prover_doctor.yaml`
3. 这些 ATP YAML 再通过 `import` 引入 `ATP/config/ax_prover_profiles.yaml`
4. 最后 ATP 在运行时动态注入 `prover.user_comments`

因此，判断“默认值”时要区分两种来源：

1. ax-prover `config.py` 的 dataclass 默认值
2. ax-prover CLI 默认加载的 `default.yaml / llms.yaml / tools.yaml`

ATP 当前是“参考了官方 YAML 的写法”，但并没有直接继承整份官方默认配置。

## 3. 实际加载链路

### 3.1 ax-prover 官方 CLI

官方 `ax-prover` 命令行在 `main.py` 中默认等价于：

```text
Config() + default.yaml + 用户额外 --config + dot overrides
```

因此官方 CLI 的“常用默认行为”主要来自：

- `Config()` dataclass
- `default.yaml`
- `default.yaml` 再导入的 `llms.yaml`
- `default.yaml` 再导入的 `tools.yaml`

### 3.2 ATP `run`

ATP `run` 的实际链路是：

```text
Config() + ATP/config/ax_prover_experiment.yaml + ATP/config/ax_prover_profiles.yaml + user_comments runtime overlay
```

### 3.3 ATP `doctor`

ATP `doctor` 的实际链路是：

```text
Config() + ATP/config/ax_prover_doctor.yaml + ATP/config/ax_prover_profiles.yaml + user_comments runtime overlay
```

## 4. ATP experiment / doctor 与官方默认的对照

下表中的“官方默认”主要指 ax-prover 官方 `default.yaml`；如果某项没有写在 `default.yaml` 中，则会补充说明 dataclass 默认值。

| 配置键 | ax-prover 官方默认 | ATP experiment | ATP doctor | 结论 |
| --- | --- | --- | --- | --- |
| `prover.prover_llm` | `${llm_configs.claude_opus_4_5}` | `${llm_runtime.experiment_profile}` | `${llm_runtime.doctor_profile}` | ATP 已修改 |
| `prover.proposer_tools.search_lean` | 开启，引用 `${tool_configs.search_lean_search}` | 开启，自定义 `tool_configs.search_lean` | 未配置 | experiment 近似官方，doctor 已修改 |
| `prover.proposer_tools.search_web` | 开启，引用 `${tool_configs.search_web}` | 未配置 | 未配置 | ATP 删除了官方默认 web search |
| `prover.max_iterations` | `50` | `50` | `2` | experiment 与官方一致，doctor 已修改 |
| `prover.memory_config.class_name` | `ExperienceProcessor` | `ExperienceProcessor` | `ExperienceProcessor` | 一致 |
| `prover.memory_config.init_args.llm_config` | `${prover.prover_llm}` | `${prover.prover_llm}` | `${prover.prover_llm}` | 一致 |
| `prover.summarize_output.enabled` | `true` | `true` | `false` | experiment 一致，doctor 已修改 |
| `prover.summarize_output.llm` | `${prover.prover_llm}` | `${prover.prover_llm}` | 未显式设置 | experiment 一致，doctor 精简 |
| `prover.user_comments` | 官方 `default.yaml` 未显式设置，dataclass 默认 `None` | `null`，运行时动态注入 | `null`，运行时动态注入 | ATP 采用动态注入策略 |
| `runtime.log_level` | `INFO` | `INFO` | `INFO` | 一致 |
| `runtime.max_tool_calling_iterations` | `1` | `1` | `1` | 一致 |
| `runtime.lean.cache_get_timeout` | dataclass 默认 `600`，官方 YAML 未覆盖 | `600` | `300` | experiment 与 dataclass 一致，doctor 已修改 |
| `runtime.lean.build_timeout` | dataclass 默认 `1200`，官方 YAML 未覆盖 | `1200` | `900` | experiment 与 dataclass 一致，doctor 已修改 |
| `runtime.lean.check_file_timeout` | dataclass 默认 `180`，官方 YAML 未覆盖 | `360` | `120` | ATP 已修改 |
| `runtime.lean.max_concurrent_builds` | `default.yaml` 设为 `12`，dataclass 默认 `4` | `4` | `1` | ATP 未继承官方 YAML 的 `12`，而是显式改为更保守值 |
| `runtime.lean_interact.verbose` | dataclass 默认 `false` | 未配置 | 未配置 | ATP 当前未暴露 |

### 4.1 关于 `max_concurrent_builds` 的特别说明

这个参数最容易误判。

如果直接看 ax-prover 官方 `default.yaml`，会以为默认值是：

```yaml
runtime:
  lean:
    max_concurrent_builds: 12
```

但 ATP 并没有加载官方 `default.yaml`，而是从 `Config()` 起步。因此如果 ATP 自己不写这个键，基础值其实会退回到 dataclass 默认：

```python
max_concurrent_builds = 4
```

当前 ATP experiment 又显式写成了 `4`，doctor 显式写成了 `1`。  
所以对 ATP 而言，这一项不是“沿用官方 YAML 默认”，而是“显式采用更保守的并发设置”。

## 5. ATP 的工具配置与官方 `tools.yaml` 的对照

### 5.1 官方 `tools.yaml` 中存在的工具模板

ax-prover 官方提供了以下工具模板：

- `tool_configs.search_web`
- `tool_configs.search_lean_search`
- `tool_configs.search_lean_search_local`
- `tool_configs.search_lean_search_ax`

### 5.2 ATP 当前暴露的工具模板

ATP 在 `ax_prover_experiment.yaml` 中只保留了一个本地模板：

- `tool_configs.search_lean`

它的值是：

- `tool_type: search_lean_search`
- `server_url: https://leansearch.net`
- `max_results: 6`
- `timeout: 60`
- `max_retries: 3`
- `retry_delay: 2`

这组数值与官方 `tool_configs.search_lean_search` 完全一致。

### 5.3 已删除或未暴露的官方工具参数

以下官方工具模板当前没有出现在 ATP 配置文件中：

- `search_web`
- `search_lean_search_local`
- `search_lean_search_ax`

其中：

- `search_web` 是 ATP 主动删除的，因为当前实验倾向“LeanSearch only”
- `search_lean_search_local` 与 `search_lean_search_ax` 是官方提供的替代搜索端点，但 ATP 当前没有做成可切换模板

## 6. ATP 的模型档案与官方 `llms.yaml` 的对照

### 6.1 官方 `llms.yaml` 的结构

官方 `llms.yaml` 采用的是“很多具名模型 preset”的结构，例如：

- `claude_opus_4_6`
- `claude_opus_4_5`
- `claude_sonnet_4_5`
- `claude_haiku_4_5`
- `gemini_3_pro`
- `gemini_3_flash`
- `gpt_5_2`
- `gpt_5_nano`
- `qwen`

### 6.2 ATP `ax_prover_profiles.yaml` 的结构

ATP 采用的是“按 provider 只保留一份当前使用档案”的结构：

- `llm_profiles.openai`
- `llm_profiles.anthropic`
- `llm_profiles.gemini`

并通过：

- `llm_runtime.shared_profile`
- `llm_runtime.experiment_profile`
- `llm_runtime.doctor_profile`

来切换 experiment 与 doctor 实际使用哪一份 profile。

### 6.3 OpenAI profile 对照

官方最接近的 OpenAI preset 是：

```yaml
llm_configs:
  gpt_5_2:
    model: openai:gpt-5.2
    provider_config:
      temperature: null
      max_tokens: null
      reasoning:
        effort: high
```

ATP 当前 OpenAI profile 则是：

- `model: openai:gpt-5.3-codex`
- `temperature: 0`
- 显式配置了 `api_key`
- 显式配置了 `base_url`
- 显式配置了 `use_responses_api: true`
- 保留了 `reasoning.effort: high`
- 显式配置了 `retry_config`

结论：

- OpenAI 模型名已修改
- provider 参数已修改
- retry 策略已修改
- ATP 支持 OpenAI 兼容中转，这是官方 `llms.yaml` 默认没有预置的

### 6.4 Anthropic profile 对照

官方最接近的 Anthropic preset 是：

```yaml
llm_configs:
  claude_opus_4_5:
    model: anthropic:claude-opus-4-5
    provider_config:
      temperature: 1.0
      max_tokens: null
      betas: [...]
      thinking:
        type: enabled
        budget_tokens: 10000
```

ATP 当前 Anthropic profile 则是：

- `model: anthropic:claude-sonnet-4-5-20250929`
- `temperature: 0`
- `thinking: null`
- 显式配置了 `retry_config`

结论：

- 模型已修改
- 官方为 Claude 预置的 thinking/betas/max_tokens 参数，ATP 当前没有跟随
- retry 策略已修改

### 6.5 Gemini profile 对照

官方最接近的 Gemini preset 是：

```yaml
llm_configs:
  gemini_3_flash:
    model: google_genai:gemini-3-flash-preview
    provider_config:
      temperature: 1.0
      max_tokens: null
      include_thoughts: true
      thinking_level: high
```

ATP 当前 Gemini profile 则是：

- `model: google_genai:gemini-2.5-flash`
- `temperature: 0`
- `reasoning_effort: null`
- 显式配置了 `retry_config`

结论：

- 模型已修改
- 官方 Gemini preset 的 `include_thoughts / thinking_level` 当前没有体现在 ATP 中
- retry 策略已修改

### 6.6 retry_config 的差异

官方 ax-prover 在 dataclass 中给 LLM 的默认 retry 配置是：

```yaml
stop_after_attempt: 10000
wait_exponential_jitter: true
exponential_jitter_params:
  initial: 0.5
  max: 3
  exp_base: 2.0
  jitter: 1.0
```

ATP 当前三个 provider 都改成了更显式的 profile retry 配置，当前值为：

```yaml
stop_after_attempt: 100
wait_exponential_jitter: true
exponential_jitter_params:
  initial: 1.0
  max: 8
  exp_base: 2.0
  jitter: 0.5
```

这意味着：

- ATP 没有沿用 ax-prover dataclass 的超大默认重试上限 `10000`
- ATP 采用了更长的单次退避窗口

## 7. 哪些参数属于 ATP，而不是 ax-prover

`ATP/config/project.yaml` 整个文件都属于 ATP 包装层配置，不会原样进入 ax-prover `Config`。

它的参数包括：

- `catalog_path`
- `experiment_ax_config`
- `doctor_ax_config`
- `artifacts_dir`
- `execution.*`
- `console.*`
- `runtime_status.*`

这些键是 ATP 自己使用的，不是 ax-prover 本体配置。

例如：

- `execution.restore_source_after_run`
- `execution.persist_last_attempt_on_failure`
- `execution.archive_source_snapshots`
- `console.enable_color`
- `console.show_banner`
- `runtime_status.default_seconds_per_formal_scenario`

都属于 ATP 自己的运行包装逻辑。

## 8. 哪些 ax-prover 参数当前没有出现在 ATP 配置文件中

下面这些参数或配置块，当前没有在 ATP YAML 中标准化暴露出来。

### 8.1 官方默认存在但 ATP 未使用

- `prover.proposer_tools.search_web`
- `tool_configs.search_web`
- `tool_configs.search_lean_search_local`
- `tool_configs.search_lean_search_ax`

### 8.2 ax-prover dataclass 支持，但 ATP 当前未显式配置

- `runtime.lean_interact.verbose`

### 8.3 provider_config 中理论可透传，但 ATP 当前未预置

这些参数虽然不在 ATP YAML 模板里，但如果你手动加入到 `provider_config` 中，ATP 通常仍会透传给底层 LangChain / provider SDK：

- OpenAI 相关：
  - `max_tokens`
  - `timeout`
  - `organization`
  - `default_headers`
  - `extra_body`
  - `verbosity`
- Anthropic 相关：
  - `betas`
  - `max_tokens`
  - `thinking.type`
  - `thinking.budget_tokens`
- Gemini 相关：
  - `include_thoughts`
  - `thinking_level`
  - 其他 provider 支持的扩展键

也就是说，这些键不是“ATP 禁止使用”，而是“ATP 当前没有做成标准模板字段”。

## 9. 当前 ATP 配置里哪些与官方最接近

当前 ATP 中与官方最接近的部分主要有：

- `prover.max_iterations = 50`（experiment）
- `runtime.max_tool_calling_iterations = 1`
- `runtime.log_level = INFO`
- `memory_config.class_name = ExperienceProcessor`
- `memory_config.init_args.llm_config = ${prover.prover_llm}`
- `summarize_output.enabled = true`（experiment）
- LeanSearch 的 `server_url / max_results / timeout / max_retries / retry_delay`

## 10. 当前 ATP 明显改动过的部分

ATP 当前明确改动过的部分主要有：

- 不再沿用官方 `default.yaml` 的整套导入链
- 删除了 `search_web`
- 自己维护 `ax_prover_profiles.yaml`，不再直接使用官方 `llms.yaml`
- experiment 与 doctor 分别设置了不同的 Lean build 超时
- `check_file_timeout` 改为 experiment `360`、doctor `120`
- `max_concurrent_builds` 改为 experiment `4`、doctor `1`
- `user_comments` 采用 ATP 动态注入模式
- 引入 `project.yaml` 作为 ATP 自己的包装层配置

## 11. 建议如何理解当前结构

如果只想知道“实际 ATP 在跑什么”：

1. 先看 `ATP/config/project.yaml`
2. 再看 `ATP/config/ax_prover_experiment.yaml` 或 `ATP/config/ax_prover_doctor.yaml`
3. 最后看 `ATP/config/ax_prover_profiles.yaml`

如果想知道“它和官方 ax-prover 默认差在哪里”：

1. 先看官方 `default.yaml`
2. 再看官方 `llms.yaml`
3. 再看官方 `tools.yaml`
4. 最后对照 ATP 三个 YAML

如果想让 ATP 更接近官方默认：

- 最直接的办法不是继续手工补默认值
- 而是让 ATP 显式导入官方 `default.yaml`，然后再做少量覆盖

当前 ATP 采用的是另一种策略：  
不直接导入官方默认整套 YAML，而是只保留实验需要的那部分，再由 ATP 自己控制包装层行为。
