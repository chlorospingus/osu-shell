import "." as Osu
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    NotificationServer {
        id: notificationServer
        onNotification: (notif) => {
            notif.tracked = true
            notifPopup.notify(notif)
        }
    }
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
    Osu.IpcToggle {
        target: "notifications"
        item: Osu.NotifCenter {
            tracked: notificationServer.trackedNotifications
        }
    }
    Osu.Notifs { id: notifPopup }
}
