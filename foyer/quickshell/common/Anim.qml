import QtQuick
import FoyerConfig 1.0

// The one animation implementation for the whole shell (BAR.md: one component
// per concern). Every animation in the bar, the launcher, the notifications and
// the OSD is an Anim, and no other file names a duration or an easing curve —
// those live in FoyerConfig `anim`, which is also where the families are
// described. Lives here rather than in bar/ because the app launcher is a
// separate quickshell instance and must not depend on the bar's module.
//
// Pick a family with `family`; the default suits opacity.
NumberAnimation {
    enum Family {
        Enter,
        Exit,
        Resize,
        Slide
    }

    property int family: Anim.Enter

    duration: {
        if (family === Anim.Resize)
            return Config.anim.resizeMs;
        if (family === Anim.Slide)
            return Config.anim.slideMs;
        if (family === Anim.Exit)
            return Config.anim.exitMs;
        return Config.anim.enterMs;
    }
    easing.bezierCurve: {
        if (family === Anim.Resize)
            return Config.anim.resizeCurve;
        if (family === Anim.Slide)
            return Config.anim.slideCurve;
        if (family === Anim.Exit)
            return Config.anim.exitCurve;
        return Config.anim.enterCurve;
    }
    easing.type: Easing.Bezier
}
