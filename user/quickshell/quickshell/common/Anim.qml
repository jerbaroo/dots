import QtQuick
import "../config.js" as Config

// The one animation implementation for the whole shell (BAR.md: one component
// per concern). Every animation in the bar, the launcher, the notifications and
// the OSD is an Anim, and no other file names a duration or an easing curve —
// those live in config.js `anim`, which is also where the families are
// described. Lives here rather than in bar/ because the app launcher is a
// separate quickshell instance and must not depend on the bar's module.
//
// Pick a family with `family`; the default suits opacity.
NumberAnimation {
    enum Family {
        Effect,
        EffectFast,
        Spatial,
        Travel
    }

    property int family: Anim.Effect

    duration: {
        if (family === Anim.Spatial)
            return Config.anim.spatialMs;
        if (family === Anim.Travel)
            return Config.anim.travelMs;
        if (family === Anim.EffectFast)
            return Config.anim.effectFastMs;
        return Config.anim.effectMs;
    }
    easing.bezierCurve: {
        if (family === Anim.Spatial)
            return Config.anim.spatialCurve;
        if (family === Anim.Travel)
            return Config.anim.travelCurve;
        return Config.anim.effectCurve;
    }
    easing.type: Easing.Bezier
}
