use cairo, gtk, deadlogger

// game deps
import Sprite
import game/[Level, Hero]
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 
import gtk/[Gtk, Widget, Window]
import gdk/[Event]
import structs/[ArrayList]
import zombieconfig

Keys: enum from UInt {
    LEFT  = 65361
    RIGHT = 65363
    SPACE = 32
}

MainUI: class {
    win: Window
    debug := false
    debugRender := false

    width, height: Int

    MAX_KEY := static 65536
    keyState: Bool*

    logger := static Log getLogger(This name)

    level: Level // current level being drawn

    campos := vec2(0.0, 0.0)
    mousepos := vec2(0.0, 0.0)
    mouseworldpos := vec2(0.0, 0.0)

    init: func (config: ZombieConfig) {
        keyState = gc_malloc(Bool size * MAX_KEY)
        win = Window new(config["title"])

        width  = config["screenWidth"] toInt()
        height = config["screenHeight"] toInt()
        win setUSize(width as GInt, height as GInt)
        win setPosition(Window POS_CENTER)

        win connect("delete-event", exit) // exit on window close

        // redraw on each window move, possibly before!
        win connect("expose-event", || draw())

        win addEvents(GdkEventMask POINTER_MOTION_MASK)
        win connectKeyEvent("key-press-event",     |ev| keyPressed (ev))
        win connectKeyEvent("key-release-event",   |ev| keyReleased(ev))
        win connectKeyEvent("motion-notify-event", |ev| mouseMoved(ev))

        win showAll()
    }

    run: func {
        Gtk main()
    }

    keyPressed: func (ev: EventKey*) {
        if(debug) {
            "Key pressed! it's state %d, key %u" printfln(ev@ state, ev@ keyval)
        }
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = true
        }
    }

    keyReleased: func (ev: EventKey*) {
        if(debug) {
            "Key released! it's state %d, key %u" printfln(ev@ state, ev@ keyval)
        }
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = false
        }
    }

    mouseMoved: func (ev: EventMotion*) {
        if(debug) {
            "Motion at (%.2f, %.2f)" printfln(ev@ x, ev@ y)
        }
        (mousepos x, mousepos y) = (ev@ x, ev@ y)
    }

    isPressed: func (keyval: Int) -> Bool {
        if (keyval >= MAX_KEY) {
            return false
        }
        keyState[keyval]
    }

    redraw: func {
        gdkWin := win getWindow()
        gdkWin invalidateRegion(gdkWin getClipRegion(), false)
    }

    draw: func {
        gdkWin := win getWindow()
        cr := GdkContext new(gdkWin)
        paint(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        camposTarget := level hero body pos sub(vec2(width / 2, height / 2))
        campos interpolate!(camposTarget, 0.2)
        cr translate (-campos x, -campos y)

        mouseworldpos x = mousepos x + campos x
        mouseworldpos y = mousepos y + campos y

        background(cr)

        // draw level
        if (level) {
            level bgSprites each(|sprite| sprite draw(cr))
            level sprites each(|sprite| sprite draw(cr))
            level fgSprites each(|sprite| sprite draw(cr))
            if(debug || debugRender) {
                level debugSprites each(|sprite| sprite draw(cr))
            }
        } else {
            logger error("No level set!")
        }

    }

    background: func (cr: Context) {
        cr setSourceRGB(0.1, 0.1, 0.1)
        cr paint()
    }

}
