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

by OpenAI CODEX 5.4 
