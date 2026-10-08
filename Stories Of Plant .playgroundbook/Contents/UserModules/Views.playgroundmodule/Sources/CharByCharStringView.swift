import Foundation
import UIKit
///可以动态设置形状绘制路径页面的视图控制
///`CharByCharStringView`是`CharByCharDrawingView`的一部分，并为L系统路径绘制动画。
///这包括设置动画箭头，该箭头始终显示当前位置和方向。
internal class CharByCharStringView: UIView {
    let string: String

    var animationIndex = 0

    private let spacing: CGFloat = 20

    /// 显示完整字符串的文本字段
    private let textField = UITextField()

    /// 突出显示当前动画进度的视图
    private let highlightView = UIView()

    /// 默认初始化器
    init(string: String) {
        self.string = string
        super.init(frame: .zero)

        // 设定文字栏位
        addSubview(textField)
        textField.text = string
        textField.textAlignment = .center
        textField.isUserInteractionEnabled = false
        textField.font = .monospacedSystemFont(ofSize: 50, weight: .light)
        textField.defaultTextAttributes.updateValue(spacing, forKey: NSAttributedString.Key.kern)

        // 设置高亮区域视图
        addSubview(highlightView)
        highlightView.backgroundColor = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 0.4)
        highlightView.layer.cornerRadius = 8
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新布局
    override func layoutSubviews() {
        if bounds.isEmpty { return }

        textField.frame = currentFrameForTextView
        highlightView.frame = currentFrameForHighlightView
    }

    ///根据当前动画索引，计算文本字段的框架
    var currentFrameForTextView: CGRect {
        var frame = bounds

        frame.size.width = max(
            bounds.width,
            string.size(with: textField.font!, kerning: spacing).width
        )

        //如果字符串长于宽度，则在动画过程中将文本字段向左移动
        let maxSize = bounds.width - 40
        let rectMax = textField.textRect(for: 0 ..< animationIndex).maxX
        if rectMax > maxSize {
            frame.origin.x -= (rectMax - maxSize)
        }

        frame.origin.x += spacing / 2 // 补偿尾随字距调整

        return frame
    }

    /// 根据当前动画索引计算高光视图的框架
    var currentFrameForHighlightView: CGRect {
        var frame = bounds

        var rect = textField.textRect(for: 0 ..< animationIndex)
        rect = textField.convert(rect, to: self)
        frame.origin.x = rect.origin.x - spacing / 2
        frame.size.width = rect.width

        // 如果字符串长于宽度，则在动画过程中将文本字段向左移动
        let maxSize = bounds.width - 40
        if rect.maxX > maxSize {
            frame.origin.x -= (rect.maxX - maxSize)
            frame.origin.x += spacing / 2 // 我也不知道为为什么,他就是需要在这里
        }

        return frame
    }

    ///动画到下一个字符。
    ///仅在动画尚未完成时调用
    func animateNext(duration: Double) {
        animationIndex += 1
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.textField.frame = self.currentFrameForTextView
            self.highlightView.frame = self.currentFrameForHighlightView
        })
    }

    ///在动画开始之前立即进行初步设置
    func beginAnimation() {
        textField.frame = currentFrameForTextView
        highlightView.frame = currentFrameForHighlightView
    }

    /// 动画结束后进行清理
    func finishAnimating() {
    }

    /// 重置为开始状态
    func reset() {
        animationIndex = 0

        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.textField.frame = self.currentFrameForTextView
            self.highlightView.frame = self.currentFrameForHighlightView
        })
    }
}

// MARK: 扩展

private extension String {
    func size(with font: UIFont, kerning: CGFloat) -> CGSize {
        NSString(string: self).boundingRect(
            with: CGSize(width: Double.infinity, height: .infinity),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font, .kern: kerning],
            context: nil
        ).size
    }
}

private extension UITextField {
    func textRect(for range: Range<Int>) -> CGRect {
        if range.isEmpty {
            let pos = position(from: beginningOfDocument, offset: range.lowerBound)!
            return caretRect(for: pos)
        }

        let start = position(from: beginningOfDocument, offset: range.lowerBound)!
        let end = position(from: beginningOfDocument, offset: range.upperBound)!
        let range = textRange(from: start, to: end)!
        return firstRect(for: range)
    }
}
