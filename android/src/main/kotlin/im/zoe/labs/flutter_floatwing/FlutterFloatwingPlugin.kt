package im.zoe.labs.flutter_floatwing

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

/** FlutterFloatwingPlugin */
class FlutterFloatwingPlugin: FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

  private lateinit var mContext: Context
  private lateinit var mActivity: Activity
  private lateinit var channel : MethodChannel
  private lateinit var engine: FlutterEngine
  private lateinit var waitPermissionResult: Result

  private var serviceChannelInstalled = false

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    mContext = binding.applicationContext

    // should window's engine install method channel?
    channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)

    // how to known i'm a window engine not the main one?
    // if contains engine already, means we are coming from window
    // TODO: take first engine as main, but if service auto start the window
    // this will cause error
    if (FlutterEngineCache.getInstance().contains(FLUTTER_ENGINE_CACHE_KEY)) {
      Log.d(TAG, "on attached to window engine")
    } else {
      // store the flutter engine @only main
      engine = binding.flutterEngine
      FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_CACHE_KEY, engine)
      // should install service handler for every engine? @only main
      // window has already set in this own logic
      serviceChannelInstalled = FloatwingService.installChannel(engine)

      Log.d(TAG, "on attached to main engine")
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "plugin.initialize" -> {
        // the main engine should call initialize?
        // but the sub engine don't
        val cbId = call.argument<Long>("callback")!!
        // store to share preference
        mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit().putLong(CALLBACK_KEY, cbId).apply()

        val map = HashMap<String, Any?>()
        map["permission_grated"] = permissionGiven(mContext)
        map["service_running"] = FloatwingService.isRunning(mContext)
        map["windows"] = FloatwingService.instance?.windows?.map { it.value.toMap() }

        return result.success(map)
      }
      "plugin.has_permission" -> {
        return result.success(permissionGiven(mContext))
      }
      "plugin.open_permission_setting" -> {
        return result.success(requestPermissions())
      }
      "plugin.grant_permission" -> {
        return grantPermission(result)
      }
      "plugin.create_window" -> {
        val id = call.argument<String>("id") ?: "default"
        val cfg = call.argument<Map<String, *>>("config")!!
        val start = call.argument<Boolean>("start") ?: false
        val config = FloatWindow.Config.from(cfg)
        return result.success(FloatwingService.createWindow(mContext, id, config, start))
      }
//      "plugin.start_window" -> {
//        val id = call.argument<String>("id") ?: "default"
//        return result.success(FloatwingService.startWindow(id))
//      }
      "plugin.is_service_running" -> {
        return result.success(FloatwingService.isRunning(mContext))
      }
      "plugin.start_service" -> {
        return result.success(FloatwingService.isRunning(mContext)
          .or(FloatwingService.start(mContext)))
      }
      else -> {
        Log.d(TAG, "method ${call.method} not implement")
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    mActivity = binding.activity

    // TODO: notify the window to show and return the result?

    Log.d(TAG, "on attached to activity")
  }

  override fun onDetachedFromActivityForConfigChanges() {

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    mActivity = binding.activity
  }

  override fun onDetachedFromActivity() {

  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == ALERT_WINDOW_PERMISSION) {
      waitPermissionResult.success(permissionGiven(mContext))
      return true
    }
    return false
  }

  private fun requestPermissions(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      mActivity.startActivityForResult(Intent(
        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
        Uri.parse("package:${mContext.packageName}")
      ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), ALERT_WINDOW_PERMISSION)
      return true
    }
    return false
  }

  private fun grantPermission(result: Result) {
    waitPermissionResult = result
    requestPermissions()
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(FlutterFloatwingPlugin())
    }

    private const val TAG = "FloatwingPlugin"
    private const val CHANNEL_NAME = "im.zoe.labs/flutter_floatwing/method"
    private const val ALERT_WINDOW_PERMISSION = 1248

    const val FLUTTER_ENGINE_CACHE_KEY = "flutter_engine_main"
    const val SHARED_PREFERENCES_KEY = "flutter_floatwing_cache"
    const val CALLBACK_KEY = "callback_key"

    fun permissionGiven(context: Context): Boolean {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Settings.canDrawOverlays(context)
      }
      return false
    }
  }
}
