private struct RawWorkspaceCmdArgs: RawCmdArgs {
    var target: Lateinit<RawWorkspaceTarget> = .uninitialized

    // direct workspace target OPTIONS
    var autoBackAndForth: Bool?

    // next|prev OPTIONS
    var wrapAroundNextPrev: Bool?

    static let parser: CmdParser<Self> = cmdParser(
        kind: .workspace,
        allowInConfig: true,
        help: """
              USAGE: workspace [-h|--help] [--wrap-around] (next|prev)
                 OR: workspace [-h|--help] [--auto-back-and-forth] <workspace-name>

              OPTIONS:
                -h, --help              Print help
                --auto-back-and-forth   Automatic 'back-and-forth' when switching to already
                                        focused workspace
                --wrap-around           Make it possible to jump between first and last workspaces
                                        using (next|prev)

              ARGUMENTS:
                <workspace-name>        Workspace name to focus
              """,
        options: [
            "--auto-back-and-forth": optionalTrueBoolFlag(\.autoBackAndForth),
            "--wrap-around": optionalTrueBoolFlag(\.wrapAroundNextPrev)
        ],
        arguments: [newArgParser(\.target, parseRawWorkspaceTarget, mandatoryArgPlaceholder: workspaceTargetPlaceholder)]
    )
}

public struct WorkspaceCmdArgs: CmdArgs, Equatable {
    public static let info: CmdStaticInfo = RawWorkspaceCmdArgs.info
    public let target: WTarget

    public init(_ target: WTarget) {
        self.target = target
    }
}

enum RawWorkspaceTarget: Equatable {
    case next
    case prev
    case workspaceName(String)

    func parse(wrapAround: Bool?, autoBackAndForth: Bool?) -> ParsedCmd<WTarget> {
        switch self {
        case .next:
            fallthrough
        case .prev:
            if autoBackAndForth != nil {
                return .failure("--auto-back-and-forth is not allowed for (next|prev)")
            }
            return .cmd(.relative(WTarget.Relative(isNext: self == .next, wrapAround: wrapAround ?? false)))
        case .workspaceName(let name):
            if wrapAround != nil {
                return .failure("--wrap-around is allowed only for (next|prev)")
            }
            return .cmd(.direct(WTarget.Direct(name: name, autoBackAndForth: autoBackAndForth ?? false)))
        }
    }
}

public enum WTarget: Equatable { // WorkspaceTarget
    //case back_and_forth // todo what about 'prev-focused'? todo at least the name needs to be reserved
    case direct(Direct)
    case relative(Relative)

    public struct Direct: Equatable {
        public let name: String
        public let autoBackAndForth: Bool

        public init(
            name: String,
            autoBackAndForth: Bool
        ) {
            self.name = name
            self.autoBackAndForth = autoBackAndForth
        }
    }

    public struct Relative: Equatable {
        public let isNext: Bool // next|prev
        public let wrapAround: Bool

        public init(
            isNext: Bool,
            wrapAround: Bool
        ) {
            self.isNext = isNext
            self.wrapAround = wrapAround
        }
    }

    public func workspaceNameOrNil() -> String? {
        if case .direct(let direct) = self {
            return direct.name
        } else {
            return nil
        }
    }
}

public func parseWorkspaceCmdArgs(_ args: [String]) -> ParsedCmd<WorkspaceCmdArgs> {
    parseRawCmdArgs(RawWorkspaceCmdArgs(), args)
        .flatMap { raw in raw.target.val.parse(wrapAround: raw.wrapAroundNextPrev, autoBackAndForth: raw.autoBackAndForth) }
        .flatMap { target in .cmd(WorkspaceCmdArgs(target)) }
}

let workspaceTargetPlaceholder = "(<workspace-name>|next|prev)"

func parseRawWorkspaceTarget(arg: String, nextArgs: inout [String]) -> Parsed<RawWorkspaceTarget> {
    switch arg {
    case "next":
        return .success(.next)
    case "prev":
        return .success(.prev)
    default:
        return .success(.workspaceName(arg))
    }
}
