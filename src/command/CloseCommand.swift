import Common

struct CloseCommand: Command {
    let info: CmdStaticInfo = CloseCmdArgs.info

    func _run(_ state: CommandMutableState, stdin: String) -> Bool {
        check(Thread.current.isMainThread)
        guard let window = state.subject.windowOrNil else {
            state.stdout.append("Empty workspace")
            return false
        }
        if window.close() {
            (window as! MacWindow).garbageCollect()
            if let focusedWindow {
                state.subject = .window(focusedWindow)
            } else {
                state.subject = .emptyWorkspace(focusedWorkspaceName)
            }
            return true
        } else {
            state.stdout.append("Can't close the window. Probably it doesn't have close button")
            return false
        }
    }
}
