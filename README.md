# ATP Ax-Prover Benchmark Framework

## 1. Purpose

本项目实现了一个围绕 `ATP/temTH` 模板文件的 ax-prover 实验框架，用于对同一批定理在不同提示模式下进行可重复、可归档、可扩展的证明实验。

当前默认覆盖：

- `test` 冒烟场景
- `T1` 到 `T10` 候选定理
- `free / disable / guided` 三类模式

其中 `guided` 当前默认展开为 `routeA` 与 `routeB`，但框架已支持在 YAML 中扩展为更多路线和更多自定义场景。

## 2. Directory Layout

```text
ATP/
├── README.md -- 项目总览、部署方式与使用入口
├── artifacts/ -- 运行结果、doctor 报告与每轮归档输出目录
├── config/ -- YAML 配置目录
│   ├── ax_prover_doctor.yaml -- doctor 命令使用的 ax-prover 配置
│   ├── ax_prover_experiment.yaml -- 正式实验使用的 ax-prover 配置
│   ├── ax_prover_profiles.yaml -- 共享的 provider/model/base_url/retry 档案
│   ├── project.yaml -- ATP 项目级总配置
│   └── theorem_catalog.yaml -- test 场景与候选定理目录
├── scripts/ -- 命令行入口脚本目录
│   ├── atp_axbench.py -- ATP CLI 脚本入口
│   ├── min_ax_prover.py -- 单题直连 ax-prover 的最小测试脚本
│   └── install_atp.sh -- Linux / macOS 自动安装脚本
├── src/ -- 主代码目录
│   └── atp_axbench/
│       ├── __init__.py -- 包版本入口
│       ├── __main__.py -- `python -m atp_axbench` 入口
│       ├── catalog.py -- 题目目录加载与场景选择逻辑
│       ├── cli.py -- CLI 参数解析与子命令分发
│       ├── console.py -- 终端颜色、日志过滤与状态打印
│       ├── direct_prove.py -- 单题直连 ax-prover 的最小配置与 CLI 逻辑
│       ├── doctor.py -- 环境检查与 smoke proof 逻辑
│       ├── iteration_archive.py -- 每轮 proposal 快照归档
│       ├── leansearch_trace.py -- LeanSearch 查询归档
│       ├── models.py -- 结构化数据模型
│       ├── paths.py -- 目录路径常量
│       ├── prompts.py -- 模式提示渲染
│       ├── reporting.py -- 结果落盘与 Markdown 汇总
│       ├── reasoning_probe.py -- reasoning 模式诊断工具
│       ├── runner.py -- ax-prover 调用与单次/批量运行逻辑
│       ├── runtime_monitor.py -- 简单 ETA 与运行时间预测
│       └── settings.py -- YAML 配置加载
├── temTH/ -- 冒烟测试与正式题目模板
```

## 3. Deployment

### 3.1 Common Requirements

空设备部署至少需要以下组件：

- Git
- Python 3.11 或更高版本
- Lean 4 / Lake / Elan
- 网络可访问的 LLM provider 接口
- 与所选 provider 对应的 API key

建议使用独立 Python 虚拟环境，例如 `~/ax-prover-env`。

### 3.2 Linux

以下示例以 Debian / Ubuntu 为例：

```bash
sudo apt update
sudo apt install -y git curl python3 python3-venv python3-pip build-essential
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y
source "$HOME/.elan/env"

git clone <your-repo-url> elementary-number-theory
cd elementary-number-theory

python3 -m venv ~/ax-prover-env
source ~/ax-prover-env/bin/activate
python -m pip install --upgrade pip
pip install ax-prover omegaconf

lake build
python ATP/tests/run_tests.py
```

### 3.3 macOS

以下示例以 Homebrew 为例：

```bash
brew install git python elan-init
elan default stable

git clone <your-repo-url> elementary-number-theory
cd elementary-number-theory

python3 -m venv ~/ax-prover-env
source ~/ax-prover-env/bin/activate
python -m pip install --upgrade pip
pip install ax-prover omegaconf

lake build
python ATP/tests/run_tests.py
```

如果 `elan-init` 不在你的 Homebrew 仓库中，可直接使用官方 `elan-init.sh` 脚本安装 Elan。

