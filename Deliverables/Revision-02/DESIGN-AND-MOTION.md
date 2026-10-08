# Fractal Lens · 第二版设计与动效

这一版从深色观察仪器转为明亮的自然结构图谱。主视图采用接近纸白的背景、深墨绿文字与 SF 系统字体；绿色、蓝色、紫色、陶土色分别对应四个规则家族。

## 内容架构

原生 TabView 提供 Discover / Patterns / Collection。Discover 保留现实观察入口，同时呈现规则家族、短篇互动故事与精选真实照片。Patterns 中的理想化生成模型与 Collection 中的真实照片标本明确区分。

四个家族共十种模型，生产式来自用户提供的 `Stories Of Plant .playgroundbook`：

| 家族 | 图形 | 展示行为 |
|---|---|---|
| Branching | Feathered fern、The branching tree、Wild growth、The unfolding frond | 主轴推进、分枝记忆、父子传播 |
| Repeating edges | Koch snowflake | 一段直线被四段折线替换 |
| Folding curves | Dragon variation、Lévy curve | 互补转向、折叠、连续展开 |
| Nested forms | Sierpiński weave、Pentagonal bloom、Recursive tiles | 嵌套、空隙、层级复制 |

保留原 playground 的语义细节：Wild growth 中 X 也绘制；复杂蕨叶中未定义的小写 f 忽略；Dragon variation 使用 30°，不称为经典 90°龙曲线。数学图形不被描述为自动扫描结果。

四幕互动短篇：A small beginning → Repeat the gesture → Let it branch → Look at the whole。文案将字符替换转译为可理解的动作，模型承担解释。

## Liquid Glass 层次

使用 iOS 26 原生 NavigationStack、TabView、toolbar、glass / glassProminent 按钮及 GlassEffectContainer。玻璃承载导航、类别筛选、播放、尺度与规则选择；内容图形直接绘制在清晰背景上。iOS 17–25 使用系统材质和按钮回退。

依据：[Apple Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)、[Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)。

## 动效编排

两套时间语言分别承担操作反馈和内容解释：控件使用 response 0.72 / damping 0.86 的克制弹性；结构变化使用 1.35 秒的非对称贝塞尔曲线 `(0.22, 0, 0.18, 1)`，先启动，再缓慢收束。自动演化每 2.2 秒推进一代，保留约 0.85 秒的观察停留。

### 规则图谱

1. 单路径且分段数量可对应时，先将旧直线按子段数量划分，再插值至新折线。雪花的尖角从原边缘连续展开。
2. 分枝模型从主轴向末端推进，按路径距离传递到达时间。子枝的起点须在父枝抵达后出现；不是整体淡入一张新图。
3. 前一代保留轻微回声，帮助看出增加的结构；绘制后的图形保持静止，留出阅读时间。
4. Generation 轨道支持直接选择、暂停、重启和单步推进。Look closer 以连续缩放观察细部；Reduce Motion 使用淡化。

### 真实观察

保留照片 → 骨架 → Whole / Branch / Twig → Align → Replay → Alter → Collect 的连续对象。尺度对齐中，蓝色整体、绿色分枝、橙色细枝共同旋转缩放到根点，保留几何差异。相似度在对齐停留后出现。保存成功后进入原生 Collection 标签。

## 实现边界

几何仅在代数变化时计算并缓存，逐帧只绘制和插值；静态图谱缩略图不持续运行时间轴。规则学习、真实分析与本地收藏沿用不同数据来源，并在界面与说明中明确标注。

真机相机、触觉、实体设备帧率及全面辅助功能验收仍需后续验证。录像编码帧率不代表实际渲染性能认证。
