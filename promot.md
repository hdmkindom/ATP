# 项目背景

elementary-number-theory 是项目总目录，包括
1. andidateTheorems -- 10道问题以及其解法
2. MathmaticInElementaryNumberTh -- 初等数论的简单证明
3. Tonelli_Shanks -- 另外一篇论文
4. ATP -- 你的主要关注对象，也就是本次项目
（在 ATP 中，现仅有 temTH ，是 十道问题的模版证明文件）

以及整个项目共享的 Lean Mathlib 环境

也就是说，你应当忽略 上述 1. 2. 3. ，因为他们是毫不相关的其他环境，并主要关注 4.

# 目标

完成一个 基于 ax-prover 的 ai 
关于十道问题，让同一个ai进行证明。

## 核心研究问题

给定一组与 character sums / exponential sums 的小定理。
对每一个定理，构造至少两条“本质不同”的证明路线，并比较一个 minimal agent 在下列三类模式中的表现：

    1. 自由模式
    2. 禁用模式
    3. 引导模式

研究以下现象：
    1. agent 更偏好哪种路线；
    2. 哪种路线更容易成功；
    3. 哪种路线更容易在 Lean 表达层失败；
    4. 当某条捷径被禁用后，agent 是否具备切换路线的能力。

## 相关定义：

我们称两种证明是“本质不同”的， 如果
证明所依赖的关键中间对象或关键引理族不同

自由模式指：不给 agent 指定证明路线，也不额外禁用主要引理，让它自己选择最自然的证明路径。

禁用模式指：人为禁止某条关键路线，例如不允许直接调用某个正交关系定理，或者不允许引用某个现成 Fourier 结论，从而逼迫 agent 尝试另一条路线。

引导模式指：在任务说明中明确要求 agent 使用某个中间对象、某个中间引理或某个特定思路。例如，“请通过 Fourier 观点证明”或者“请不要直接使用正交关系主定理”

## 细节

1. temTH 有两类，分别为 test 与 正式项目（也就是 CandidateTheorems），你应该考虑到测试的情况
2. CandidateTheorems 每个题目有四个文件，对应禁用模式，自由模式，以及两种引导模式
3. doc 内部应当是项目的技术文档
4. config 内部应当是参数调节，使用yaml
5. 考虑详细的完整的变量命名
6. 也许你的记忆或者项目构建记录中有类似的经验，比如  ATPSUMMARY 但是绝对不要拿来使用，那是失败的项目。我希望你可以从零造轮子，不必借鉴其他的构建记录之类的
7. ax-prover 所在的虚拟环境是 ax-prover-env ，位于 ~ 目录下。你可以直接拿来使用


# 要求 -- 你的工作

1. 设计一个详细的架构，既能满足项目目标，又有相当的可拓展性，以及可读性，可以给我一个 tree 来展示这部分工作
2. 调用 ax-prover 进行与ai相关的工作
3. 考虑项目的分层设计，我目前考虑的，交互层（脚本以及可执行文件），逻辑层（具体的实现逻辑，关于三种模式的调整等），执行层（调用ax-prover进行的工作）。鼓励你推翻我的分层设计，并选用更合理的设计
4. 充分考虑测试的情况，我目前考虑的测试至少应当包括：测试 api，base_url正常与否，测试 ax-prover 正常与否，能否正确证明test，测试逻辑正常与否与
5. 完成三种模式的代码部分，并充分考虑各种意外情况。
6. 考虑模型运行轮次，并设置上限
7. 充分阅读 promot.md 
8. 最终与ax-prover接口的部分可以考虑 在终端上 的操作，比如调用ax-prover的某些指令。但是鼓励你采用更优越的方式


## 意外

1. LangSmith 考虑以下命令，如果有更好的办法，你可以尝试
unset LANGSMITH_API_KEY LANGCHAIN_API_KEY      
export LANGSMITH_TRACING_V2=false
export LANGCHAIN_TRACING_V2=false

