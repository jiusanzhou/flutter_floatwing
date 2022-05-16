package im.zoe.labs.flutter_floatwing

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.Intent.ACTION_SHUTDOWN
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import im.zoe.labs.flutter_floatwing.Utils.Companion.toMap
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
import org.json.JSONObject
import java.lang.Exception

class FloatwingService : MethodChannel.MethodCallHandler, BasicMessageChannel.MessageHandler<Any?>, Service() {

    private lateinit var mContext: Context
    private lateinit var windowManager: WindowManager

    private lateinit var engGroup: FlutterEngineGroup

    lateinit var _channel: MethodChannel
    lateinit var _message: BasicMessageChannel<Any?>

    var subscribedEvents: HashMap<String, Boolean> = HashMap()

    var pixelRadio = 2.0
    var systemConfig = emptyMap<String, Any?>()

    // store the window object use the id as key
    val windows = HashMap<String, FloatWindow>()

    override fun onCreate() {
        super.onCreate()

        // set the instance
        instance = this

        mContext = applicationContext

        engGroup = FlutterEngineGroup(mContext)

        Log.i(TAG, "[service] the background service onCreate")

        // get the window manager and store
        (getSystemService(WINDOW_SERVICE) as WindowManager).also { windowManager = it }

        // load pixel from store
        pixelRadio = mContext.getSharedPreferences(FlutterFloatwingPlugin.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
            .getFloat(FlutterFloatwingPlugin.PIXEL_RADIO_KEY, 2F).toDouble()
        Log.d(TAG, "[service] load the pixel radio: $pixelRadio")

        // load system config from store
        try {
            val str = mContext.getSharedPreferences(FlutterFloatwingPlugin.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                .getString(FlutterFloatwingPlugin.SYSTEM_CONFIG_KEY, "{}")
            val map = JSONObject(str)
            systemConfig = map.toMap()
        }catch (e: Exception) {
            e.printStackTrace()
        }

        // install this method channel for the main engine
        FlutterEngineCache.getInstance().get(FlutterFloatwingPlugin.FLUTTER_ENGINE_CACHE_KEY)
            ?.also {
                Log.d(TAG, "[service] install the service handler for main engine")
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
                Log.d(TAG, "[service] stop the background service!")
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
            Log.d(TAG, "[service] service destroy: remove the float window ${it.key}")
        }

    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "service.stop_service" -> {
                Log.d(TAG, "[service] stop the service")
                val closed = stopService(Intent(baseContext, this.javaClass))
                return result.success(closed)
            }
            "service.promote" -> {
                Log.d(TAG, "[service] promote service")
                val map = call.arguments() as Map<*, *>
                return result.success(promoteService(map))
            }
            "service.demote" -> {
                Log.d(TAG, "[service] demote service")
                return result.success(demoteService())
            }
            "service.create_window" -> {
                val id = call.argument<String>("id") ?: "default"
                val cfg = call.argument<Map<String, *>>("config")!!
                val start = call.argument<Boolean>("start") ?: false
                val config = FloatWindow.Config.from(cfg)
                Log.d(TAG, "[service] window.create request_id: $id")
                return result.success(createWindow(mContext, id, config, start, null))
            }

            // call for windows
            "window.close" -> {
                val id = call.argument<String>("id")!!
                Log.d(TAG, "[service] window.close request_id: $id")
                val force = call.argument("force") ?: false
                return result.success(windows[id]?.destroy(force))
            }
            "window.start" -> {
                val id = call.argument<String>("id") ?: "default"
                Log.d(TAG, "[service] window.start request_id: $id ${windows[id]}")
                return result.success(windows[id]?.start())
            }
            "window.show" -> {
                val id = call.argument<String>("id")!!
                val visible = call.argument("visible") ?: true
                Log.d(TAG, "[service] window.show request_id: $id")
                return result.success(windows[id]?.setVisible(visible))
            }
            "window.update" -> {
                val id = call.argument<String>("id")!!
                Log.d(TAG, "[service] window.update request_id: $id")
                val config = FloatWindow.Config.from(call.argument<Map<String, *>>("config")!!)
                return result.success(windows[id]?.update(config))
            }
            "window.sync" -> {
                Log.d(TAG, "[service] fake window.sync")
                return result.success(null)
            }
            "data.share" -> {
                // communicate with other window, only 1 - 1 with id
                val args = call.arguments as Map<*, *>
                val targetId = call.argument<String?>("target")
                Log.d(TAG, "[service] share data from <plugin> with $targetId: $args")
                if (targetId == null) {
                    Log.d(TAG, "[service] can't share data with self")
                    return result.error("no allow", "share data from plugin to plugin", "")
                }
                val target = windows[targetId]
                    ?: return result.error("not found", "target window $targetId not exits", "");
                return target.shareData(args, result=result)
            }
            else -> {
                Log.d(TAG, "[service] unknown method ${call.method}")
                result.notImplemented()
            }
        }
    }

    override fun onMessage(message: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        // update the windows from message
    }

    private fun promoteService(map: Map<*, *>): Boolean {
        Log.i(TAG, "[service] promote service to foreground")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.e(TAG, "[service] promoteToForeground need sdk >= 26")
            return false
        }

        /*
        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
                acquire()
            }
        }
         */

        val title = map["title"] as String? ?: "Floatwing Service"
        val description = map["description"] as String? ?: "Floatwing service is running"
        val showWhen = map["showWhen"] as Boolean? ?: false
        val ticker = map["ticker"] as String?
        val subText = map["subText"] as String?


        val channel = NotificationChannel("flutter_floatwing", "Floatwing Service", NotificationManager.IMPORTANCE_HIGH)
        val imageId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, "flutter_floatwing")
            .setContentTitle(title)
            .setContentText(description)
            .setShowWhen(showWhen)
            .setTicker(ticker)
            .setSubText(subText)
            .setSmallIcon(imageId)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        startForeground(1, notification)
        return true
    }

    private fun demoteService(): Boolean {
        Log.i(TAG, "[service] demote service to background")
        stopForeground(true)
        return true
    }

    private fun createWindow(id: String, config: FloatWindow.Config, start: Boolean = false,
        p: FloatWindow?): Map<String, Any?>? {
        // check if id exits
        if (windows.contains(id)) {
            Log.e(TAG, "[service] window with id $id exits")
            return null
        }

        // get flutter engine
        val fKey = id.flutterKey()
        val (eng, fromCache) = getFlutterEngine(fKey, config.entry, config.route, config.callback)

        val svc = this
        return FloatWindow(mContext, windowManager, fKey, eng, config).apply {
            key = id
            service = svc
            parent = p
            Log.d(TAG, "[service] set window as handler $METHOD_CHANNEL/window for $eng")
        }.init().also {
            Log.d(TAG, "[service] created window: $id $config")
            it.emit("created", !fromCache)
            windows[it.key] = it
            if (start) it.start()
        }.toMap()
    }

    // this function is useful when we want to start service automatically
    private  fun getFlutterEngine(key: String, entryName: String?, route: String?, callback: Long?): Pair<FlutterEngine, Boolean> {
        // first take from cache
        var eng = FlutterEngineCache.getInstance().get(key)
        if (eng != null) {
            Log.i(TAG, "[service] use the flutter exits in cache, id: $key")
            return Pair(eng, true)
        }

        Log.d(TAG, "[service] miss from cache need to create a new flutter engine")

        // then create a flutter engine

        // ensure initialization
        // FlutterInjector.instance().flutterLoader().startInitialization(mContext)
        // FlutterInjector.instance().flutterLoader().ensureInitializationComplete(mContext, arrayOf())

        // first let's use callback to start engine first
        if (callback!=null&&callback>0L) {
            Log.i(TAG, "[service] start flutter engine, id: $key callback: $callback")

            eng = FlutterEngine(mContext)
            val info = FlutterCallbackInformation.lookupCallbackInformation(callback)
            val args = DartExecutor.DartCallback(mContext.assets, FlutterInjector.instance().flutterLoader().findAppBundlePath(), info)
            // execute the callback function
            eng.dartExecutor.executeDartCallback(args)

            // store the engine to cache
            FlutterEngineCache.getInstance().put(key, eng)

            return Pair(eng, false)
        }

        var entry = entryName
        if (entry==null) {
            // try use the main entrypoint
            entry = "main"
            Log.w(TAG, "[service] recommend to use a entrypoint")
        }

        // check the main and default route
        if (entry == "main" && route == null) {
            Log.w(TAG, "[service] use the main entrypoint and default route")
        }

        Log.i(TAG, "[service] start flutter engine, id: $key entrypoint: $entry, route: $route")

        // make sure the entrypoint exits
        val entrypoint = DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), entry)

        // start the dart executor with special entrypoint
        eng = engGroup.createAndRunEngine(mContext, entrypoint, route)

        // store the engine to cache
        FlutterEngineCache.getInstance().put(key, eng)

        return Pair(eng, false)
    }

    // window engine won't call this, so just window method
    private fun installChannel(eng: FlutterEngine): Boolean {
        Log.d(TAG, "[service] set service as handler $METHOD_CHANNEL/window for $eng")
        // set the method and message channel
        // this must be same as window, because we use the same method to call invoke
        _channel = MethodChannel(eng.dartExecutor.binaryMessenger,
            "$METHOD_CHANNEL/window").also { it.setMethodCallHandler(this) }
        _message = BasicMessageChannel(eng.dartExecutor.binaryMessenger,
            "$METHOD_CHANNEL/window_msg", JSONMessageCodec.INSTANCE).also { it.setMessageHandler(this) }
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
        const val METHOD_CHANNEL = "im.zoe.labs/flutter_floatwing"
        const val MESSAGE_CHANNEL = "im.zoe.labs/flutter_floatwing"

        fun initialize(): Boolean {
            Log.i(TAG, "[service] initialize")
            return true
        }

        fun createWindow(context: Context, id: String, config: FloatWindow.Config,
                         start: Boolean = false, parent: FloatWindow?): Map<String, Any?>? {
            Log.i(TAG, "[service] create a window: $id $config")
            // make sure the service started
            if (!ensureService(context)) return null

            // start the window
            return instance?.createWindow(id, config, start, parent)
        }

        // ensure the service is started
        private fun ensureService(context: Context): Boolean {
            if (instance != null) return true

            // let's start the service

            // make sure we granted permission
            if (!FlutterFloatwingPlugin.permissionGiven(context)) {
                Log.e(TAG, "[service] don't have permission to create overlay window")
                return false
            }

            // start the service
            val intent = Intent(context, FloatwingService::class.java)
            context.startService(intent)

            // TODO: start foreground service if need

            // TODO: waiting for service is running use a better way
            while (instance==null) {
                Log.d(TAG, "[service] wait for service created")
                Thread.sleep(100 * 1)
                break
            }

            return true
        }

        fun installChannel(eng: FlutterEngine): Boolean {
            Log.i(TAG, "[service] install the service channel for engine")
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