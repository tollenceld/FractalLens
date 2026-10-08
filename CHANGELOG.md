# 变更记录

记录可观察的产品变化与仓库基线。日期使用 Asia/Shanghai；Revision 表示已有开发迭代，不代表 App Store 发布版本。

## 2026-10-09 · 初始仓库基线

- 将现有第三版项目纳入 Git，保留应用源码、测试、生成工程、原始 Playground 和历次交付材料。
- 整理 README、完整项目说明与开发约定，保留既有测试的日期、结果与验证边界。
- 补充本地缓存、个人工程状态与签名材料的忽略规则。
- 本次整理未修改应用源码或产品行为。
- 上传前使用 Xcode 27.0 / iOS Simulator 27.0 SDK 完成禁用签名的模拟器构建，结果通过。构建包含未依赖 AppIntents.framework 时跳过元数据提取的提示；本次未重新执行全量测试，既有测试结果保留于各版验证报告。

## Revision 03 · 生活中的结构与连续观察

- 从植物观察扩展到八个生活场景，区分分枝、边界、螺旋与同尺度重复。
- 使用持续视频取景与多帧稳定判断自动触发揭示；超时后进入明确标注的教学示例。
- 按分枝层级、重复证据与普通轮廓选择结果体验，保存实际证据与来源。
- 保留规则研究、植物照片与旧版收藏兼容。

详见 [产品说明](Deliverables/Revision-03/PRODUCT-AND-RECOGNITION.md) 与 [2026-10-08 验证记录](Deliverables/Revision-03/VERIFICATION.md)。

## Revision 02 · 规则研究与动效

- 保留 Stories Of Plant 的十种规则模型，支持逐代演化、局部放大与规则短篇。
- 完善尺度对齐、结构回放与分枝传播动效。

详见 [设计与动效](Deliverables/Revision-02/DESIGN-AND-MOTION.md) 与 [验证记录](Deliverables/Revision-02/VERIFICATION.md)。

## 初期原型 · 植物观察

- 建立照片观察、结构揭示、尺度比较、规则改变与本地收藏的体验链路。
- 保留六张有作者和许可记录的植物照片，以及近似结构标注工具。

初期截图与录像保留于 `Deliverables/` 根目录。