2. 保存每一次每一轮的运行文件，ax-prover会在每一轮测试失败的时候自动删除文件，我希望保存他们，并编号。按月日时分命名排序

3. 是否应该考虑每一次运行的时候，将文件从temTH中移动到运行目录，运行完成或失败或意外中断之后，将文件移动至日志文件内

4. 为 yaml 中每个参数设置中文注释 ，采用 xx #解释内容

5. READme 书写风格更换为专业文档，而非用ai的语气

6. 架构树 用 -- 在后面指示该文件是什么

7. 为每个函数添加注释，方式为参考

'''
函数run_doctor 运行环境、配置和冒烟测试检查。它接受项目设置、场景目录、ax 配置路径、输出目录以及两个可选参数来跳过 LLM ping 和冒烟测试。函数执行一系列检查，并将结果记录在 DoctorReport 中，最后将报告写入指定的输出目录。
输入：
  - settings: ProjectSettings -- 解释参数
  - catalog: ScenarioCatalog
  - ax_config_paths: tuple[str, ...]
  - output_dir: Path
  - skip_llm_ping: bool
  - skip_proof: bool
输出：
  - DoctorReport -- 解释输出
'''
def xxx

8. 你在项目建设或者处理途中遇到的有趣的问题或者疑惑或者难点或者可能bug或者各种意外，都可以放到doc中一个md里面

## 第三轮问题

1. 你在哪里读取到的 ax-prover 的 base_url ，通过什么样的方式进行修改的。可否修改为，在yaml中直接修改供应商 api base_url 模型等，而不是用外部 ax-prover。
2. 查阅资料，告诉我ax-prover支持那些模型
3. 修改README，添加部署部分：如何在一个空设备下完成部署，WIN LINUX MACOS
4. 关于接口方面，考虑其他模型供应商如claude GEMINI等的接口，是否应当是如果留空，就使用默认
5. 你在项目建设或者处理途中遇到的有趣的问题或者疑惑或者难点或者可能bug或者各种意外，都可以放到doc中一个md里面
6. 是否应当考虑 doctor与正式实验等 共用一个 api base_url model 接口
7. 我发现目前doctor每次运行的时候，貌似都显示 cache get failed with code 1 报错，请检查怎么回事，是否是我外部 lean 或 mathlib 环境出了问题，你先不要急着修改
8. 目前 llm_ping 貌似不通，我使用 llm_ping: AttributeError: 'str' object has no attribute 'model_dump'
9. 目前 python ATP/scripts/atp_axbench.py run test 不通，怀疑是否与 7. 或 8. 有关
10. doc 中应该有关于命令参数的详细介绍，尽可能做成 wiki 的形式
11. 目前仅仅有三种模式，四轮实验，十个题目。我们未来可能会增加。一定要有更大的可拓展性。比如未来某个问题可能会有四五种甚至更多的路线，模式也可能有更多，这个是否仅仅需要修改 promot yaml 

## 第四轮问题

1. 请将 api 的修改也放在 yaml配置文件里面，可以和baseurl放在一起，我不想在程序外部修改它
2. 目前我设置的 baseurl为 https://codeflow.asia/v1/chat/completions ，但是为什么 doctor报的错中显示 llm_ping: RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/chat/completions/responses)', 'type': 'invalid_request_error', 'param': '', 'code': ''}} 其中 POST /v1/chat/completions/responses ，最后的 /responses 我没有使用，是在什么时候被拼接上去的吗？我在中转网站上看到 gpt-5.2-codex 模型支持的信息为：openai：
/v1/chat/completions ，所以应该不会出错呀？
3. 告诉我你修改完baseurl之后，ax-prover都是怎么读取他的
4. 你在项目建设或者处理途中遇到的有趣的问题或者疑惑或者难点或者可能bug或者各种意外，都可以放到doc中一个md里面，但是没有必要全部删除再重新写，直接在后面添加上即可，README等md文件也是如此

## 第五轮对话

参考 question.tex 中的题目 promot ，修改配置文件中，关于十道题目的 promot

