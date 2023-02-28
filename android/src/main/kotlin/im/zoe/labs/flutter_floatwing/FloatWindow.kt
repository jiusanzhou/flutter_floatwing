package im.zoe.labs.flutter_floatwing

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
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

    var parent: FloatWindow? = null

    var config = cfg

    var key: String = "default"

    var engineKey = engKey
    var engine = eng

    var wm = wmr

    var subscribedEvents: HashMap<String, Boolean> = HashMap()

    var view: FlutterView = FlutterView(context, FlutterTextureView(context))

    lateinit var layoutParams: LayoutParams

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
        layoutParams = config.to()

        config.focusable?.let{
            view.isFocusable = it
            view.isFocusableInTouchMode = it
        }

        view.setBackgroundColor(Color.TRANSPARENT)
        view.fitsSystemWindows = true

        config.visible?.let{ setVisible(it) }

        view.setOnTouchListener(this)

        // view.attachToFlutterEngine(engine)
        return this
    }

    fun destroy(force: Boolean = true): Boolean {
        Log.i(TAG, "[window] destroy window: $key force: $force")

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
        Log.d(TAG, "[window] set window $key => $visible")
        emit("visible", visible)
        view.visibility = if (visible) View.VISIBLE else View.GONE
        return visible
    }

    fun update(cfg: Config): Map<String, Any?> {
        Log.d(TAG, "[window] update window $key => $cfg")
        config = config.update(cfg).also {
            layoutParams = it.to()
            if (_started) wm.updateViewLayout(view, layoutParams)
        }
        return toMap()
    }

    fun start(): Boolean {
        if (_started) {
            Log.d(TAG, "[window] window $key already started")
            return true
        }

        _started = true
        Log.d(TAG, "[window] start window: $key")

        engine.lifecycleChannel.appIsResumed()

        // if engine is paused, send re-render message
        // make sure reuse engine can be re-render
        emit("resumed")

        view.attachToFlutterEngine(engine)

        wm.addView(view, layoutParams)

        emit("started")

        return true
    }

    fun shareData(data: Map<*, *>, source: String? = null, result: MethodChannel.Result? = null) {
        shareData(_channel, data, source, result)
    }

    fun simpleEmit(msgChannel: BasicMessageChannel<Any?>, name: String, data: Any?=null) {
        val map = HashMap<String, Any?>()
        map["name"] = name
        map["id"] = key // this is special for main engine
        map["data"] = data
        msgChannel.send(map)
    }

    fun emit(name: String, data: Any? = null, prefix: String?="window", pluginNeed: Boolean = true) {
        val evtName = "$prefix.$name"
        // Log.i(TAG, "[window] emit event: Window[$key] $name ")

        // check if need to send to my self
        if (true||subscribedEvents.containsKey(name)||subscribedEvents.containsKey("*")) {
            // emit to window engine
            simpleEmit(_message, evtName, data)
        }

        // plugin
        // check if we need to fire to plugin
        if (pluginNeed&&(true||service.subscribedEvents.containsKey("*")||service.subscribedEvents.containsKey(evtName))) {
            simpleEmit(service._message, evtName, data)
        }

        // emit parent engine
        // if fire to parent need have no need to fire to service again
        if(parent!=null&&parent!=this) {
            parent!!.simpleEmit(parent!!._message, evtName, data)
        }

        // _channel.invokeMethod("window.$name", data)
        // we need to send to man engine
        // service._channel.invokeMethod("window.$name", key)
    }

    fun toMap(): Map<String, Any?> {
        // must not null if success created
        val map = HashMap<String, Any?>()
        map["id"] = key
        map["pixelRadio"] = service.pixelRadio
        map["system"] = service.systemConfig
        map["config"] = config.toMap().filter { it.value != null }
        return map
    }

    override fun toString(): String {
        return "${toMap()}"
    }

    // return window from svc.windows by id
    fun take(id: String): FloatWindow? {
        return service.windows[id]
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        return when (call.method) {
            // just take current engine's window
            "window.sync" -> {
                // when flutter is ready should call this to sync the window object.
                Log.i(TAG, "[window] window.sync from flutter side: $key")
                result.success(toMap())
            }

            // we need to support call window.* in window engine
            // but the window engine register as window channel
            // so we should take the id first and then get window from windows cache
            // TODO: those code should move to service

            "window.create_child" -> {
                val id = call.argument<String>("id") ?: "default"
                val cfg = call.argument<Map<String, *>>("config")!!
                val start = call.argument<Boolean>("start") ?: false
                val config = FloatWindow.Config.from(cfg)
                Log.d(TAG, "[service] window.create_child request_id: $id")
                return result.success(FloatwingService.createWindow(service.applicationContext, id,
                        config, start, this))
            }
            "window.close" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.close request_id: $id, my_id: $key")
                val force = call.argument("force") ?: false
                return result.success(take(id)?.destroy(force))
            }
            "window.destroy" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.destroy request_id: $id, my_id: $key")
                return result.success(take(id)?.destroy(true))
            }
            "window.start" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.start request_id: $id, my_id: $key")
                return result.success(take(id)?.start())
            }
            "window.update" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.update request_id: $id, my_id: $key")
                val config = Config.from(call.argument<Map<String, *>>("config")!!)
                return result.success(take(id)?.update(config))
            }
            "window.show" -> {
                val id = call.argument<String?>("id")?:"<unset>"
                Log.d(TAG, "[window] window.show request_id: $id, my_id: $key")
                val visible = call.argument<Boolean>("visible") ?: true
                return result.success(take(id)?.setVisible(visible))
            }
            "window.launch_main" -> {
                Log.d(TAG, "[window] window.launch_main")
                return result.success(service.launchMainActivity())
            }
            "window.lifecycle" -> {

            }
            "event.subscribe" -> {
                val id = call.argument<String?>("id")?:"<unset>"

            }
            "data.share" -> {
                // communicate with other window, only 1 - 1 with id
                val args = call.arguments as Map<*, *>
                val targetId = call.argument<String?>("target")
                Log.d(TAG, "[window] share data from $key with $targetId: $args")
                if (targetId == null) {
                    Log.d(TAG, "[window] share data with plugin")
                    return result.success(shareData(service._channel, args, source=key, result=result))
                }
                if (targetId == key) {
                    Log.d(TAG, "[window] can't share data with self")
                    return result.error("no allow", "share data from $key to $targetId", "")
                }
                val target = service.windows[targetId]
                    ?: return result.error("not found", "target window $targetId not exits", "");
                return target.shareData(args, source=key, result=result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onMessage(msg: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        // stream message
    }

    companion object {
        private const val TAG = "FloatWindow"

        fun shareData(channel: MethodChannel, data: Map<*, *>, source: String? = null,
                      result: MethodChannel.Result? = null): Any? {
            // id is the data comes from
            // invoke the method channel
            val map = HashMap<String, Any?>()
            map["source"] = source
            data.forEach { map[it.key as String] = it.value }
            channel.invokeMethod("data.share", map, result)
            // how to get data back
            return null
        }
    }

    // window is dragging
    private var dragging = false

    // start point
    private var lastX = 0f
    private var lastY = 0f

    // border around
    // TODO: support generate around edge

    override fun onTouch(view: View?, event: MotionEvent?): Boolean {
        // default draggable should be false
        if (config.draggable != true) return false
        when (event?.action) {
            MotionEvent.ACTION_DOWN -> {
                // touch start
                dragging = false
                lastX = event.rawX
                lastY = event.rawY
                // TODO: support generate around edge
            }
            MotionEvent.ACTION_MOVE -> {
                // touch move
                val dx = event.rawX - lastX
                val dy = event.rawY - lastY

                // ignore too small fist start moving(some time is click)
                if (!dragging && dx*dx+dy*dy < 25) {
                    return false
                }

                // update the last point
                lastX = event.rawX
                lastY = event.rawY

                val xx = layoutParams.x + dx.toInt()
                val yy = layoutParams.y + dy.toInt()

                if (!dragging) {
                    // first time dragging
                    emit("drag_start", listOf(xx, yy))
                }

                dragging = true
                // update x, y, need to update config so use config to update
                update(Config().apply {
                    // calculate with the border
                    x = xx
                    y = yy
                })

                emit("dragging", listOf(xx, yy))
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                // touch end
                if (dragging) emit("drag_end", listOf(event.rawX, event.rawY))
                return dragging
            }
            else -> {
                return false
            }
        }
        return false
    }

    class Config {
        // this three fields can not be changed
        // var id: String = "default"
        var entry: String? = null
        var route: String? = null
        var callback: Long? = null

        var autosize: Boolean? = null

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
                gravity = cfg.gravity ?: Gravity.TOP or Gravity.LEFT

                // default flags
                flags = FLAG_LAYOUT_IN_SCREEN or FLAG_NOT_TOUCH_MODAL
                // if immersion add flag no limit
                cfg.immersion?.let{ if (it) flags = flags or FLAG_LAYOUT_NO_LIMITS }
                // default we should be clickable
                // if not clickable, add flag not touchable
                cfg.clickable?.let{ if (!it) flags = flags or FLAG_NOT_TOUCHABLE }
                // default we should be no focusable
                if (cfg.focusable == null) { cfg.focusable = false }
                // if not focusable, add no focusable flag
                cfg.focusable?.let { if (!it) flags = flags or FLAG_NOT_FOCUSABLE }

                // default type is overlay
                type = cfg.type ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) TYPE_APPLICATION_OVERLAY else TYPE_PHONE
            }
        }

        fun toMap(): Map<String, Any?> {
            val map = HashMap<String, Any?>()
            map["entry"] = entry
            map["route"] = route
            map["callback"] = callback

            map["autosize"] = autosize

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

            cfg.autosize?.let { autosize = it }

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

                val int_callback = data["callback"] as Number?
                cfg.callback = int_callback?.toLong()

                cfg.autosize = data["autosize"] as Boolean?

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