### 3.4 Windows

推荐方案是 **WSL2 + Ubuntu**。原因：

- Lean / Lake / shell 工具链在 WSL2 下更接近 Linux 参考环境
- 本项目大量命令默认以 POSIX shell 为例
- 归档、脚本和路径行为更稳定

WSL2 推荐流程：

1. 安装 WSL2 与 Ubuntu。
2. 在 Ubuntu 内按上面的 Linux 步骤部署。
3. 在 VS Code 中使用 Remote WSL 打开仓库。

如果必须使用原生 Windows：

1. 安装 Git for Windows。
2. 安装 Python 3.11。
3. 安装 Elan。
4. 在 PowerShell 中创建虚拟环境并安装 `ax-prover` 与 `omegaconf`。
5. 确认 `lake`, `lean`, `python` 都在 `PATH` 中。

原生 Windows 流程理论可行，但当前项目未对 PowerShell / CMD 下的全部边界行为做系统验证。

### 3.5 API Key and Secrets

ax-prover 会从仓库根目录的 `.env.secrets` 中读取 provider 凭据。常用变量包括：

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`

如需使用 OpenAI 兼容中转，请在 `config/ax_prover_profiles.yaml` 中填写对应 `base_url`。

## 4. First Run

推荐首次部署完成后依次执行：

```bash
source ~/ax-prover-env/bin/activate
python ATP/tests/run_tests.py
python ATP/scripts/atp_axbench.py list
python ATP/scripts/atp_axbench.py doctor --skip-proof
python ATP/scripts/atp_axbench.py run test --skip-prebuild
```

如果 `doctor` 的 `llm_ping` 失败，应优先检查：

- `.env.secrets` 中的 API key 是否存在且可用
- `config/ax_prover_profiles.yaml` 中的 `model`
- `config/ax_prover_profiles.yaml` 中的 `base_url`

## 5. Configuration

### 5.1 Shared LLM Defaults

`doctor` 与正式实验当前默认共用同一份 LLM 档案：

```yaml
llm_runtime:
  shared_profile: ${llm_profiles.openai_default}
  experiment_profile: ${llm_runtime.shared_profile}
  doctor_profile: ${llm_runtime.shared_profile}
```

因此，通常只需要编辑 `config/ax_prover_profiles.yaml`，就可以同时调整：

- provider
- model
- base_url
- retry 策略

### 5.2 Empty `base_url`

ATP 会在运行前自动清理空字符串与 `null` 的 provider 参数。因此：

- `base_url: null` 表示使用 provider 默认端点
- `base_url: ""` 也会被视为未配置
- 只有非空 URL 才会真正传给 ax-prover / LangChain

### 5.3 Doctor vs Experiment

当前默认建议：

- `doctor` 与正式实验共用同一接口配置
- 只在需要做特殊 smoke 调试时，才单独改 `doctor_profile`

这样可以避免“doctor 可用、正式实验却在用另一套接口”的配置漂移问题。

详细配置说明见：

- [configuration-wiki.md](/Users/hdm/math/elementary-number-theory/ATP/doc/configuration-wiki.md)

## 6. Commands

常用命令如下：

```bash
source ~/ax-prover-env/bin/activate
python ATP/scripts/atp_axbench.py list
python ATP/scripts/atp_axbench.py doctor
python ATP/scripts/atp_axbench.py run test
python ATP/scripts/atp_axbench.py run T1
python ATP/scripts/atp_axbench.py run candidates --repeats 2
```

命令与参数详解见：

- [command-wiki.md](ATP/doc/command-wiki.md)

如果你只想绕过 ATP 批量实验层，直接验证“当前 `model / api_key / base_url` 能否驱动 ax-prover 证明单个 Lean 目标”，可以使用最小脚本：

```bash
source ~/ax-prover-env/bin/activate
python ATP/scripts/min_ax_prover.py \
  --target ATP/temTH/CandidateTheorems/T9/Free.lean:candidate_T9_free \
  --model openai:gpt-5.3-codex \
  --base-url https://your-relay.example/v1 \
  --api-key 'YOUR_API_KEY' \
  --use-chat-completions \
  --skip-prebuild
