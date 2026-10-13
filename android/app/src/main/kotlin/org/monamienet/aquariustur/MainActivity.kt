package org.monamienet.aquariustur

import android.app.ActivityManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Expõe ActivityManager.isBackgroundRestricted() ao Dart. Quando o app
        // está restrito em segundo plano, o Android remove o status de
        // foreground do serviço de rastreamento assim que o app sai da tela.
        //
        // Retorna true para qualquer modo do app-op RUN_ANY_IN_BACKGROUND
        // diferente de ALLOWED, inclusive DEFAULT — o que coincide com o que o
        // sistema aplica, mesmo quando as Configurações exibem o interruptor
        // "Permitir o uso em segundo plano" como ativado.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKGROUND_RESTRICTION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBackgroundRestricted" -> {
                    val restricted = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
                        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).isBackgroundRestricted
                    result.success(restricted)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val BACKGROUND_RESTRICTION_CHANNEL = "monamie/background_restriction"
    }
}
