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
import org.json.JSONObject
import java.lang.Exception

/** FlutterFloatwingPlugin */
class FlutterFloatwingPlugin: FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

  private lateinit var mContext: Context
  private lateinit var mActivity: Activity
  private lateinit var channel : MethodChannel
  private lateinit var engine: FlutterEngine
  private lateinit var waitPermissionResult: Result

  private var serviceChannelInstalled = false
  private var isMain = false

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
      Log.d(TAG, "[plugin] on attached to window engine")
    } else {
      // update the main flag
      isMain = true
      // store the flutter engine @only main
      engine = binding.flutterEngine
      FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_CACHE_KEY, engine)
      // should install service handler for every engine? @only main
      // window has already set in this own logic
      serviceChannelInstalled = FloatwingService.installChannel(engine)
        .also { r -> if (!r) {
          MethodChannel(engine.dartExecutor.binaryMessenger,
            "${FloatwingService.METHOD_CHANNEL}/window").also { it.setMethodCallHandler(this) }
        } }

      Log.d(TAG, "[plugin] on attached to main engine")
    }
  }

  private fun saveSystemConfig(data: Map<*, *>?): Boolean {
    // if not exit should save
    val old =  mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
      .getString(SYSTEM_CONFIG_KEY, null)
    if (old != null) {
      Log.d(TAG, "[plugin] system config already exits: $old")
      return false
    }

    FloatwingService.instance?.systemConfig = data as Map<String, Any?>

    return try {
      val str = JSONObject(data).toString()
      // json encode map to string
      // try to save
      mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
        .putString(SYSTEM_CONFIG_KEY, str)
        .apply()
      true
    } catch (e: Exception) {
      e.printStackTrace()
      false
    }
  }

  private fun savePixelRadio(pixelRadio: Double): Boolean {
    val old = mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
      .getFloat(PIXEL_RADIO_KEY, 0F)
    if (old > 1F) {
      Log.d(TAG, "[plugin] pixel radio already exits")
      return false
    }

    FloatwingService.instance?.pixelRadio = pixelRadio

    // we need to save pixel radio
    Log.d(TAG, "[plugin] pixel radio need to be saved")
    mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
      .putFloat(PIXEL_RADIO_KEY, pixelRadio.toFloat())
      .apply()
    return true
  }

  private fun cleanCache(): Boolean {
    // delete all of cache files
    Log.w(TAG, "[plugin] will delete all of contents")
    mContext.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE).edit()
      .clear().apply()
    return true
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "plugin.initialize" -> {
        // the main engine should call initialize?
        // but the sub engine don't
        val pixelRadio = call.argument("pixelRadio") ?: 1.0
        val systemConfig = call.argument<Map<*, *>?>("system") as Map<*, *>

        val map = HashMap<String, Any?>()
        map["permission_grated"] = permissionGiven(mContext)
        map["service_running"] = FloatwingService.isRunning(mContext)
        map["windows"] = FloatwingService.instance?.windows?.map { it.value.toMap() }

        map["pixel_radio_updated"] = savePixelRadio(pixelRadio)
        map["system_config_updated"] = saveSystemConfig(systemConfig)

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
      // remove
      "plugin.create_window" -> {
        val id = call.argument<String>("id") ?: "default"
        val cfg = call.argument<Map<String, *>>("config")!!
        val start = call.argument<Boolean>("start") ?: false
        val config = FloatWindow.Config.from(cfg)
        return result.success(FloatwingService.createWindow(mContext, id, config, start, null))
      }
      "plugin.is_service_running" -> {
        return result.success(FloatwingService.isRunning(mContext))
      }
      "plugin.start_service" -> {
        return result.success(FloatwingService.isRunning(mContext)
          .or(FloatwingService.start(mContext)))
      }
      "plugin.clean_cache" -> {
        return result.success(cleanCache())
      }
      "plugin.sync_windows" -> {
        return result.success(FloatwingService.instance?.windows?.map { it.value.toMap() })
      }
      "window.sync" -> {
        Log.d(TAG, "[plugin] fake window.sync")
        return result.success(null)
      }
      else -> {
        Log.d(TAG, "[plugin] method ${call.method} not implement")
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

    Log.d(TAG, "[plugin] on attached to activity")

    // how to known are the main
     FloatwingService.onActivityAttached(mActivity)
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
    private const val TAG = "FloatwingPlugin"
    private const val CHANNEL_NAME = "im.zoe.labs/flutter_floatwing/method"
    private const val ALERT_WINDOW_PERMISSION = 1248

    const val FLUTTER_ENGINE_CACHE_KEY = "flutter_engine_main"
    const val SHARED_PREFERENCES_KEY = "flutter_floatwing_cache"
    const val CALLBACK_KEY = "callback_key"
    const val PIXEL_RADIO_KEY = "pixel_radio"
    const val SYSTEM_CONFIG_KEY = "system_config"

    fun permissionGiven(context: Context): Boolean {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Settings.canDrawOverlays(context)
      }
      return false
    }
  }
}