```

说明：

- 该脚本默认沿用 `ATP/config/ax_prover_experiment.yaml` 的其他 ax-prover 运行参数。
- `--model / --base-url / --api-key` 只覆盖本次运行，不会改写 YAML。
- `--dry-run` 可先检查最终注入给 ax-prover 的关键配置。
- 目标必须是现有 Lean 文件中的 `path/to/file.lean:theorem_name`，而不是自然语言题目。

## 7. Artifact Policy

每次运行默认会归档：

- 批量汇总 JSON / Markdown
- 单场景 `result.json`
- 原始源文件快照
- 结束时文件快照
- 恢复后文件快照
- 每轮 proposal 重建出的完整 Lean 文件
- 每轮 proposal 对应的 JSON 元数据
- ax-prover 消息流

单轮文件命名采用“月日时分 + 轮次编号”形式，例如：

```text
04051942_iter01.lean
04051943_iter02.lean
```

## 8. Design Policy on Source Files

框架默认不把目标文件从 `temTH` 真正移动到运行目录。当前策略是：

1. 原地运行
2. 运行前保存快照
3. 运行中保存每轮快照
4. 结束后恢复模板
5. 保存恢复后快照

这样可以保持 Lean 模块路径稳定，避免把路径迁移引入证明实验本身。

## 9. Extensibility

当前框架已支持显式 `scenarios` 结构，因此未来如果要增加：

- 第三条、第四条甚至第五条证明路线
- 新的模式族
- 某一道题的专用场景

通常只需要修改 `config/theorem_catalog.yaml`，而不需要改 Python 代码。

建议未来新增题目时直接采用 `routes + scenarios` 显式写法，而不是继续依赖旧版四模式自动派生格式。

## 10. Additional Documentation

建议配合阅读以下文档：

- [architecture.md](/Users/hdm/math/elementary-number-theory/ATP/doc/architecture.md)
- [command-wiki.md](/Users/hdm/math/elementary-number-theory/ATP/doc/command-wiki.md)
- [configuration-wiki.md](/Users/hdm/math/elementary-number-theory/ATP/doc/configuration-wiki.md)
- [engineering-notes.md](/Users/hdm/math/elementary-number-theory/ATP/doc/engineering-notes.md)

## 11. YAML API Key and OpenAI-Compatible Endpoints

当前 ATP 允许把 provider 的 `api_key` 直接写进 `config/ax_prover_profiles.yaml` 的 `provider_config` 中。运行时，ATP 会先从 YAML 读取该值，再同步到当前进程环境变量中，因此不必再额外修改外部 ax-prover 配置。

对于 OpenAI 兼容接口，需要特别注意：

- `base_url` 应填写 API 根路径，例如 `https://codeflow.asia/v1`
- 不应填写最终 endpoint，例如 `https://codeflow.asia/v1/chat/completions`
- 某些模型名如 `gpt-5.2-codex` 会被当前 `langchain-openai` 默认视为更偏向 Responses API；如果你的中转只支持 `/v1/chat/completions`，需要在 YAML 中显式设置 `use_responses_api: false`

当前默认的 OpenAI 兼容档案已经按上述约定写好，可直接作为参考。

## 12. Iteration Limit and Final Failed Attempt

ATP / ax-prover 当前与“调试轮次”直接相关的主要配置有两层：

- `config/ax_prover_experiment.yaml` 中的 `prover.max_iterations`
- `config/ax_prover_experiment.yaml` 中的 `runtime.max_tool_calling_iterations`
- `config/project.yaml` 中的 `execution.max_llm_requests_per_attempt`

其中：

- `max_iterations` 控制单个 theorem 最多允许多少轮 proposer / reviewer 主循环
- `max_tool_calling_iterations` 控制单轮中工具往返的上限
- `max_llm_requests_per_attempt` 控制 ATP 对“单次场景尝试内真实模型请求次数”的硬上限

当达到最大轮次仍未成功时，ax-prover 会停止继续尝试。ATP 会照常归档最后一次尝试结果，并在 `result.json` 中写出 `max_iterations_reached`。

