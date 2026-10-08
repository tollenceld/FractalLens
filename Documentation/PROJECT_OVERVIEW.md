# 项目说明 · Fractal Lens

原生 iPhone **生活中的分形与重复结构**观察工具。英文界面、离线使用，围绕 **See → Reveal → Understand → Replay → Collect** 展开。明亮的近白 / 墨绿视觉，原生 Liquid Glass；包含八个生活场景研究、Stories Of Plant 的十种规则模型和六个精选植物照片。

## 运行

1. 用 Xcode 打开 `FractalLens.xcodeproj`，选择 `FractalLens` scheme 并 Run。最低 iOS 17，无第三方运行依赖。
2. Discover 点击 **Find a pattern**，直接进入持续视频取景。无需按快门；稳定的多帧结构会自动进入揭示。
3. 模拟器没有摄像头，使用清楚标注的 **Guided camera preview**。约几秒后自动进入示例体验；暂停键允许停留。
4. **Open a photo** 导入任意照片；**Try a specimen** 选择植物实拍标本或生活场景插画。清楚边缘、较高对比度的图像效果更好。
5. Patterns 的 **In the world** 探索河流、闪电、海岸、地面裂纹、螺旋、窗格和织物；**Rule studies** 保留十种逐代生成模型。
6. Discover 播放按钮可观看河流插画的约 30 秒完整发现。所有插画明示为 Guided study。
7. 真机首次请求摄像头权限；需要在 Xcode 选择自己的 Signing Team。

工程配置来源为 `project.yml`；已生成工程可直接打开，不需要 XcodeGen。重新生成执行 `xcodegen generate`。

## 连续观察与识别边界

视频帧在设备上采样，由 Vision 提取轮廓和可选场景标签。至少四帧、持续至少 1.6 秒的稳定证据才能自动触发。12 秒没有稳定证据会自然进入标注的教学示例，**不会把示例作为刚刚拍到的识别结果**。

结果依据图像证据分流：可见分枝层级进入 Scale Dive / Align；同尺度重复进入 spatial repetition；普通图像展示实际轮廓和转折关键点。螺旋不是天然等同于分形。照片导入也使用这套分流。

这不是经专业数据集验证的通用分形识别模型。植物骨架自动提取适用于清楚、可见分枝的对象；河流、闪电及螺旋场景目前提供原始插画研究，相机可分析轮廓但不承诺专业结构分类。图像标签不能证明分形。未取得层级时不显示虚构角度、比例、深度或相似度。

视频流不保存为电影，不采集麦克风。点击 Collect 才保存最终图像及观察结果，全部在本机，无账号、上传或云同步。

## 交互

- 原生 Discover / Patterns / Collection 三个 Tab；iOS 26 使用 Liquid Glass，iOS 17–25 使用系统材质回退。
- Live lens 支持暂停/继续；选择照片时可点选主体；后台停止相机和分析。
- 有尺度证据的结果允许 Whole / Branch / Twig、对齐、参数联动、Replay 和单变量 Alter。
- 无尺度证据的结果允许轮廓/关键点/重复组高亮、Replay the trace 与收藏；不推断生长规则。
- Rule studies 支持逐代动画、暂停、重启、代数选择、放大以及四幕规则短篇。
- 详情可切换 Moment / Structure / Glyph。Observe this subject again 添加同一对象的下一次记录。
- 数据为版本化 JSON 与独立图片，存于 Application Support/FractalLens，兼容旧版收藏。演示插画和用户实拍分别标识。

## 模块

| 模块 | 职责 |
|---|---|
| Camera | 视频流、帧采样、稳定证据触发、暂停/权限/照片导入 |
| Analysis | Vision 轮廓/上下文、形状重复、关键点、前景骨架与估算 |
| FractalModel | 结构图、规则、来源、证据类型与版本化数据 |
| World | 八个原创生活场景插画、家族图谱、非分形解释 |
| Patterns | Stories Of Plant 的规则模型、turtle、几何缓存与逐代形变 |
| GrowthSimulation | 分枝传播、确定性规则重放与单变量改变 |
| Visualization | 统一舞台、尺度/路径动效、证据高亮、Glass 控件 |
| Collection | 原子保存、重启恢复、同一对象记录、照片标本 |

六个植物照片的许可与作者见 [照片署名与许可](../ATTRIBUTIONS.md)。插画均为本项目生成。所有指标为几何估计；具体方法、产品判断和技术范围见 [产品判断与识别范围](../Deliverables/Revision-03/PRODUCT-AND-RECOGNITION.md)。

## 测试与交付

Xcode 使用 Product → Test。自动化涵盖多帧稳定/运动/空白/超时、实际 Vision 轮廓、数据兼容、规则生成、持久化、自动揭示、暂停、结果分流、完整收藏和旧植物流程。

最新截图、录像与验证报告在 [`Deliverables/Revision-03`](../Deliverables/Revision-03)，前两版保留用于对照。模拟器不验证真机相机权限切换、焦点、触觉和实体设备帧率；这些未实测项目在验证报告中明确列出。
