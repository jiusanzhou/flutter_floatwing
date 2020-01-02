package im.zoe.labs.flutter_floatwing

import android.annotation.SuppressLint
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.Intent.ACTION_SHUTDOWN
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

class FloatwingService : MethodChannel.MethodCallHandler, BasicMessageChannel.MessageHandler<Any?>, Service() {

    private lateinit var mContext: Context
    private lateinit var windowManager: WindowManager

    private lateinit var engGroup: FlutterEngineGroup
    private lateinit var methodChannel: MethodChannel
    private lateinit var messageChannel: BasicMessageChannel<Any?>

    // store the window object use the id as key
    val windows = HashMap<String, FloatWindow>()

    override fun onCreate() {
        super.onCreate()

        mContext = applicationContext

        engGroup = FlutterEngineGroup(mContext)

        // set the instance
        instance = this

        Log.i(TAG, "the background service onCreate")

        // get the window manager and store
        (getSystemService(WINDOW_SERVICE) as WindowManager).also { windowManager = it }

        // install this method channel for the main engine
        FlutterEngineCache.getInstance().get(FlutterFloatwingPlugin.FLUTTER_ENGINE_CACHE_KEY)
            ?.also {
                Log.d(TAG, "install the service handler for main engine")
                installChannel(it)
            }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHUTDOWN -> {
                (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                    newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                        if (isHeld) release()
                    }
                }
                Log.d(TAG, "stop the background service!")
                stopSelf()
            }
            else -> {

            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()

        // clean up: remove all views in the window manager
        windows.forEach {
            it.value.destroy()
            Log.d(TAG, "service destroy: remove the float window ${it.key}")
        }

    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "service.stop_service" -> {
                Log.d(TAG, "stop the service")
                val closed = stopService(Intent(baseContext, this.javaClass))
                result.success(closed)
            }
            "service.close_window" -> {
                val id = call.argument<String>("id")!!
                val hard = call.argument<Boolean?>("hard")
                return result.success(closeWindow(id, hard))
            }
            "service.start_window" -> {
                val id = call.argument<String>("id") ?: "default"
                val cfg = call.argument<Map<String, *>>("config")!!
                val config = FloatWindow.Config.from(cfg)
                return result.success(startWindow(mContext, id, config))
            }
            "service.show_window" -> {
                val id = call.argument<String>("id")!!
                val visible = call.argument<Boolean>("visible") ?: true
                return result.success(showWindow(id, visible))
            }
            "service.update_window" -> {
                val id = call.argument<String>("id")!!
                val config = FloatWindow.Config.from(call.argument<Map<String, *>>("config")!!)
                return result.success(updateWindow(id, config))
            }
            "window.init" -> {
                return result.success(null);
            }
            else -> {
                Log.d(TAG, "unknown method ${call.method}")
                result.notImplemented()
            }
        }
    }

    override fun onMessage(message: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        // update the windows from message
    }

    private fun closeWindow(id: String, hard: Boolean?): Boolean {
        windows[id]?.destroy(hard = hard?:false) ?: return true.also {
            Log.d(TAG, "window with id $id already destroy")
        }
        windows.remove(id)
        Log.i(TAG, "close window with id $id $hard")
        return true
    }

    private fun startWindow(id: String, config: FloatWindow.Config): Map<String, Any?>? {
        // check if id exits
        if (windows.contains(id)) {
            Log.e(TAG, "window with id $id exits")
            return null
        }

        // get flutter engine
        val fKey = id.flutterKey()
        val eng = getFlutterEngine(fKey, config.entry, config.route)

        // use the callback to set window id for this engine
        // and then engine will take window object by call with this id

        /*
        val cbId = mContext.getSharedPreferences(FlutterFloatwingPlugin.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
            .getLong(FlutterFloatwingPlugin.CALLBACK_KEY, 0)
        if (cbId != 0L) {
            Log.d(TAG, "try to find callback and execute: $cbId")
            val info = FlutterCallbackInformation.lookupCallbackInformation(cbId)
            val callback = DartExecutor.DartCallback(mContext.assets, FlutterInjector.instance().flutterLoader().findAppBundlePath(), info)
            eng.dartExecutor.executeDartCallback(callback)
        } else {
            Log.e(TAG, "fatal: no callback register")
        }*/

        val svc = this

        Log.d(TAG, "start window: $id $config")

        return FloatWindow(mContext, windowManager, fKey, eng, config).apply {
            // set the channel for window engine
            methodChannel = MethodChannel(eng.dartExecutor.binaryMessenger, METHOD_CHANNEL).also {
                it.setMethodCallHandler(svc)
            }
            messageChannel = BasicMessageChannel(eng.dartExecutor.binaryMessenger, MESSAGE_CHANNEL, JSONMessageCodec.INSTANCE).also {
                it.setMessageHandler(svc)
            }
            customMethodChannel = MethodChannel(eng.dartExecutor.binaryMessenger,
                "$METHOD_CHANNEL/window").also {
                it.setMethodCallHandler(this)
            }

            key = id
        }.also {
            windows[it.key] = it
            it.start()
        }.toMap()
    }

    private fun showWindow(id: String, visible: Boolean): Boolean {
        return windows[id]?.let {
            it.setVisible(visible)
            return  true
        } ?: false
    }

    private fun updateWindow(id: String, config: FloatWindow.Config): Map<String, Any?>? {
        windows[id]?.let {
            Log.i(TAG, "update window $id config: $config")
            it.update(config)
            Log.d(TAG, "update window result: $it")
        }
        return  windows[id]?.toMap()
    }

    // this function is useful when we want to start service automatically
    private  fun getFlutterEngine(key: String, entry: String?, route: String?): FlutterEngine {
        // first take from cache
        var eng = FlutterEngineCache.getInstance().get(key)
        if (eng != null) {
            Log.i(TAG, "use the flutter exits in cache, id: $key")
            return eng
        }

        Log.d(TAG, "miss from cache need to ceate a new flutter engine")

        // then create a flutter engine

        // ensure initialization
        // FlutterInjector.instance().flutterLoader().startInitialization(mContext)
        // FlutterInjector.instance().flutterLoader().ensureInitializationComplete(mContext, arrayOf())

        var entry = entry
        if (entry==null) {
            // try use the main entrypoint
            entry = "main"
            Log.w(TAG, "recommend to use a entrypoint")
        }

        // check the main and default route
        if (entry == "main" && route == null) {
            Log.w(TAG, "use the main entrypoint and default route")
        }

        Log.i(TAG, "start flutter engine, id: $key entrypoint: $entry, route: $route")

        // make sure the entrypoint exits
        val entrypoint = DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), entry)

        // start the dart executor with special entrypoint
        eng = engGroup.createAndRunEngine(mContext, entrypoint, route)

        // store the engine to cache
        FlutterEngineCache.getInstance().put(key, eng)

        return eng
    }

    private fun installChannel(eng: FlutterEngine): Boolean {
        Log.d(TAG, "set service as bg_method and bg_message handler for $eng")

        // set the method and message channel
        methodChannel = MethodChannel(eng.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        messageChannel = BasicMessageChannel(eng.dartExecutor.binaryMessenger, MESSAGE_CHANNEL, JSONMessageCodec.INSTANCE)
        messageChannel.setMessageHandler(this)


        // todo avoid error
        MethodChannel(eng.dartExecutor.binaryMessenger, "$METHOD_CHANNEL/window").also {
            it.setMethodCallHandler(this)
        }
        return true
    }

    private fun String.flutterKey(): String {
        return FLUTTER_ENGINE_KEY + this
    }

    companion object {
        @JvmStatic
        private val TAG = "FloatwingService"

        @SuppressLint("StaticFieldLeak")
        var instance: FloatwingService? = null

        const val WAKELOCK_TAG = "FloatwingService::WAKE_LOCK"
        const val FLUTTER_ENGINE_KEY = "floatwing_flutter_engine_"
        const val METHOD_CHANNEL = "im.zoe.labs/flutter_floatwing/bg_method"
        const val MESSAGE_CHANNEL = "im.zoe.labs/flutter_floatwing/bg_message"

        fun closeWindow(id: String, hard: Boolean?): Boolean {
            Log.i(TAG, "close a window: $id")
            return instance?.closeWindow(id, hard) ?: false
        }

        fun startWindow(context: Context, id: String, config: FloatWindow.Config): Map<String, Any?>? {
            Log.i(TAG, "start a window: $config")
            // make sure the service started
            if (!ensureService(context)) return null

            // start the window
            return instance?.startWindow(id, config)
        }

        // ensure the service is started
        private fun ensureService(context: Context): Boolean {
            if (instance != null) return true

            // let's start the service

            // make sure we granted permission
            if (!FlutterFloatwingPlugin.permissionGiven(context)) {
                Log.e(TAG, "don't have permission to create overlay window")
                return false
            }

            // start the service
            val intent = Intent(context, FloatwingService::class.java)
            context.startService(intent)

            // TODO: start foreground service if need

            // TODO: waiting for service is running use a better way
            while (instance==null) {
                Log.d(TAG, "wait for service created")
                Thread.sleep(100 * 1)
                break
            }

            return true
        }

        fun installChannel(eng: FlutterEngine): Boolean {
            Log.i(TAG, "install the service channel for engine")
            return instance?.installChannel(eng) ?: false
        }

        fun isRunning(context: Context): Boolean {
            return Utils.getRunningService(context, FloatwingService::class.java) != null
        }

        fun start(context: Context): Boolean {
            return ensureService(context)
        }
    }
}