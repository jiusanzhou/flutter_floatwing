package im.zoe.labs.flutter_floatwing

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import android.view.WindowManager.LayoutParams.*
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception

@SuppressLint("ClickableViewAccessibility")
class FloatWindow(
    context: Context,
    wmr: WindowManager,
    engKey: String,
    eng: FlutterEngine,
    cfg: Config): View.OnTouchListener, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "FloatWindow"
    }

    var config = cfg

    var key: String = "default"

    var engineKey = engKey
    var engine = eng

    var wm = wmr

    var view: FlutterView = FlutterView(context, FlutterTextureView(context))
    var layoutParams: LayoutParams = config.to()

    lateinit var methodChannel: MethodChannel
    lateinit var messageChannel: BasicMessageChannel<Any?>
    lateinit var customMethodChannel: MethodChannel

    init {

        /*
        view.attachToFlutterEngine(engine)

        view.fitsSystemWindows = true
        view.isFocusable = true;
        view.isFocusableInTouchMode = true

        view.setBackgroundColor(Color.TRANSPARENT)
        view.setOnTouchListener(this)

        wm.addView(view, layoutParams)
         */
    }

    fun destroy(hard: Boolean = true) {
        Log.i(TAG, "destroy window: $key hard: $hard")

        // remote from manager must be first
        wm.removeView(view)
        view.detachFromFlutterEngine()

        // TODO: should we stop the engine for flutter?
        if (hard) {
            // stop engine and remove from cache
            FlutterEngineCache.getInstance().remove(engineKey)
            engine.destroy()
        } else {
            engine.lifecycleChannel.appIsPaused()
        }
    }

    fun setVisible(visible: Boolean = true) {
        view.visibility = if (visible) View.VISIBLE else View.GONE
    }

    fun update(cfg: Config): Boolean {
        config = config.update(cfg).also {
            layoutParams = it.to()
            wm.updateViewLayout(view, layoutParams)
        }
        return true
    }

    fun start(): Boolean {
        engine.lifecycleChannel.appIsResumed()
        // if engine is paused, send re-render message
        // make sure reuse engine can be re-render
        customMethodChannel.invokeMethod("window.resumed", null)

        view.attachToFlutterEngine(engine)

        // view.setZOrderMediaOverlay(true)
        // view.holder.setFormat(PixelFormat.TRANSPARENT)

        config.focusable?.let{
            view.isFocusable = it
            view.isFocusableInTouchMode = it
        }

        config.visible?.let{ setVisible(it) }

        view.setBackgroundColor(Color.TRANSPARENT)

        view.fitsSystemWindows = true

        view.setOnTouchListener(this)

        wm.addView(view, layoutParams)

        return true
    }

    fun initialize() {
        // send message to engine
        Log.i(TAG, "invoke window engine init: $key")
        customMethodChannel.invokeMethod("window.initialize", toMap())
    }

    fun toMap(): Map<String, Any?>? {
        // must not null if success created
        val map = HashMap<String, Any?>()
        map["id"] = key
        map["config"] = config.toMap()
        return map
    }

    override fun toString(): String {
        return "${toMap()}"
    }

    override fun onTouch(p0: View?, p1: MotionEvent?): Boolean {
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // just for init
        Log.i(TAG, "receive init from flutter side, let's send the window to flutter")
        result.success(toMap())
    }

    class Config {
        // this three fields can not be changed
        // var id: String = "default"
        var entry: String? = null
        var route: String? = null
        var callback: Long? = null

        var width: Int? = null
        var height: Int? = null
        var x: Int? = null
        var y: Int? = null

        var format: Int? = null
        var gravity: Int? = null
        var type: Int? = null

        var clickable: Boolean? = null
        var draggable: Boolean? = null
        var focusable: Boolean? = null

        var immersion: Boolean? = null

        var visible: Boolean? = null


        // inline fun <reified T: Any?>to(): T {
        fun to(): LayoutParams {
            val cfg = this
            return LayoutParams().apply {
                // set size
                width = cfg.width ?: 1 // we must have 1 pixel, let flutter can generate the pixel radio
                height = cfg.height ?: 1 // we must have 1 pixel, let flutter can generate the pixel radio

                // set position fixed if with (x, y)
                cfg.x?.let { x = it } // default not set
                cfg.y?.let { y = it } // default not set

                // format
                format = cfg.format ?: PixelFormat.TRANSPARENT

                // default start from center
                gravity = cfg.gravity ?: Gravity.CENTER

                // default flags
                flags = FLAG_LAYOUT_IN_SCREEN or FLAG_NOT_TOUCH_MODAL
                // if immersion add flag no limit
                cfg.immersion?.let{ if (it) flags = flags or FLAG_LAYOUT_NO_LIMITS }
                // if not clickable, add flag not touchable
                cfg.clickable?.let{ if (!it) flags = flags or FLAG_NOT_TOUCHABLE }
                // if focusable, add flag
                cfg.focusable?.let { if (!it) flags = flags or FLAG_NOT_FOCUSABLE }

                // default type is overlay
                type = cfg.type ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) TYPE_APPLICATION_OVERLAY else TYPE_PHONE
            }
        }

        fun toMap(): Map<String, Any?>? {
            val map = HashMap<String, Any?>()
            map["entry"] = entry
            map["route"] = route
            map["callback"] = callback

            map["width"] = width
            map["height"] = height
            map["x"] = x
            map["y"] = y

            map["format"] = format
            map["gravity"] = gravity
            map["type"] = type

            map["clickable"] = clickable
            map["draggable"] = draggable
            map["focusable"] = focusable

            map["immersion"] = immersion

            map["visible"] = visible

            return map
        }

        fun update(cfg: Config): Config {
            // entry, route, callback shouldn't be updated

            cfg.width?.let { width = it }
            cfg.height?.let { height = it }
            cfg.x?.let { x = it }
            cfg.y?.let { y = it }

            cfg.format?.let { format = it }
            cfg.gravity?.let { gravity = it }
            cfg.type?.let { type = it }

            cfg.clickable?.let{ clickable = it }
            cfg.draggable?.let { draggable = it }
            cfg.focusable?.let { focusable = it }

            cfg.immersion?.let { immersion = it }

            cfg.visible?.let { visible = it }

            return this
        }

        override fun toString(): String {
            return "${toMap()}"
        }

        companion object {

            fun from(data: Map<String, *>): Config {
                val cfg = Config()

                // (data["id"]?.let { it as String } ?: "default").also { cfg.id = it }
                cfg.entry = data["entry"] as String?
                cfg.route = data["route"] as String?
                cfg.callback = data["callback"] as Long?

                cfg.width = data["width"] as Int?
                cfg.height = data["height"] as Int?
                cfg.x = data["x"] as Int?
                cfg.y = data["y"] as Int?

                cfg.gravity = data["gravity"] as Int?
                cfg.format = data["format"] as Int?
                cfg.type = data["type"] as Int?

                cfg.clickable = data["clickable"] as Boolean?
                cfg.draggable = data["draggable"] as Boolean?
                cfg.focusable = data["focusable"] as Boolean?

                cfg.immersion = data["immersion"] as Boolean?

                cfg.visible = data["visible"] as Boolean?

                return cfg
            }
        }
    }

}