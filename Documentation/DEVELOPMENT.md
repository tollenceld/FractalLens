# 开发说明

## 环境与工程

使用带有 iOS 26 或更新 SDK 的 Xcode，以编译原生 Liquid Glass API。部署目标为 iOS 17，设备类型为 iPhone；较早系统由代码中的可用性判断选择系统材质回退。

`FractalLens.xcodeproj` 已提交，首次运行不依赖 XcodeGen。`project.yml` 维护 target、资源、构建设置和共享 scheme；修改这些配置时，应更新 YAML 并重新生成工程：

```bash
xcodegen generate
```

相机与 Vision 分析依赖 Apple 系统框架，应用没有第三方运行依赖。`scripts/` 中的辅助工具不参与应用运行。

## 构建与测试

无需配置开发团队即可检查模拟器构建：

```bash
xcodebuild -project FractalLens.xcodeproj -scheme FractalLens \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

在 Xcode 中使用 Product → Test，或先列出可用模拟器，再指定一台运行测试：

```bash
xcrun simctl list devices available
xcodebuild -project FractalLens.xcodeproj -scheme FractalLens \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedData test
```

命令中的设备名称应替换为本机实际安装的模拟器。单元与集成测试覆盖多帧稳定判断、Vision 轮廓、规则生成、版本化数据与持久化；UI 测试覆盖连续观察、暂停、超时示例、结果分流、规则研究与收藏恢复。

历史测试数量、环境及结果记录在各版 `Deliverables/**/VERIFICATION.md` 中。修改后应记录本次实际执行的检查，保留验证日期；历史通过结果不能代替当前提交的验证。

## 改动时对表

- **保持证据来源可辨认**：用户实拍、精选照片、教学插画与理想化规则模型使用各自的来源标识。
- **先有证据，再显示指标**：图像分类标签不决定分形结论；没有分枝层级时不开放依赖生长规则的参数改变。
- **保持坐标一致**：预览、冻结帧与轮廓共用图像方向和归一化坐标，避免标记脱离主体。
- **尊重观察生命周期**：暂停、照片选择与后台状态停止观察；回前台重新积累稳定帧。
- **保留收藏兼容性**：修改数据模型时，检查旧版 JSON 的解码、新字段默认值与重启恢复。
- **保留动效回退**：交互变化应同步考虑 Reduce Motion，真机性能与触觉需单独实测。

更具体的产品依据见 [产品判断与识别范围](../Deliverables/Revision-03/PRODUCT-AND-RECOGNITION.md)。

## 版本管理

`main` 保存可追溯的项目状态。功能开发使用独立分支，提交说明写清改动对象与结果；合并前按改动范围执行构建或相关测试。

`Deliverables` 保存产品迭代的可见证据。新的截图、录像与验证报告放入新的 Revision 目录，保留已有记录。源码和交付材料已纳入初始版本；`.build`、`DerivedData`、`.xcresult`、签名材料与个人 Xcode 状态由 `.gitignore` 排除。

GitHub Issues 用于记录问题和后续工作。缺陷应包含运行环境、复现步骤、实际表现与预期表现；相机或分析问题需说明使用真实拍摄、导入照片还是教学示例。提交 Pull Request 时，说明行为变化、实际验证结果与仍待验证的部分。
