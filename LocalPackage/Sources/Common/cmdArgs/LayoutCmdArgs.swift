public struct LayoutCmdArgs: CmdArgs, RawCmdArgs, Equatable {
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .layout,
        allowInConfig: true,
        help: """
              USAGE: layout [-h|--help] \(LayoutDescription.unionLiteral)...

              OPTIONS:
                -h, --help   Print help
              """,
        options: [:],
        arguments: [newArgParser(\.toggleBetween, parseToggleBetween, mandatoryArgPlaceholder: LayoutDescription.unionLiteral)]
    )
    public var toggleBetween: Lateinit<[LayoutDescription]> = .uninitialized

    fileprivate init() {}

    public init(toggleBetween: [LayoutDescription]) {
        self.toggleBetween = .initialized(toggleBetween)
    }

    public enum LayoutDescription: String, CaseIterable, Equatable {
        case accordion, tiles
        case horizontal, vertical
        case h_accordion, v_accordion, h_tiles, v_tiles
        case tiling, floating
    }
}

private func parseToggleBetween(arg: String, _ nextArgs: inout [String]) -> Parsed<[LayoutCmdArgs.LayoutDescription]> {
    var args: [String] = []
    args.append(arg)
    while let nextArg = nextArgs.nextNonFlagOrNil() {
        args.append(nextArg)
    }

    var result: [LayoutCmdArgs.LayoutDescription] = []
    for arg in args {
        if let layout = arg.parseLayoutDescription() {
            result.append(layout)
        } else {
            return .failure("Can't parse '\(arg)'\nPossible values: \(LayoutCmdArgs.LayoutDescription.unionLiteral)")
        }
    }

    return .success(result)
}

public func parseLayoutCmdArgs(_ args: [String]) -> ParsedCmd<LayoutCmdArgs> {
    parseRawCmdArgs(LayoutCmdArgs(), args).map {
        check(!$0.toggleBetween.val.isEmpty)
        return $0
    }
}

private extension String {
    func parseLayoutDescription() -> LayoutCmdArgs.LayoutDescription? {
        if let parsed = LayoutCmdArgs.LayoutDescription(rawValue: self) {
            return parsed
        } else if self == "list" {
            return .tiles
        } else if self == "h_list" {
            return .h_tiles
        } else if self == "v_list" {
            return .v_tiles
        }
        return nil
    }
}