如果你还希望在“模型请求次数”层面做硬中断，可以在 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml) 中设置：

```yaml
execution:
  max_llm_requests_per_attempt: 12
```

含义是：

- `0` 表示不限制
- 正整数表示当前场景一旦发出到第 `N + 1` 次真实 LLM 请求，就立即中断该场景尝试
- 该中断不会丢失归档，`result.json`、快照和 `terminal.log` 仍会保留
- 它只终止当前场景尝试，不会强制结束整个 batch

如果你希望“失败到上限后，把最后一次失败产物留在模板文件里，不要恢复原模板”，现在可以在 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml) 中打开：

```yaml
execution:
  persist_last_attempt_on_failure: true
```

默认值是 `false`。

## 13. Automated Installer for Linux and macOS

现在仓库提供了一个面向 Linux / macOS 的自动安装脚本：

```bash
bash ATP/scripts/install_atp.sh
```

常用可选参数：

```bash
bash ATP/scripts/install_atp.sh --venv-path ~/ax-prover-env
bash ATP/scripts/install_atp.sh --skip-build
bash ATP/scripts/install_atp.sh --skip-tests
```

该脚本会：

1. 检查 `python3`、`git` 等基础命令。
2. 按需安装 `elan`。
3. 创建 Python 虚拟环境。
4. 安装 `ax-prover` 与 `omegaconf`。
5. 运行 `lake build` 与 ATP 自带测试。

脚本不会替你自动安装系统级包管理器依赖；如果基础命令不存在，它会直接提示缺少什么。

## 14. Runtime Output, Colors, and Simple ETA

ATP 现在支持一套独立于 ax-prover 内部源码的终端展示层，默认能力包括：

- 为 ax-prover 日志添加颜色。
- 在每个场景之间打印短分隔线，例如 `--T1-free------`。
- 运行开始时打印欢迎横幅。
- 每次真实模型请求前打印一条 INFO 风格请求日志。
- 在每个场景结束后打印：
  - 成功 / 失败状态
  - 已运行时间
  - 当前题目耗时
  - 剩余时间估计
- 将本次终端输出同步写入 `output_dir/terminal.log`，即使 `Ctrl+C` 中断也会保留已打印内容

相关开关位于 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml)：

```yaml
console:
  enable_color: true
  show_banner: true
  suppress_known_build_fallback_warning: true

runtime_status:
  enabled: true
  show_time: true
  history_file: ATP/artifacts/runtime_history.json
  default_seconds_per_formal_scenario: 180

execution:
  max_llm_requests_per_attempt: 0
```

其中 `runtime_history.json` 会持续记录正式题目的简单平均耗时，用于下一次运行开始时的初始 ETA。
如果 `max_llm_requests_per_attempt` 设置为正整数，欢迎横幅里也会显示当前采用的单次尝试请求上限。

## 15. About `unknown target` During Temporary Lean Checks

如果你曾在运行时看到类似：

```text
'lake build ATP.temTH.CandidateTheorems.T2.tmp_Disable_xxx' failed: unknown target.
Falling back to 'lake env lean ATP/temTH/CandidateTheorems/T2/tmp_Disable_xxx.lean'
```

这通常不是 Lean / mathlib 环境损坏。

根因是 ax-prover 会把 proposal 写入临时 Lean 文件，再优先尝试：

- `lake build <临时模块名>`

但这些临时模块本来就不是 Lake 里的正式 target，于是会得到 `unknown target`，随后 ax-prover 再自动回退到：

- `lake env lean <临时文件路径>`

ATP 现在默认会把这类已知噪声 warning 隐藏掉；如果你想保留它们，可以把：

```yaml
console:
  suppress_known_build_fallback_warning: false
```

改回 `false`。

## 16. Prompt Injection

当前 ATP 不再重写 ax-prover 的 prover prompt。  
现在的策略是：

- ax-prover 负责自己的 system prompt、结构化输出约束和工具调用协议；
- ATP 只把每个实验场景对应的 `prompt_seed` 作为 `prover.user_comments` 追加进去。

也就是说，ATP prompt 现在只是“附加提示”，不是“替换 prover prompt”。

详细说明见：

