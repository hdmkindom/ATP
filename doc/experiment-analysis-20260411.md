# 2026-04-11 实验排查报告

本文档汇总 2026-04-11 对 ATP / ax-prover 实验失败原因的专项排查结果，重点关注以下问题：

- 为什么 `T1.free` 在 6 轮内没有使用 LeanSearch。
- 为什么 `T1` 到 `T8` 的整体成功率显著低于 `T9` 和 `T10`。
- 目前失败更像是 prompt / agent 问题，还是本地 Lean / Lake 环境问题。

## 1. 关键结论

### 1.1 `T1.free` 当前版本中确实没有调用 LeanSearch

对当前代码重新运行：

```bash
python ATP/scripts/atp_axbench.py run T1.free --skip-prebuild
```

得到的新归档目录：

- `ATP/artifacts/runs/20260411_164125/scenarios/T1_free/attempt_01`

其中：

- `messages.json` 显示 6 轮 proposal 全部都是“猜 lemma 名”或手写证明，不含任何搜索结果。
- `leansearch/index.json` 显示：

```json
{
  "search_count": 0,
  "records": []
}
```

这说明这次不是“搜了但没保存”，而是 proposer 在 6 轮内一次 LeanSearch 都没有调用。

### 1.2 `search_lean` 已经真实挂载到 ax-prover agent 中

排查 ATP 配置合并和 ax-prover agent 初始化后，确认：

- `build_ax_config(...)` 生成的 `prover.proposer_tools` 中包含 `search_lean`
- `ProverAgent.create(...)` 创建出的 `proposer_tools` 实例列表中也包含 `search_lean_search_tool`

因此，当前问题不是“LeanSearch 没配置进去”，而是“工具可用，但模型没有选择调用它”。

### 1.3 `T2` 到 `T8` 的大量失败首先是环境 / 构建问题

当前环境下直接检查模板文件可编译性：

```bash
lake env lean ATP/temTH/CandidateTheorems/T1/Free.lean
lake env lean ATP/temTH/CandidateTheorems/T2/Free.lean
...
lake env lean ATP/temTH/CandidateTheorems/T10/Free.lean
```

结果如下：

| 题目 | 当前模板可否进入 theorem 证明阶段 | 首个错误 |
|---|---|---|
| T1 | 可以 | 只有 `sorry` warning |
| T2 | 不可以 | `CandidateTheorems.T2.Support.olean` 不存在 |
| T3 | 不可以 | `CandidateTheorems.T3.PrimitiveRoot.olean` 不存在 |
| T4 | 不可以 | `CandidateTheorems.T3.PrimitiveRoot.olean` 不存在 |
| T5 | 不可以 | `CandidateTheorems.T3.PrimitiveRoot.olean` 不存在 |
| T6 | 不可以 | `CandidateTheorems.T6.Support.olean` 不存在 |
| T7 | 不可以 | `CandidateTheorems.T3.PrimitiveRoot.olean` 不存在 |
| T8 | 不可以 | `CandidateTheorems.T8.Support.olean` 不存在 |
| T9 | 可以 | 只有 `sorry` warning |
| T10 | 可以 | 只有 `sorry` warning |

这意味着在当前环境里：

- `T1 / T9 / T10` 至少能真正进入“模型生成 proof -> Lean build -> 继续迭代”的流程。
- `T2` 到 `T8` 的模板从一开始就缺少依赖模块的 `.olean`，因此实验结果会被环境问题严重污染。

### 1.4 `T9` 和 `T10` 容易成功，不只是因为题目简单，也因为它们不依赖缺失模块

`ATP/temTH/CandidateTheorems/T9/Free.lean` 与 `ATP/temTH/CandidateTheorems/T10/Free.lean` 只依赖基础 `Mathlib` 模块，不依赖 `CandidateTheorems.T*.Support` 或 `PrimitiveRoot`。

这与它们在多轮实验中高成功率的现象一致。

## 2. 历史整轮实验统计

本次汇总的整轮实验目录如下：

- `ATP/artifacts/runs/20260405_231320`
- `ATP/artifacts/runs/20260405_234554`
- `ATP/artifacts/runs/20260406_095756`
- `ATP/artifacts/runs/20260406_113408`

这四轮都是“10 题 * 4 模式”的完整或近完整实验。

### 2.1 按题目汇总的总成功率

| 题目 | 成功 / 总尝试 |
|---|---|
| T1 | 0 / 16 |
| T2 | 1 / 16 |
| T3 | 1 / 16 |
| T4 | 0 / 16 |
| T5 | 0 / 16 |
| T6 | 0 / 16 |
| T7 | 0 / 16 |
| T8 | 0 / 16 |
| T9 | 15 / 16 |
| T10 | 15 / 16 |

### 2.2 按题目汇总的平均运行成本

| 题目 | 平均迭代轮次 | 平均请求数 | 平均 tokens |
|---|---:|---:|---:|
| T1 | 7.75 | 18.88 | 91,230.31 |
| T2 | 6.56 | 18.00 | 79,997.69 |
| T3 | 7.31 | 19.38 | 100,077.00 |
| T4 | 7.75 | 22.12 | 115,927.06 |
| T5 | 7.75 | 21.88 | 127,051.19 |
| T6 | 7.75 | 22.25 | 101,189.31 |
| T7 | 7.75 | 22.00 | 134,135.06 |
| T8 | 7.75 | 22.38 | 115,593.25 |
| T9 | 1.25 | 1.88 | 2,793.31 |
| T10 | 1.62 | 2.44 | 3,866.69 |

