# GLM/Qwen 部署分支

只在当前项目使用 GLM、CodeGeeX/GLM 系列、Qwen/Qwen-VL 或其量化变体时读取。具体参数以模型卡、权重配置和实际运行时为准。

## 共同检查

- 权重、Tokenizer/Processor、Chat Template 和生成配置来自同一兼容 Revision。
- 确认模型是 Dense 还是 MoE、是否内置 Reasoning、是否包含 MTP/草稿层、是否需要自定义代码。
- 量化格式必须与镜像、算子和硬件代际完全匹配；W4A8、W8A8、C8 等不能只根据文件名推断。
- 验证普通聊天、流式、Reasoning、Tool Calling、结构化输出和目标上下文，而不是只请求 `/models`。
- 以实际进程确认上下文、并行拓扑、显存利用率、批处理、图编译和缓存参数。

## GLM 注意项

- 核对对应运行时的 Reasoning Parser 和 Tool Call Parser，保留流中的 reasoning 字段。
- MTP、MLAPO、FlashComm、EPLB、Shared Expert、稀疏量化算子和 PD 分离均属于模型/镜像/硬件组合能力，不是通用开关。
- 多节点或 PD 部署需要逐个 Prefill/Decode Rank 验证，而不是只检查入口代理。
- A2、A3 等硬件代际参数不得混用。

## Qwen 注意项

- 区分 Qwen 文本、Qwen-Coder、Qwen-VL、Qwen-Audio 和 MoE 版本；它们的 Processor、输入协议和资源模型不同。
- Qwen-VL 验收要固定图片数、分辨率、视频帧和媒体传输方式。
- 检查 Chat Template、Tool Calling 格式、Thinking 开关和流式字段是否与客户端适配器一致。
- 多模态 Processor 缓存和媒体预处理节点需要纳入部署架构。

## 分支验收补充

- 至少一个普通响应、一个流式响应、一个目标能力请求和一个边界输入。
- 返回内容、Reasoning、Tool Call/JSON 字段与客户端实际可见结果一致。
- 压力后再次做功能回归，确认没有空流、Parser 错误或实例掉线。
