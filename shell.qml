import "." as Osu
import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "launcher"
        function hide() {
            launcher.hide()
        }
        function show() {
            launcher.show()
        }
        function toggle() { launcher.visible ? hide() : show() }
    }
        
    Osu.Launcher {
        id: launcher
    }
}
