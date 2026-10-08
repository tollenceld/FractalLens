public extension LSystem {
    ///使用生产规则，逐个字符地将系统应用于字符串
    func apply(to input: String) -> String {
        var result = ""

        for char in input {
            if let rule = self.rule(for: char) {
                result.append(contentsOf: rule.successor)
            } else {
                result.append(char)
            }
        }

        return result
    }

    ///查找给定字符（如果存在）的生产规则
    private func rule(for char: Character) -> ProductionRule? {
        for rule in productionRules {
            if rule.predecessor == String(char) { return rule }
        }

        return nil
    }

    ///将系统多次应用于一个字符串，即演变系统“ count”次
    func apply(count: Int, to input: String) -> String {
        (0 ..< count).reduce(input) { string, _ in
            apply(to: string)
        }
    }
}
