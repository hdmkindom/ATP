# ATP Command Wiki

## 1. Overview

`ATP/scripts/atp_axbench.py` 提供三个一级命令：

- `list`：查看已注册场景。
- `doctor`：检查环境、接口和冒烟证明。
- `run`：运行一个或多个正式场景或测试场景。

建议先激活 Python 环境：

```bash
source ~/ax-prover-env/bin/activate
```

## 2. `list`

### 2.1 Usage

```bash
python ATP/scripts/atp_axbench.py list [--only all|candidates|test]
```

### 2.2 Parameters

- `--only all`
  默认值。列出全部场景，包括 `test.*` 与 `T1...T10`。
- `--only candidates`
  只列出正式候选题。
- `--only test`
  只列出测试场景。

### 2.3 Examples

```bash
python ATP/scripts/atp_axbench.py list
python ATP/scripts/atp_axbench.py list --only candidates
python ATP/scripts/atp_axbench.py list --only test
```

## 3. `doctor`

### 3.1 Usage

```bash
python ATP/scripts/atp_axbench.py doctor [options]
```

### 3.2 Parameters

- `--output-dir PATH`
  指定 doctor 归档目录。默认写到 `ATP/artifacts/doctor/<timestamp>/`。
- `--skip-llm-ping`
  跳过真实模型联通性测试，只做本地环境和配置检查。
- `--skip-proof`
  跳过 `test.smoke` 的真实 proving 测试。
- `--ax-config PATH`
  追加 ax-prover YAML overlay。可重复传入，后传的覆盖前传的。

### 3.3 Checks

`doctor` 默认依次执行：

- `ax_prover_import`
- `llm_credentials`
- `llm_base_url`
- `lean_repo_build`
- `template_smoke_file`
- `llm_ping`
- `smoke_proof`

### 3.4 Examples

```bash
python ATP/scripts/atp_axbench.py doctor
python ATP/scripts/atp_axbench.py doctor --skip-llm-ping --skip-proof
python ATP/scripts/atp_axbench.py doctor --ax-config ATP/config/ax_prover_experiment.yaml
```

### 3.5 Exit Code

- `0`：全部检查没有 `error`
- `1`：至少一项检查失败

## 4. `run`

### 4.1 Usage

```bash
python ATP/scripts/atp_axbench.py run [selectors ...] [options]
```

### 4.2 Selectors

`selectors` 可以混用，框架会去重并按标准顺序执行：

- `test`
  运行所有测试场景。
- `test.smoke`
  只运行冒烟测试。
- `T1`
  运行该题目下注册的全部场景。
- `T1.free`
  运行某一个精确场景。
- `candidates`
  运行全部正式候选题。
- `all` 或 `*`
  运行全部场景。

如果不传 selector，默认等价于 `run test`。

### 4.3 Parameters

- `--repeats N`
  每个场景重复运行 `N` 次。
- `--output-dir PATH`
  指定本次实验归档目录。默认写到 `ATP/artifacts/runs/<timestamp>/`。
- `--persist`
  成功时保留模板文件中的证明改动，不在 `finally` 中恢复。
- `--skip-prebuild`
  跳过批量运行前的 `lake exe cache get` 和 `lake build`。
- `--ax-config PATH`
  追加 ax-prover YAML overlay。可重复传入，后传的覆盖前传的。

### 4.4 Examples

```bash
python ATP/scripts/atp_axbench.py run test
python ATP/scripts/atp_axbench.py run T1
python ATP/scripts/atp_axbench.py run T1.free --repeats 2
python ATP/scripts/atp_axbench.py run candidates --skip-prebuild
python ATP/scripts/atp_axbench.py run T3 --ax-config ATP/config/ax_prover_doctor.yaml
```

### 4.5 Exit Code

- `0`：所有场景都 `valid=true`
- `1`：任一场景失败或不合规

## 5. Output Layout

`run` 和 `doctor` 都会落盘结构化归档。`run` 典型内容包括：

- `summary.md`：本批次 Markdown 汇总
- `summary.json`：本批次 JSON 汇总
- `<scenario>/attempt_01/result.json`：单场景结果
- `<scenario>/attempt_01/source/*.lean`：原始、结束、恢复快照
- `<scenario>/attempt_01/iterations/*.lean`：每轮 proposal 重建文件
- `<scenario>/attempt_01/messages.json`：ax-prover 消息流

如果 `project.yaml` 中启用了：

```yaml
execution:
  persist_last_attempt_on_failure: true
```

那么当场景失败或达到最大轮次后，模板文件本体也会保留最后一次失败尝试的内容，而不是恢复回原始模板。

如果还设置了：

```yaml
execution:
  max_llm_requests_per_attempt: 12
```

那么 ATP 会在单次场景尝试内监控真实模型请求次数；一旦即将超过该上限，就中断当前尝试，同时仍然保留：

- `result.json`
- 快照归档
- `terminal.log`

## 6. Overlay Merge Rule

命令行中的 `--ax-config` 会按“后者覆盖前者”的顺序叠加到默认配置之后。实际顺序如下：

1. ax-prover 内置 `Config()`
2. ATP 默认 YAML
3. 命令行 `--ax-config` 传入的 overlay
4. ATP 运行时注入的 `prover.user_comments`

## 7. Suggested Workflow

建议按下面顺序使用：

1. `list` 确认场景已注册。
2. `doctor --skip-proof` 先检查环境和接口。
3. `doctor` 做一次完整冒烟。
4. `run test` 验证归档链路。
5. `run T1` 或 `run candidates` 开始正式实验。

## 8. Runtime Banner and Status Lines

当 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml) 中启用了：

```yaml
console:
  show_banner: true

runtime_status:
  enabled: true
```

`run` 命令启动后会先打印欢迎横幅，内容包括：

- 当前模型
- 最大证明轮次
- 运行轮数
- 正式场景数量与测试场景数量
- 本次运行预估时间

随后在每个场景结束时，会打印两类状态：

- 结果行：`✓` 或 `X`
- 时间行：已运行、当前题目耗时、剩余时间

如果配置了 `execution.max_llm_requests_per_attempt`，欢迎横幅中还会显示当前的“单次尝试模型请求上限”。

## 9. Output Colors

当前终端输出采用以下颜色约定：

- `INFO`：蓝色
- `DEBUG`：绿色
- `WARNING`：黄色
- `ERROR`：红色
- 运行状态行：浅蓝色

如果你不想在终端看到 ANSI 颜色，可以在 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml) 中关闭：

```yaml
console:
  enable_color: false
```

## 10. Known Build Fallback Warning

如果你曾经在旧版本输出中看到：

```text
'lake build ATP.temTH....tmp_xxx' failed: unknown target. Falling back to 'lake env lean ...'
```

这通常不是环境损坏，而是 ax-prover 检查临时文件时的正常回退路径。

现在 ATP 默认会隐藏这类已知噪声 warning。若你希望重新显示，可在 [project.yaml](/Users/hdm/math/elementary-number-theory/ATP/config/project.yaml) 中设置：

```yaml
console:
  suppress_known_build_fallback_warning: false
```