要求：
1. 使用中文，最好使用原文
2. 关于自由模式，最好是默认，让ax-prover去考虑。如果留空会怎么样
3. 关于禁用模式，默认禁用掉路线A的方式。请不要直接说禁用掉路线A，应当是将 promot中关于路线A的表述复制并修改。不要在禁用模式 promot中出现 路线A 等类似的表述
4. 关于引导模式的两个路线，使用原文

## 第六轮对话

1. 关于ai的最大调试轮次如何调控，在生成最大多少次没有成功时，ai自动放弃该问题，并将最终一次的回答作为最终回答
2. 如果我讲temTH文件中所有的 import 都去掉，会不会影响ax-prover。如果不会，就请都去掉

## 第七轮对话

1. 当我运行 python ATP/scripts/atp_axbench.py run all --skip-prebuild 时候

出现大量报错夹杂在问题之间：
PydanticSerializationUnexpectedValue(PydanticSerializationUnexpectedValue: Expected `none` - serialized value may not be as expected [field_name='parsed', input_value=ProverResult(imports=[], ...t := root) (a := a) ha'), input_type=ProverResult]
PydanticSerializationUnexpectedValue: Expected `ResponseOutputRefusal` - serialized value may not be as expected [field_name='content', input_value=ParsedResponseOutputText[... := root) (a := a) ha')), input_type=ParsedResponseOutputText[~TextFormatT]])
  PydanticSerializationUnexpectedValue(Expected `ParsedResponseFunctionToolCall` - serialized value may not be as expected [field_name='output', input_value=ParsedResponseOutputMessa...', phase='final_answer'), input_type=ParsedResponseOutputMessage[~TextFormatT]])

请告诉我怎么回事，并分析有何解决办法？
如果可以屏蔽掉，并将两个问题之间打上类似 -T1-free-------- 符号作为分割。格式为 -- 中夹着 T1-free 等题目标号，且标号在第一个-之后，避免太长而串行。

2. 我在运行的时候发现下述问题：
貌似所有的都仅仅运行了一遍，这期间有成功的有失败的。但是我的yaml设置的是最大3轮次。为什么会自动停止

## 第八轮对话

1. 我在运行的时候发现了一些问题：
貌似会一直出现 
2026-04-05 23:53:55 - WARNING - [build.py:306 - check_lean_file()] - 'lake build ATP.temTH.CandidateTheorems.T2.tmp_Disable_jwlsm42c' failed: unknown target. Falling back to 'lake env lean ATP/temTH/CandidateTheorems/T2/tmp_Disable_jwlsm42c.lean' 
一个报错，这是否是我环境配置的问题

2. 重整输出规范：
  1. 目前你的每一个输出都有 时间 INFO等标志，这是不错的。但是目前的输出太多，太杂乱。考略讲其中部分输出归类为DEBUG模式下
  2. 如果这些输出都是ax-prover做的输出，不好修改的话，可以先不修改。我不希望改变ax-prover内部的文件
  3. 为终端增加颜色：打印时带上颜色标记，让每个输出都有颜色。
    具体为：

    INFO = "\033[34m"      # 蓝色
    DEBUG = "\033[32m"     # 绿色
    WARNING = "\033[33m"   # 黄色
    ERROR = "\033[31m"     # 红色
    RESET = "\033[0m"      # 重置颜色

  4. 我希望可以预估每次运行的时间，该时间动态改变。可以考虑时间为证明前面所有问题的时间和取均值乘所有问题。并将第一次运行的预估时间，放进yaml中作为参数。仅仅考虑正式的问题，不考虑测试的时间。鼓励你采用更先进的时间估计方法。并将已运行的时间以及该题目花费的时间以及孩生育的时间，在每个题目的一个小阶段结束之后单独打印出来，颜色可以采用浅蓝色，与INFO标志分开。
  5. 考虑运行请求的次数以及消耗的tokens。分为目前已运行消耗的总tokens，以及单题消耗的tokens，以及单题该小阶段花费的tokens。并打印出来，颜色用 紫色
  6. 时间与tokens，请求次数等是表示运行状态，应当设置单独启用并写入配置文件

  7. 在每次输入指令开始运行之后，打印一个欢迎使用，类似于：

  ----------------------
  欢迎使用 ax-prover—ATP
  本次使用的模型：
  最大重试次数：
  运行轮数：

  预估需要最大请求次数：
  本次运行预估所需时间：
  
  作者：刘泽博
  -----------------------

  预估的时间请单独计算，我目前的想法是：每次运行完之后，都记录总共的时间，以及题目的数量，并做一些均值等处理，下次运行的时候就显示出来。
  第一次运行的时候，如果时间没有，或者出不来的话，考虑给一个默认值

  请求次数的计算应当是：按照题目的数量，一共需要最大的运行次数。比如以俄共10个题目，共有三个模式，四次测试，最大重试5次，则总共请求次数应当是：10*4*5=200 

  8. 每一次运行失败之后都应当用 ERROR 打印出来并在前面打一个X。如果成功了就用 INFO 打印出来，并在前面有一个 对号

3. 遇到的问题或者隐藏的bug还是和以前一样写进doc，但是不建议重新生成或完全删除某个文件，应当在其基础上进行修改

4. 请写一个自动安装的脚本，考虑用 shell ，这样可以方便linux与macos用户.

5. 代码规范参照以前的 promot 

## 第九轮

我简单看了一下实验的结果。发现成功率并不高。但是我是用的模型是 5.3-codx。这应当是很强的模型了，但是大部分题目，仍然在重试6次之后是错误的。而且我观察发现，每一次的运行结果都和前一次有很大出入。这是否意味着 a-prover 的记忆机制坏了。我记得你在之前的工作中修改过与记忆相关的部分。那一次是修改了什么，为什么修改。目前应该怎么做。

## 第十轮

有几个问题：
1. 第一个是我看到在 你测试的过程中 出现了很多次这个错误： “AttributeError: 'NoneType' object has no attribute 'ainvoke' ” 我想知道这个是为什么呢？模型外部接口出现了错误吗？ 还是说 axprover无法正确（语法层面）去解析 type类型？

可以看到 
"T3.free"

#记录

v1.CmQKHHN0YXRpY2tleS1lMDBmdHBxbTc2c3ZiY3d0em4SIXNlcnZpY2VhY2NvdW50LWUwMHFqZ2FlNnNtN3EwMWhrMDIMCPjKv84GEOnNqoQDOgwI-M3XmQcQgN-hnwFAAloDZTAw.AAAAAAAAAAGZ52MgzB9tGrlCFY_dHpm2DPOefIfKUuGBqHcjFwcFkpOq9yak4t1g3j4oWO9t4SmUfKkYMO8g2S8Ga-wmf0wP

import os
from openai import OpenAI

client = OpenAI(
    base_url="https://api.tokenfactory.nebius.com/v1/",
    api_key=os.environ.get("NEBIUS_API_KEY")
)

response = client.chat.completions.create(
    model="deepseek-ai/DeepSeek-R1-0528",
    messages=[
        {
            "role": "system",
            "content": """SYSTEM_PROMPT"""
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": """USER_MESSAGE"""
                }
            ]
        }
    ]
)

print(response.to_json())

角色扮演型promot
否定文章

## 第十一轮

1. 我在查看过去的运行记录的时候，发现了一些很有趣的问题
我看了一下运行的中间lean文件，花奴也问题十分严重 以T1.disable为例 反复的重试 MulChar.sum_eq_zero_of_ne_one 定理来证明。但是却查找不到这个定理。按理来说agent应该会用leansearch来查找定理的。为什么会有问题
但是我本地mathlib中根本就没有该定理。
你不需要去查看快照，这个文件在另一台设备上。
是否是记忆或者搜索器出问题了
2. 我似乎理解了问题在哪里，看起来 大模型在幻觉这里有一个lemma ，他在基于你的输入猜“名字” 但是这个是一个空泛的名字， 并不存在往往
可以对未知lemma 引用之后失败次数达到一定数量，然后我们让它在轮次上 禁用。
关于T9 和 T10 内置识别就能完成证明，不许呀 检索 所以没做leansearch 。
3. 1. 定理不能只给他名字，应该加上描述，带上sorry 然后给他。

2. 可以在定理描述的过程中给他 提前写好import，之后如果想禁用什么，我可以可以不允许其调用某一个import这样子一整个方向都block

3. route A 和route B放在我们的环境中，不要当成prompt喂给自由模式，更倾向自由模式是没有任何prompt 只让他证明就可以。但这部分非常好，我们依旧还是需要 给出具体路线指示 的，或者更强的，我们可以写出来对应的lean 代码， 然后做一个supervised experiment，这一部分是去证明 模型的基础能力的，他应该能达到100% 正确率。
例如： search_hints:
  - nontrivial character sum over finite abelian group
  - orthogonality of characters
  - sum over group of nontrivial character
可以这样写出对应的提示作为prompt
自由模式下 不要给他路线提示这类的

## 

1. 你不需要考虑 决定运行后怎么判定“这题算不算按规则完成”
2. 自由模式应当是完全按照 ax-prover 默认的promot，而不做任何其他修改
3. 禁用模式 promot控制不要去尝试那些路线，而不要使用 disable_forbidden_regexes 这样的硬性控制
4. 也就是给更多的权限给ax-prover

## 
1. 目前已经进行了多轮实验，最终结果为 1-8 题全部无法证明，9与10题可以证明。
2. 我发现了一个奇怪的现象，在我进行实验的时候，设置最大重试次数为6次，但是第一题貌似在六次中都没有进入搜索定理的leansearch。请首先排查一下这个问题。据我看到的信息，每次运行，都是agent在猜测定理的名字，猜错了继续重试
3. 请你仔细分析目前已有的报错信息，尤其是几次进行了十道题目的测试，并汇总相关信息，尝试给我一份完善的统计数据。并尝试分析为什么会出现错误。注意，我在此指的错误是前八个题目的错误。
4. 如果你要尝试重新进行实验，可以以 T1.free 为例子，这样节省时间
5. 可以尝试分析的问题方向，我目前大致可以想到的是，promot有问题，干扰了agent分析，leansearch有问题，或者是search到了定理，但是不使用，或者是我本地环境有问题，没有进入build阶段。如果你能找到跟好的问题方向，可以积极尝试
6. 尝试增加leansearch统计机制，将每次search到的内容也保存进快照，与之前的保存方式类似

## 

1. 先尝试修复 `CandidateTheorems` 的 Lake 源码映射问题  
   在这个问题没修好前，`T2` 到 `T8` 的实验结果不能作为模型能力结论。

2. 修复的时候，ATP主体代码尽可能不要动，是否我将 temTH与artfacts移动到ATP文件外面比较好，还是在ATP文件内部重新做一个完整的lean-mathlib环境，而不依赖外部lean-mathlib环境？抑或是尝试修改路径参数，可以解决该问题

## 

1. 我重新尝试了一次 30 重试次数的 T1.free 测试，发现完全没有调用 leansearch 。而且三十次测试全部错误，这肯定是不正常的状态。既然已经如你所说修复了路径报错。那么请你重新检查一下 快照文件 20260411_170838 ，尝试分析报错以及相关代码。分析问题出现在那个地方，是否是 free模式下 promot的问题还是search异常的问题，请重新检查一遍。给我一份 20260411_170838 的分析报告文件，仔细的分析并报告，统计错误原因。
2. 仔细分析问题在哪里
3. 你可以自己尝试运行试验，但是实验之前修改参数，避免浪费tokens

## 
1. 我用尝试运行了一次 T1.free 重试次数为 6 。并修改了promot的描述，你可以到config中查看。但是仍然无法调用 search。是否应该修改 experiment yaml中的 user comments？user comments 与 promot是什么区别，为什么要给null值，他起什么作用。贸然修改会不会干扰ax-prover的功能
2. 分析新生成的一轮快照文件，仍然分析报错以及相关代码并统计

## 
1. 修改 promot.py ,并写一个md详细的介绍目前的promot注入机制。自由模式也要注入在配置中写的promot。
2. user_comments 是否是全局生效的 promot ，所以一般给 null？

## 
1. 请分析 20260411_210627 的实验结果，你要用自己的沙盒实际去测试一下每一次重试生成的代码，看看问题出现在哪里。并且对结果分析统计。
2. 20260411_210627 我看到试验结果中有的定理并非不存在，我自己实际去 leansearch 上去搜索了 MulChar.sum_eq_zero_of_ne_one 定理，发现它存在。但是在 04112106_iter01.lean 中，却报错，报错内容是 Unknown identifier `MulChar.sum_eq_zero_of_ne_one`Lean 4(lean.unknownIdentifier) 。这明显有问题。
3. 思考是否是我本地 mathlib 版本较老导致的。是否调用leansearch搜索的到的都是最新的结果？
4. 仔细分析，并制作文档

##

1. 请先修改 _DEFAULT_SEARCH_WEB_TOOL 等参数设置，把他们调整参数的地方移动到config中，放在 ax_prover_experiment yaml里面。
2. 请分析 20260411_214642 的实验结果，你要用自己的沙盒实际去测试一下每一次重试生成的代码，看看问题出现在哪里。并且对结果分析统计。
3. 尝试根据 run-analysis-20260411_210627 的 341行开始的 建议的下一步 ，尝试一下。，但是尽可能不要修改代码主体。尝试做比较小的修改。
4. 我对这些实验结果感觉很奇怪，我是用的模型是 gpt-5.3-codex，不应该在证明这些简单问题的时候出现问题。是否是我们的代码修改过了ax-prover的一些机制？请再次检查
5. 对做的任何更改都要仔细的撰写文档

## 

1. 一些现象 我在最开始使用5.3codex的时候，默认没有开启reseoning，这个原因很可能就是我们一直感觉模型很笨的原因
2. 关于 promot ，
3. 关于 您说的没有加载mathlib，这个我后来通过删除模版文件中所有的import去测试了一下，当时使用没有思考的5.3codex，发现很多次都是连import都不写。在该轮次后面重试的次数中，又直接 import 了mathlib，没有引用具体模块名，就是一个mathlib。甚至我强制promot，要求禁止饮用mathlib，它也不听话。我当时突然感觉笨的异常，然后又想起来之前测试的时间，10轮T1.free带上思考编译search全部合起来才不到3min，一下子想起来好像没有开思考模式，后来尝试了一下强制使用 reasoning: {effort: high} 搜索的频率多了非常多，思考的时间也变得很长了。
4. 关于 您说的路径问题，我仔细排查了，发现有一点也许会有影响，axprover工作的目录是在lean项目内部一个ATP目录下的一个子目录。确实leanfile.lean没有引入，大概就是我vscode中会显示报错，但是对实际编译并无影响。后来我修改了 leanfile.lean ，但是对效果影响不大
5. 关于您说的 “you may add mathlib ...” 该报错是我在注入promot的时候对输出做的处理，并不是prover或模型或lean报的错误
6. 我最初尝试了对T1free的多轮测试，但是发现在56次重试的时候就会混乱，会重新回到最开始的思路上去，连用的定理都一样
7. 另外一个可以支持它确实搜索的例证是，在搜索到定理之后，会使用，而且我去查询之后发现，定理确实存在于mathlib中，上次组会讨论这个问题确实是我的疏忽，事实上是因为ai太笨，搜索到了这个定理之后，直接就放这里了，并没有正确import钙定理，知识放这了，导致报的错误与找不到定理一样。
8. 另外一个差别是：上次组会也提到了六轮的情况下，他会一直不进入搜索模式或者很少进入搜索，事实上就是因为用的是没开启思考模式的原因。开启了思考模式之后，会疯狂的搜索定理，当然也可能是我promot的设置。
9. 因为之前有一次import了mathlib，导致需要重新 restart file 。这个过程挺消耗时间的，现在还在built。开启思考模式之后话费的时间非常长。刚才做测试大概4轮用了11min。现在我终端再进行测试，但是貌似卡了，可能是因为编译器还在built。


一些现象：我在最开始使用 5.3codex 的时候，默认没有开启 reseoning，这个原因很可能就是我们一直感觉模型很笨的原因。

关于 promot。

关于您说的没有加载 mathlib，这个我后来通过删除模版文件中所有的 import 去测试了一下。当时使用没有思考的 5.3codex，发现很多次都是连 import 都不写。在该轮次后面重试的次数中，又直接 import 了 mathlib，没有引用具体模块名，就是一个 mathlib。甚至我强制 promot，要求禁止饮用 mathlib，它也不听话。我当时突然感觉笨的异常，然后又想起来之前测试的时间，10 轮 T1.free 带上思考、编译、search 全部合起来才不到 3min，一下子想起来有可能没有开思考模式。虽然use_responses_api: true ，但是后来尝试了一下强制使用 reasoning: {effort: high}，搜索的频率多了非常多，思考的时间也变得很长了。

关于您说的路径问题，我仔细排查了，发现有一点也许会有影响：axprover 工作的目录是在 lean 项目内部一个 ATP 目录下的一个子目录。确实 leanfile.lean 没有引入，大概就是我 vscode 中会显示报错，但是对实际编译并无影响。后来我修改了 leanfile.lean，但是对效果影响不大。

关于您说的 “you may add mathlib ...”，该报错是我在注入 promot 的时候对输出做的处理，并不是 prover 或模型或 lean 报的错误。

我最初尝试了对 T1free 的多轮测试，但是发现在 56 次重试的时候就会混乱，会重新回到最开始的思路上去，连用的定理都一样。

另外一个可以支持它确实搜索的例证是，在搜索到定理之后，会使用，而且我去查询之后发现，定理确实存在于 mathlib 中。上次组会讨论这个问题确实是我的疏忽，事实上是因为 ai 太笨，搜索到了这个定理之后，直接就放这里了，并没有正确 import 钙定理，知识放这了，导致报的错误与找不到定理一样。

另外一个差别是：上次组会也提到了六轮的情况下，他会一直不进入搜索模式或者很少进入搜索，事实上就是因为用的是没开启思考模式的原因。开启了思考模式之后，会疯狂的搜索定理，当然也可能是我 promot 的设置。

因为之前有一次 import 了 mathlib，导致需要重新 restart file。这个过程挺消耗时间的，现在还在 built。开启思考模式之后话费的时间非常长。刚才做测试大概 4 轮用了 11min。现在我终端再进行测试，但是貌似卡了，可能是因为编译器还在 built。

1. 将 config 里面 思考模式等，合并只保留 openai，anthropic，gemini 等，让思考模式成为其内部一个参数
2. 研究 ax-prover的代码，看看其promot注入机制，给我一份文档。并检查ATP的promot机制，我希望的是将我们的promot和prover的pormot合并，或者是否没有必要我们自己写promot？
3. 尝试整体精简ATP代码，policy 部分我的试验不需要，我感觉我的试验是一个小的试验，仅仅是调用prover对定理进行证明，三种模式，功能上做到美化终端输出，快照归档，config配置等功能，不需要太复杂的代码
4. leansearch 部分应该完全交给ax-prover。
5. 始终记住，ATP应当是基于ax-prover机制的，不需要做没有必要的操作
6. runtime_monitor 部分，只需要简单的时间预测机制就可以。

1. 为什么会搜索这么多次，我在yaml里面限制的是20，但是在终端中测试的时候，大概搜索了28次。你不需要重新运行，知识回答一下
2. wait_exponential_jitter 是什么，我应该如何修改这几个参数
3. 刚才在测试的时候 出现了 2026-04-16 10:38:23 - ERROR - [agent.py:597 - chat()] - Error: Connection error. 报错

1. 每次请求调用模型的时候，都打印一个 info，并在最后将终端输出信息保存到快照中，crtl + c的时候也要保存快照信息
2. 目前的设置每次leansearch都是20个，默认ax-prover是多少，按照默认值

限制模型调用次数，当重试达到多少次的时候，中断

1. 输出 llm_request 的时候，Sending LLM request #i -all #j ，其中，i是这次proposer的请求次数，j是该题目的请求次数
2. 输出 _process_lean_search_response 的时候，

1. 自由模式下，是否存在不同的证明方式，比例是多少
2. 禁用模式下，是否真正的实现了禁用某个定理或证明方式
3. routeA下，是否按照routeA方式证明
4. routeB下，是否按照routeB方式证明

两个问题的 promot 在 theorem_catalog.yaml中

1. 修改promot的方式，每个题目的promot应该仅仅有 free_instruction disable_instruction route_a route_b ，将他们 放到 ax-prover 的 user_comments，而且仅仅是针对该题目该模式下的 user_comments，而非全局模式下的 user_comments。


1. 根据下面的代码，改装一个 支持DeepSeek-R1-0528的模型
import os
from openai import OpenAI

client = OpenAI(
    base_url="https://api.tokenfactory.nebius.com/v1/",
    api_key=os.environ.get("NEBIUS_API_KEY")
)

response = client.chat.completions.create(
    model="deepseek-ai/DeepSeek-R1-0528",
    messages=[
        {
            "role": "system",
            "content": """SYSTEM_PROMPT"""
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": """USER_MESSAGE"""
                }
            ]
        }
    ]
)

print(response.to_json())

我又测试了几次，和之前一样，但是这几次发现 Error: Connection error 报错很多。
因为我看到中转站显示我调用次数达到了 4000+，感觉很不正常。然后在每次调用的时候专门去打印看了下。发现因为切换成 high 思考模式之后，思考时间变长了，每次是靠间隔3min左右，就会触发 Error: Connection error  报错。怀疑是中转站的问题，去问客服，客服回复是 非流无响应cloudflare会中断。怀疑是非流模式下，模型相应的输出都在后台，等完整输出之后，再结构化整理输出给我本地。而在等待输出的过程是无响应的，某个时间的时候，就会强制中断。
所以思考时间一旦达到这个阈值，就会报 Error: Connection error 错误。
我尝试用claude opus 4.6 做测试。仍然是一样的情况 Error: Connection error

至于您说的 olean not found 报错，是因为ai生成的代码缺少import，导致它在编译的时候会去找这个定理所在的位置，找不到，所以报了 not found。

至于为什么会缺少import，或者我们之前说的左右脑互搏的情况，我猜测事实上都是因为ai很傻，而傻的原因是因为我们之前的很多测试都是没有开 high 思考模式的，这对代码能力大概率是致命的。

而一旦我们开了high思考模式，或者对cluda而言 thinking 模式下，思考时间很有可能会超出这个阈值。从而导致中断。

我尝试看了prover的部分代码以及其工作流程。
prover默认的参数是这样的：同一个定理，最大重试次数为50次，每次重试会包含3次模型调用，第一次调用模型，模型在调用工具去leansearch，第二次调用模型，这一次一般而言时间会比较长，是思考的写代码的阶段。完成之后会去编译，失败之后，会出现第三次模型调用，也就是viewer，去生成 memory
每次调用leansearch，仅仅会搜索一次，搜索的最大范围是6个定理。

目前看来，中转站是彻底指望不上了。幸运的是我在源码中发现了官方留下来的对qwen3max的支持配置文件，但是baseurl并非阿里的网址，这里存疑，我得再看看。接下来我只能尝试修改一下axprover，来支持老师您给的deepseek的api。
