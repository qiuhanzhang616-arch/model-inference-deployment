# modelarts-glm-deploy-bench

面向华为云 / HCSO **ModelArts Standard** 的通用 Ascend 大模型部署、排障、调优与测试技能。用于指导支持 `SKILL.md` 的 AI 编程助手执行工作，不是一个开箱即用的云端部署器。

## 能做什么

- 根据实际硬件、镜像和模型核对部署兼容性，区分 Standard 与 Lite Server 的启动和服务发现方式。
- 区分混部、PD分离及实际设备拓扑，按证据定位初始化、调度与通信问题。
- 先确认业务场景，再展开完整的输入长度 × 并发矩阵。
- 针对 coding 场景关注 decode，验证原生前缀缓存命中率，不把响应缓存当成模型性能。
- 指导 LiteLLM / AIS-bench 性能测试、客户功能题、断点恢复、低频定时检查和分配置 Excel 交付。
- 保留配置指纹、原始结果、失败分母和交接记录，不修改受保护的服务。

## 安装

将此仓库克隆到 Codex 的个人技能目录中：

```bash
git clone https://github.com/qiuhanzhang616-arch/modelarts-glm-deploy-bench.git "$HOME/.codex/skills/modelarts-glm-deploy-bench"
```

如果目标目录已经存在，请先备份并比较，不要直接覆盖。也可以将仓库内容放到其他支持技能的工具所要求的位置。

调用示例：

```text
使用 $modelarts-glm-deploy-bench，先确认我的环境与测试矩阵，
然后准备部署和可续跑测试脚本；未经确认不修改现有服务。
```

## 离线矩阵工具

要求 Python 3，仅使用标准库。

```bash
python scripts/build_matrix_plan.py --concurrency-range 1 64 --input-k-range 8 256
python -m unittest discover -s scripts -p "test_*.py" -v
```

示例展开为并发 `[1,4,8,16,32,64]` × 输入 `[8,16,32,64,128,256]K`，每个配置、每种缓存模式共36格。显式指定的并发2、48等档位会保留。

**矩阵工具只输出计划JSON，不调用模型、不启动服务，也不直接生成Excel。** 实际测试器、资源采集器和Excel报告脚本需要助手根据本次环境准备并验证。

## 文件

| 路径 | 用途 |
|---|---|
| `SKILL.md` | 技能入口、工作边界和参考路由 |
| `agents/openai.yaml` | 技能界面元数据 |
| `references/deployment.md` | Standard部署与启动排障 |
| `references/tuning.md` | 受控调优与瓶颈定位 |
| `references/benchmark.md` | 矩阵、计时、缓存、功能评分与报告口径 |
| `references/resume-handoff.md` | 不可变实验、续跑、定时检查及交接 |
| `scripts/` | 离线矩阵生成与测试 |

## 边界

本仓库不含模型权重、容器镜像、云账号、密码、API key、私钥、客户测试记录或固定生产地址。SFS、Obsidian、主机、服务与凭据引用均需由使用者按本次环境提供。

模型、镜像和框架兼容性需在实际部署时核对官方资料；技能中的示例不构成兼容性或性能保证。公开仓库不代表授权助手自行修改云资源。
