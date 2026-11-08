package kg.finansy.finansy

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val aliases = listOf("IconCoin", "IconBag", "IconPiggy", "IconCat")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "finansy/icon").setMethodCallHandler { call, result ->
            if (call.method == "setIcon") {
                val index = call.argument<Int>("index") ?: 0
                val pm = applicationContext.packageManager
                aliases.forEachIndexed { i, name ->
                    pm.setComponentEnabledSetting(
                        ComponentName(packageName, "kg.finansy.finansy.$name"),
                        if (i == index) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                }
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
