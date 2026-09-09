# 可恢复执行与交接

## 先写完整脚本，再跑，再低频定时检查

在正式发压前准备全部环节：参数化环境配置、用户确认的矩阵manifest、题库/判分、AIS执行、资源采集、断点恢复、指标汇总、分配置Excel生成。不得先手动发压再临时补关键采集或统计脚本。先dry-run列出完整格数，再用mock数据验证计数/单位/失败处理/Excel产物，最后在授权内做最小真实smoke并开始正式运行。

启动编排器后，让脚本负责逐格执行和自动收尾报告。用产品提供的定时机制建立低频检查，默认10分钟，用户指定周期则遵从。使用现有同run-id任务避免重复；不存在调度工具或无相应权限时明确说明无法设置，不假称会自动回来。不得绕过产品约束自行加cron或另开常驻GPT循环。

定时任务只读该run-id的紧凑status/exit/summary：是否终止、完成格数、异常与最终Excel路径。不重复加载聊天历史、全部日志或原始逐请求数据，不重复登录或发模型请求。未变化且无须处理时保持安静；完成/失败/需用户操作时才通知。任务身份、作用域和停止条件写进自动化提示，禁止借检查之名重启/扩容/改变矩阵。

正常情况下测试脚本自行生成Excel，定时检查只核验和交付；若汇总失败，终止后离线修复/重建报告，不重跑已经完成的推理。完整完成、失败中止或用户停止时，交付完整/部分Excel并暂停或删除本次检查任务。用户要求只修技能或只看旧结果时不创建任何定时任务。

## 不可变实验

每次实验有manifest，固定：model/revision/quantization、image digest、部署配置hash、精确题集与tokenizer hash、采样/output/cache策略、全部入口及导入依赖hash、矩阵与grader、指标定义。路径仅作定位，hash/ID才作身份。

模型/参数/题目/核心依赖变化需新实验目录。绝不修改旧checkpoint-spec来“兼容”新代码。真正等价的数据迁移须明确规则并离线验证；旧数据仍留原址。

建议目录（适配现有框架，不为格式重写已经可靠的工具）：

```text
run-id/
  manifest.json
  checkpoints/checkpoint-spec.json
  units/cell-or-case/attempt-0001/
    native/                  # AIS 原始文件及 db_data
    requests.jsonl
    summary.json
    grader/                  # 适用时，单独恢复
  checkpoints/receipts/      # 原子封存，包含结果hash和stop状态
  telemetry/
  report/
run-id.resume-unique.control/ # 每次恢复独立，不覆盖旧PID/exit/log
```

写日志append-only，完成回执fsync+原子替换并验证产物hash。记录开始、终止状态、退出码、配置身份和artifact清单；单看summary文件存在不等于整格完成。

## 恢复语义

- 推理完整但答案错/性能差也算已执行，不能重试来挑好成绩。quality score与execution status分开。
- 评分中断只重跑grader，不重新生成已经完成的答案。
- HTTP半截流不能从中间token续接。保存旧失败，在确认服务器排空后另起attempt；并发半格不能与新半格拼算TPS。
- 恢复先校验manifest、依赖hash、已封存回执，并恢复容量停止状态。近1M正式异常后的更高并发在后续恢复中仍禁止自动运行。
- 预热失败与正式容量失败分开；冷测新attempt必须新prefix namespace，暖机成本不能消失。
- 限制本次max-cells/时间不删除剩余计划。STOP在安全单元边界阻止新请求，不自动重启服务或无限重试。
- 断线后先检查真实PID+start time/boot identity及退出记录，避免PID复用；锁只是协调证据，不单独证明活着。原任务可能仍在运行，不能重复发起。
- 后台运行用互斥锁、唯一控制目录、退出文件及可等待的进程身份。新启动前确认无冲突测试、服务器排空、后端正确、运行版本未变、采集窗口能覆盖下一格。
- proof/telemetry过期时刷新真实观测，不延长旧证据时间戳、不伪造UI证据；也不要要求某个固定UI渠道，如果等价受支持只读接口足以核验。

## 修改测试器的离线验证

用mock网络/假记录测试，无生产请求：中途退出后的恢复、重复start/end、缺usage、截断SSE、错误后端、原生DB引用、依赖变化拒绝、评分独立恢复、近1M停止跨恢复保留、冷prefix刷新及互斥启动。验证真实runner调用了新guard，不能只测孤立helper后宣称修复生效。

脚本候选验证通过后，在旧任务终止且锁可取得时备份并安装；记录安装前后hash。离线PASS不是实际模型性能或质量通过。

## 参数化交接目的地

每次实际配置改动及每次测试结束都写记录。变更前写intent，完成后写outcome；失败也写。首选复用现有带锁audit函数，追加而不截断历史。artifact_root/handoff_path由本次用户指定，可位于SFS、其他共享盘或本地项目目录；可选notes_destination指向Obsidian或其他知识库。不要求某台电脑的vault或固定路径，启动前确认权威原始数据位置。

最小事件字段：

```json
{
  "event_id": "唯一事件ID",
  "time_utc": "ISO8601",
  "phase": "intent或outcome",
  "scope": "精确服务/部署/实验/测试格",
  "before": {"config_id": "旧版", "hash": "证据摘要"},
  "change": "本次改什么和原因；只读则说明未变更",
  "after": {"config_id": "实际新版或未提交"},
  "result": "完成、失败、部分完成、未测等真实状态",
  "evidence": ["原始日志/summary/manifest路径"],
  "metrics": {"success": null, "total": null},
  "rollback": "已核实的回退方式或不适用",
  "next": "待做事项及阻塞条件"
}
```

字段是记录结构示例，不可把示例值当真数据。不要在审计中写凭据。若指定共享存储/知识库暂不可达，在本次工作目录保存待同步记录并标明未同步，不能声称双写完成。

checkpoint顶部保留短的“当前状态、下一步、活动run/control、保护范围、最新用户覆盖”。过去密集轮询日志不要复制进技能或每轮上下文。按上述低频定时机制等脚本终止后集中整理；状态无变化不反复大段输出。
