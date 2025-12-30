import "." as Osu
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    readonly property var font: {
        family: "comfortaa"
    }
    Osu.IpcToggle {
        target: "launcher"
        item: Osu.Launcher {}
    }
    Osu.IpcToggle {
        target: "lock"
        item: Osu.Lock { }
    }
}
