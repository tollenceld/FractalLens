# Fractal Lens · 生活中的分形

## 产品判断

把“植物”扩展为“生活中的分形与重复结构”，并将拍照变成持续观察，是合理的方向。首屏邀请变为 **See how the world repeats itself.** 植物只是一个入口；河流、闪电、边界、螺旋、窗格和织物都能提供不同的观察问题。

保留积极反馈，修改一个关键细节：超时后不冒充识别成功，而是自然进入 **Guided study · illustrated structure**。用户仍然获得一次完整发现，同时可以区分自己拍到的证据与教学示例。普通重复、螺旋和分形不是同义词，结果页根据证据选择不同体验。

## 连续观察

- AVFoundation 的 `AVCaptureVideoDataOutput` 输出连续视频帧，不再使用 `AVCapturePhotoOutput` 或快门按钮。
- Session 配置与启动在专用串行队列进行；视频帧在另一条队列采样，大约每 0.7 秒保留一个缩小帧。过期帧直接丢弃，不积压分析工作。
- 预览与图像证据使用相同方向和 aspect-fit 映射。轮廓、拐点与最终冻结帧共用归一化图像坐标。
- Vision 轮廓、图像对比度/边缘能量与空间边缘签名提供实际反馈。至少四帧、持续至少 1.6 秒、轮廓数量与位置分布稳定，才能自动触发。
- 捕获后显示一个轻反馈，冻结实际帧，进入表面消退和结构描出。无需按拍摄按钮。
- 12 秒内未取得稳定证据时自动进入标注示例。暂停、选择照片、示例列表、说明面板与后台状态暂停观察；回到前台重新积累稳定证据。
- 摄像头被拒绝或不可用时显示明确状态，并提供照片、示例和权限设置。模拟器使用标注的插画取景预览，不能证明真机摄像头已验证。
- 不录麦克风，不保存视频文件；只有点击 Collect 时将最终帧与结构保存到本地。

## 识别能力与结果分流

这是一个可运行的本机计算机视觉原型，不是经训练及评测的通用“分形物体分类器”。它可以对广泛场景提取轮廓和关键点，并寻找相近的形状重复；不承诺识别任何物体的真实分形性质。

1. **场景上下文**：Apple Vision 内置图像分类仅提供可选物体标签。标签不决定分形分数。
2. **分枝证据**：植物相关上下文且前景骨架提取成功时，使用真实连接关系与嵌套子图进入 Scale Dive → Align → Self similarity。当前自动分枝分析仍以清楚的植物分枝为主要适用范围；河流和闪电提供原始插画研究，不宣称自动完成专业水文或放电分析。
3. **重复证据**：比较轮廓的长度、长宽比、闭合性和面积/周长平方紧致度。至少三个近似轮廓形成重复组。显示 **spatial repetition**，不显示分形相似度。
4. **普通轮廓**：显示提取路径与转折关键点，并明确没有可靠递归层级。用户可回放真实路径，收藏这次观察。
5. **螺旋研究**：通过精确生成的原始插画解释转向与扩张。螺旋不会自动获得分形结论；相机中的螺旋目前仍按照轮廓/重复证据处理。

无可靠层级的结果不显示默认 35°、0.5 或伪造递归深度，也不开放依赖分枝规则的 Alter。照片导入共用同一场景分析器。所有置信度和比例是原型几何估计，不是专业测量。

## 内容与信息架构

Discover 增加“世界正在重复”的河流与螺旋主视觉，以及生活场景入口；Patterns 分为 **In the world / Rule studies**。

| 生活家族 | 原创插画研究 | 观察问题 |
|---|---|---|
| Branching | River networks / A path through the sky | 小支流或分路径是否像整体？ |
| Irregular edges | The restless coastline / Cracks in the ground | 更小的边界会揭示哪些转折？ |
| Spirals | A spiral in a shell / A curl unfolding | 每次转向时，什么发生了变化？ |
| Everyday repetition | Windows within the city / The rhythm of a weave | 是同一大小的重复，还是跨尺度重复？ |

八个场景是自有 procedural illustrations，无外部照片授权问题。原 Stories Of Plant 的十种规则研究和六个有来源记录的植物照片全部保留，分别标识。收藏现在支持不同结构类型、来源和证据备注；旧版 JSON 可继续读取。

## 动效编排

- **Attend**：轮廓低透明度出现，拐点轻呼吸；观察进度表示真实稳定帧数。
- **Settle**：稳定反馈以缓动环收束。短暂停留使用户理解“我刚刚看见了什么”。
- **Hold**：固定当下帧，避免相机移动后结构漂离主体。
- **Reveal**：沿实际路径描出结构，照片表面逐渐消退。分枝从主轴传播；普通轮廓按路径时序展开。
- **Understand**：有嵌套证据才深入尺度；其余路径进入轮廓、关键点和重复组的可点击证据。
- **Replay**：分枝重放规则；普通图像重放提取路径，不包装为生命生长。
- **Collect**：保存成功后收束为 Glyph，再返回收藏。

继续使用上一版统一的 spring 和缓动曲线、原生 Liquid Glass 导航与控件。Reduce Motion 使用分阶段淡化；后台取消分析/停止相机并暂停动画。

## Apple 技术依据

- [Recognizing Objects in Live Capture](https://developer.apple.com/documentation/vision/recognizing-objects-in-live-capture)
- [AVCaptureVideoDataOutput](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput)
- [VNClassifyImageRequest](https://developer.apple.com/documentation/vision/vnclassifyimagerequest)
- [VNDetectContoursRequest](https://developer.apple.com/documentation/vision/vndetectcontoursrequest)
