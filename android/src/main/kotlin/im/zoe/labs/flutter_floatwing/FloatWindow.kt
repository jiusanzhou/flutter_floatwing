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
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@SuppressLint("ClickableViewAccessibility")
class FloatWindow(
    context: Context,
    wmr: WindowManager,
    engKey: String,
    eng: FlutterEngine,
    cfg: Config): View.OnTouchListener, MethodChannel.MethodCallHandler,
    BasicMessageChannel.MessageHandler<Any?> {

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

    lateinit var service: FloatwingService

    // method and message channel for window engine call
    var _channel: MethodChannel = MethodChannel(eng.dartExecutor.binaryMessenger,
        "${FloatwingService.METHOD_CHANNEL}/window").also {
        it.setMethodCallHandler(this) }
    var _message: BasicMessageChannel<Any?> = BasicMessageChannel(eng.dartExecutor.binaryMessenger,
        "${FloatwingService.MESSAGE_CHANNEL}/window_msg", JSONMessageCodec.INSTANCE)
        .also { it.setMessageHandler(this) }

    var _started = false

    fun init(): FloatWindow {
        config.focusable?.let{
            view.isFocusable = it
            view.isFocusableInTouchMode = it
        }

        config.visible?.let{ setVisible(it) }

        view.setOnTouchListener(this)

        view.setBackgroundColor(Color.TRANSPARENT)
        view.fitsSystemWindows = true

        // view.attachToFlutterEngine(engine)
        return this
    }

    fun destroy(force: Boolean = true): Boolean {
        Log.i(TAG, "destroy window: $key force: $force")

        // remote from manager must be first
        if (_started) wm.removeView(view)

        view.detachFromFlutterEngine()


        // TODO: should we stop the engine for flutter?
        if (force) {
            // stop engine and remove from cache
            FlutterEngineCache.getInstance().remove(engineKey)
            engine.destroy()
            service.windows.remove(key)
            emit("destroy", null)
        } else {
            _started = false
            engine.lifecycleChannel.appIsPaused()
            emit("paused", null)
        }
        return true
    }

    fun setVisible(visible: Boolean = true): Boolean {
        Log.d(TAG, "set window $key => $visible");
        emit("visible", visible)
        view.visibility = if (visible) View.VISIBLE else View.GONE
        return visible
    }

    fun update(cfg: Config): Map<String, Any?>? {
        Log.d(TAG, "update window $key => $cfg");
        config = config.update(cfg).also {
            layoutParams = it.to()
            if (_started) wm.updateViewLayout(view, layoutParams)
        }
        return toMap()
    }

    fun start(): Boolean {
        if (_started) {
            Log.d(TAG, "window $key already started")
            return true
        }

        _started = true
        Log.d(TAG, "start window: $key")

        engine.lifecycleChannel.appIsResumed()

        // if engine is paused, send re-render message
        // make sure reuse engine can be re-render
        emit("resumed")

        view.attachToFlutterEngine(engine)

        wm.addView(view, layoutParams)

        emit("started")

        return true
    }

    fun emit(name: String, data: Any? = null) {
        Log.i(TAG, "emit event: Window[$key] $name ")
        _channel.invokeMethod("window.$name", data)

        // we need to send to man engine
        service._channel.invokeMethod("window.$name", key)
    }

    fun toMap(): Map<String, Any?>? {
        // must not null if success created
        val map = HashMap<String, Any?>()
        map["id"] = key
        map["config"] = config.toMap()?.filter { it.value != null }
        return map
    }

    override fun toString(): String {
        return "${toMap()}"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // TODO: move window call from service to here
        return when (call.method) {
            "window.sync" -> {
                // when flutter is ready should call this to sync the window object.
                Log.i(TAG, "[window] window.sync from flutter side: $key")
                result.success(toMap())
            }
            "window.close" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.close request_id: $id, my_id: $key")
                val force = call.argument("force") ?: false
                return result.success(destroy(force))
            }
            "window.destroy" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.destroy request_id: $id, my_id: $key")
                return result.success(destroy(true))
            }
            "window.start" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.start request_id: $id, my_id: $key")
                return result.success(start())
            }
            "window.update" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.update request_id: $id, my_id: $key")
                val config = Config.from(call.argument<Map<String, *>>("config")!!)
                return result.success(update(config))
            }
            "window.show" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.show request_id: $id, my_id: $key")
                val visible = call.argument<Boolean>("visible") ?: true
                return result.success(setVisible(visible))
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onMessage(msg: Any?, reply: BasicMessageChannel.Reply<Any?>) {

    }

    override fun onTouch(p0: View?, p1: MotionEvent?): Boolean {
        return false
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
            val map = toMap()?.filter { it.value != null }
            return "$map"
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