这里要注意：

- `T2` 到 `T8` 的平均迭代轮次偏低，并不代表它们更容易，而是大量早停来自依赖模块问题。
- `T9` 和 `T10` 的请求数与 tokens 都非常低，说明它们基本是“短链路直接证明”。

## 3. 当前最重要的两个根因

## 3.1 根因 A：Lake / CandidateTheorems 源码目录映射存在结构性问题

`lakefile.lean` 中定义了：

```lean
lean_lib «AtpSummary» where
  srcDir := "AtpSummary"
  roots := #[
    `CandidateTheorems,
    ...
  ]
```

但真实源码位于仓库根目录：

- `CandidateTheorems/T2/Support.lean`
- `CandidateTheorems/T3/PrimitiveRoot.lean`
- `CandidateTheorems/T6/Support.lean`
- ...

而不是：

- `AtpSummary/CandidateTheorems/...`

因此当前直接执行：

```bash
lake build CandidateTheorems.T2.Support
```

会报：

```text
file: /.../AtpSummary/CandidateTheorems/T2/Support.lean
no such file or directory
```

这说明：

- Lake 现在是按照 `AtpSummary/CandidateTheorems/...` 去找模块源码
- 但真实文件不在那个目录下
- 所以 `T2` 到 `T8` 的依赖 `.olean` 很难被正常构建出来

这不是模型问题，而是当前项目构建配置与源码布局不一致的问题。

## 3.2 根因 B：`T1.free` 的默认 free 模式下，模型确实在“猜 lemma 名”，而不是搜索

当前 `T1.free` 新运行的 6 轮中，提案依次尝试了：

- `Character.sum_eq_zero_of_ne_one`
- 手写有限和重排证明
- `χ.sum_eq_zero_of_ne_one`
- `Character.sum_coe_eq_zero_of_ne_one`
- `Character.sum_eq_zero_of_ne_one`

每次失败后都会进入下一轮，但没有任何 LeanSearch 调用记录。

同时检查 ax-prover 默认 `PROPOSER_SYSTEM_PROMPT` 可见：

- iterative prompt 强调“利用 build feedback 和 experience”
- 但并没有像 single-shot prompt 那样显式提醒“你可以使用工具”

在 ATP 当前的 free 模式下，我们又按要求不额外注入任何 prompt，因此结果就是：

- 工具是可用的
- 但默认 prompt 对工具使用的引导很弱
- `gpt-5.3-codex` 在这道题上更倾向于直接猜一个看起来合理的 theorem 名

## 4. 对“记忆是否坏了”的判断

就 `T1.free` 这类运行而言，当前证据更支持：

- memory 不是“完全失效”
- 但 memory 是软性的自然语言总结，不是“硬规则禁用器”

也就是说：

- 上一轮如果因为 `unknown identifier` 失败
- 下一轮理论上会看到这条失败信息
- 但模型仍然可能继续押注一个相近的、同样不存在的名字

所以当前现象更像：

- 工具不被主动使用
- memory 只能弱提醒，不能硬拦截
- 因此会出现“重复猜错 theorem 名”的局面

## 5. 现阶段最稳妥的解释框架

综合当前排查，前八题失败不能简单归因于单一因素，而更像是两层问题叠加：

1. `T2` 到 `T8`：首先被环境 / 构建问题污染  
   它们依赖的 `Support` / `PrimitiveRoot` 模块在当前 Lake 布局下无法正常产出 `.olean`。

2. `T1`：能够进入真实迭代，但 free 模式下 proposer 没有主动用 LeanSearch  
   于是进入“猜 theorem 名 -> build 报 unknown identifier -> 继续猜”的循环。

3. `T9` 和 `T10`：不依赖缺失模块，且题目本身较短，因此明显更稳定。

## 6. 已经完成的增强

为便于继续排查，ATP 现在已经支持 LeanSearch 归档：

- 每次搜索会写入 `attempt_dir/leansearch/`
- 包含 `.json`、`.txt` 以及 `index.json`

因此从 2026-04-11 之后的新实验开始，可以直接区分三种情况：

- 没有搜索
- 搜索了，但结果没被采用
- 搜索失败或返回结果质量差

## 7. 建议的后续排查顺序

建议下一步按这个顺序继续推进：

1. 先修复 `CandidateTheorems` 的 Lake 源码映射问题  
   在这个问题没修好前，`T2` 到 `T8` 的实验结果不能作为模型能力结论。

2. 在修复构建问题之前，只拿 `T1.free` 做 agent 行为研究  
   因为它当前至少能真正进入 proof loop。

3. 对 `T1.free` 做两组对照实验  
   一组使用完全默认 free 模式，一组仅加一句“当 lemma 名不确定时先使用 LeanSearch”，比较 `search_count` 是否变化。

4. 如果需要更强控制，再考虑实现“unknown lemma 名称黑名单”  
   这属于 ATP 的增强项，不是 ax-prover 默认行为。
