const timeout = 5000;

// The notification's actions that should be shown as buttons.
// 'actions' is a QML list, not a JS array, so iterate by index.
function buttonActions(n) {
    let result = [];
    if (!n) {
        return result;
    }
    for (let i = 0; i < n.actions.length; i++) {
        let a = n.actions[i];
        if (a.identifier !== "default" && a.text !== "") {
            result.push(a);
        }
    }
    return result;
}