- [prompt-mechanism.md](/Users/hdm/math/elementary-number-theory/ATP/doc/prompt-mechanism.md)

## 17. Search Tools

LeanSearch 现在完全交给 ax-prover 的 `prover.proposer_tools` 管理。  
ATP 不再在 Python 里恢复 fallback 搜索工具，也不再接管 LeanSearch 的决策逻辑。

正式实验默认配置位于：

- [ax_prover_experiment.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/ax_prover_experiment.yaml)

当前默认仅保留：

```yaml
prover:
  proposer_tools:
    search_lean: ${tool_configs.search_lean}
```

其中 `search_lean.max_results` 当前已恢复为 ax-prover 官方默认值 `6`。

ATP 仍保留一层旁路归档，用于把 LeanSearch 的查询结果保存进 artifact，但这不会改变 ax-prover 的搜索行为。

## 18. Memory Config and Thin Wrapper Design

ATP 当前的设计目标是“尽量薄地包在 ax-prover 外面”。  
因此，像 `memory_config` 这类原本属于 prover 本体的默认项，现在也写回 YAML，而不再由 ATP Python 代码隐式补齐。

正式实验与 doctor 都显式声明：

```yaml
prover:
  memory_config:
    class_name: ExperienceProcessor
    init_args:
      llm_config: ${prover.prover_llm}
```

这样做的目的，是把运行语义尽量留在 ax-prover 配置层，而不是 ATP 包装层。

## 19. Recent T1 Findings

对 `T1.free` 的专项排查显示：

- LeanSearch 已经能够被触发，`20260411_214642` 中一共触发了 7 次；
- 主要瓶颈不是“完全不搜索”，而是“搜索结果采用失败”：
  - 有些 theorem 本地存在，但 import 不对；
  - 有些 theorem 本地存在，但对象类型与 `Character G := G →* ℂˣ` 不匹配；
  - 有些 theorem / module 名只在 LeanSearch 候选中出现，本地并不存在。

对应分析文档：

- [run-analysis-20260411_210627.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_210627.md)
- [run-analysis-20260411_214642.md](/Users/hdm/math/elementary-number-theory/ATP/doc/run-analysis-20260411_214642.md)
- [ax-prover-wrapper-audit-20260411.md](/Users/hdm/math/elementary-number-theory/ATP/doc/ax-prover-wrapper-audit-20260411.md)

## 20. How to Check Whether GPT-5.3 Codex Is Really Using Reasoning Mode

ATP 现在提供了一个专门的脚本：

- [check_reasoning_mode.py](/Users/hdm/math/elementary-number-theory/ATP/scripts/check_reasoning_mode.py)

它可以做两件事：

1. 只检查当前 experiment 配置实际传给 LangChain / OpenAI 的参数
2. 真实发起一次小请求，并和 `--compare-effort high` 做对照

示例：

```bash
source ~/ax-prover-env/bin/activate
python ATP/scripts/check_reasoning_mode.py
python ATP/scripts/check_reasoning_mode.py --live --compare-effort high
```

一次真实对照的样例报告已写到：

- [20260411_current_vs_high.json](/Users/hdm/math/elementary-number-theory/ATP/artifacts/reasoning_probe/20260411_current_vs_high.json)

在本地排查中，当前默认 profile 的关键现象是：

- `llm.reasoning = None`
- `llm.reasoning_effort = None`
- `_default_params` 中没有 `reasoning`
- live 调用的 `reasoning_tokens = 0`

而临时覆盖：

```yaml
provider_config:
  reasoning:
    effort: high
```

之后，live 调用出现了明显的：

- `reasoning_tokens > 0`
- 更长耗时

这说明如果你希望 `gpt-5.3-codex` 在 ATP 中显式进入高思考模式，当前最稳的做法是切到：

- `openai_reasoning_high`

而不是只保留当前默认 profile。

@article{axproverbase2026,
  title={A Minimal Agent for Automated Theorem Proving},
  author={Requena Pozo, Borja and Letson, Austin and Nowakowski, Krystian and Beltran Ferreiro, Izan and Sarra, Leopoldo},
  year={2026}
}

by OpenAI CODEX 5.4 
