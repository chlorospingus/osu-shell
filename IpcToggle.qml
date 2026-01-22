import Quickshell.Io

IpcHandler {
    target: target
    required property var item
    function close() {
        item.close();
    }
    function open() {
        item.open();
    }
    function toggle() {
        item.toggle();
    }
}
