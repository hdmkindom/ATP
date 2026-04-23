# ATP Architecture

## 1. Architectural Goal

本框架的目标不是只“调用一次 ax-prover”，而是建立一层稳定的实验基础设施，用于长期支撑以下工作：

- 统一管理 `test` 与正式候选定理场景
- 在多种提示模式下重复运行同一 prover
- 记录完整归档，而不污染原始模板
- 支持后续统计、路线分析、失败分析与论文整理
- 尽量把新增题目、路线与模式的成本压缩到 YAML 配置层

## 2. Layering Strategy

### 2.1 Catalog Layer

职责：

- 维护 `test` 场景与候选定理目录
- 兼容旧版四模式自动派生
- 正式候选题固定使用 `free_instruction / disable_instruction / route_a / route_b` 四种 prompt 入口
- 统一处理用户传入的选择器

对应文件：

- `config/theorem_catalog.yaml`
- `src/atp_axbench/catalog.py`

### 2.2 Prompt Layer

职责：

- 把场景信息渲染成 ax-prover 的 `prover.user_comments`
- 不改写 ax-prover 的原生 system prompt
- 尽量把实验差异收敛到 theorem catalog 的文本配置层

对应文件：

- `src/atp_axbench/prompts.py`

### 2.3 Execution Layer

职责：

- 加载并合并 ax-prover 配置
- 清理空的 provider 参数，使 `base_url: null` 回退到默认端点
- 预构建 Lean 仓库
- 运行单个或批量 proving 任务
- 在运行期间保存每轮 proposal 对应的完整 Lean 快照
- 在结束后恢复模板文件

对应文件：

- `src/atp_axbench/runner.py`
- `src/atp_axbench/doctor.py`
- `src/atp_axbench/iteration_archive.py`

### 2.4 Interface and Reporting Layer

职责：

- 提供命令行入口
- 将结果写成 JSON、Markdown 与源文件快照
- 为后续统计或论文整理提供稳定归档格式

对应文件：

- `scripts/atp_axbench.py`
- `src/atp_axbench/cli.py`
- `src/atp_axbench/reporting.py`

## 3. Directory Tree

```text
ATP/
├── README.md -- 项目总览、部署方式与使用入口
├── artifacts/ -- 运行输出根目录
├── config/ -- YAML 配置目录
│   ├── ax_prover_doctor.yaml -- doctor 阶段的 ax-prover 配置
│   ├── ax_prover_experiment.yaml -- 正式实验的 ax-prover 配置
│   ├── ax_prover_profiles.yaml -- 共享 LLM provider/model/base_url 档案
│   ├── project.yaml -- ATP 项目级执行配置
│   └── theorem_catalog.yaml -- 题目、路线与场景元数据
├── doc/ -- 技术文档目录
│   ├── architecture.md -- 本文档
│   ├── command-wiki.md -- CLI 命令与参数详解
│   ├── configuration-wiki.md -- 配置链路与扩展说明
│   └── engineering-notes.md -- 工程问题与风险记录
├── promot.md -- 任务说明原文
├── scripts/ -- 命令行入口脚本
│   ├── atp_axbench.py -- ATP CLI 入口
│   └── install_atp.sh -- Linux / macOS 自动安装脚本
├── src/ -- 代码实现目录
│   └── atp_axbench/
│       ├── __init__.py -- 包版本定义
│       ├── __main__.py -- 模块执行入口
│       ├── catalog.py -- 场景目录与选择器逻辑
│       ├── cli.py -- CLI 参数解析与命令分发
│       ├── console.py -- 终端颜色、日志过滤与状态打印
│       ├── doctor.py -- 环境与 smoke 检查
│       ├── iteration_archive.py -- 每轮 proposal 文件归档
│       ├── leansearch_trace.py -- LeanSearch 归档
│       ├── models.py -- 数据模型定义
│       ├── paths.py -- 路径常量
│       ├── prompts.py -- 模式提示渲染
│       ├── reporting.py -- JSON / Markdown / 快照输出
│       ├── reasoning_probe.py -- reasoning 模式诊断
│       ├── runner.py -- ax-prover 调用与运行主逻辑
│       ├── runtime_monitor.py -- 简单 ETA 与运行时间预测
│       └── settings.py -- 项目级 YAML 配置加载
├── temTH/ -- Lean 模板文件目录
└── tests/ -- ATP 自测目录
    ├── conftest.py -- 测试导入路径初始化
    ├── run_tests.py -- 零依赖测试执行器
    ├── test_catalog.py -- 场景目录测试
    ├── test_direct_prove.py -- 单题直连脚本测试
    ├── test_leansearch_trace.py -- LeanSearch 归档测试
    ├── test_prompts.py -- 提示渲染测试
    ├── test_reasoning_probe.py -- reasoning 诊断测试
    ├── test_reporting.py -- 汇总输出测试
    ├── test_runner.py -- 运行主逻辑测试
    ├── test_runtime_monitor.py -- 简单 ETA 测试
    └── test_settings.py -- 项目配置解析测试
```

## 4. Key Design Decisions

### 4.1 Python API Instead of CLI Chaining

框架直接调用 ax-prover 的 Python API，而不是只拼 shell 命令。这样可以直接拿到：

- prover summary
- metrics
- message trace
- proposal 对象

从而为归档、路线分析和错误诊断提供更稳定的数据源。

### 4.2 Shared LLM Profiles

`doctor` 与正式实验现在默认共用一份 LLM 档案：

- 避免接口配置漂移
- 让 `doctor` 的结论更接近正式运行
- 保留单独覆盖 `doctor_profile` 或 `experiment_profile` 的能力

### 4.3 In-Place Execution with Snapshot Archiving

当前版本选择“原地运行 + 快照归档 + finally 恢复”，而不是物理移动模板文件。

原因：

- 保持 Lean 模块路径稳定
- 避免 `lake build` 与 `import` 分辨率受路径迁移影响
- 简化异常恢复逻辑

### 4.4 Iteration Preservation

ax-prover 在 builder 阶段会创建临时文件并在退出时删除。ATP 额外做了一层 proposal 归档：

- proposer 每生成一轮 proposal，立刻根据 proposal 重建完整 Lean 文件
- 归档文件命名采用“月日时分 + 轮次编号”
- 运行结束后再用最终状态补全反馈信息

因此，即使最终证明失败，也可以保留每一轮的完整文件。

## 5. Extensibility Boundary

当前扩展策略分成两层：

- 若只是新增题目、路线或场景，优先改 `theorem_catalog.yaml`
- 若只是切换 provider / model / base_url，优先改 `ax_prover_profiles.yaml`

只有在以下情况下一般才需要改 Python 代码：

- 新增新的 doctor 检查项
- 变更归档格式
- 引入新的场景选择语义

## 6. Current Limitations

当前实现仍有边界需要注意：

- 如果外部模型在第一轮 proposal 之前就失败，则不会生成迭代快照
- 默认运行仍依赖原始仓库，而不是隔离副本工作区
- 当前正式候选题不再支持在 YAML 中注册额外 prompt 场景；题目级 prompt 入口固定为 `free_instruction / disable_instruction / route_a / route_b`

这些边界不影响当前框架使用，但需要在更大规模实验中继续观察。
