package org.monamienet.app

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
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
                "openBackgroundUsageSettings" -> result.success(openBackgroundUsageSettings())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Abre direto a tela "Uso da bateria pelo app" deste app. Retorna false
     * quando o aparelho não oferece essa tela, para o Dart abrir as
     * informações do app no lugar.
     *
     * Não passa pela tela de informações do app: no Android 15, o item "Uso
     * da bateria pelo app" de lá usa o UID guardado no histórico de bateria
     * das Configurações. Depois de desinstalar e reinstalar o app, esse UID é
     * o da instalação anterior, e o interruptor "Permitir o uso em segundo
     * plano" falha sem aviso (AppOps: "Cannot setMode"). Esta ação resolve o
     * UID atual com PackageManager.getPackageUid().
     */
    private fun openBackgroundUsageSettings(): Boolean {
        val intent = Intent(
            ACTION_VIEW_ADVANCED_POWER_USAGE_DETAIL,
            Uri.fromParts("package", packageName, null),
        ).addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                // A tela de bateria compartilha a afinidade de tarefa da tela
                // inicial das Configurações; sem MULTIPLE_TASK ela entraria
                // numa tarefa das Configurações já aberta, e o "voltar"
                // levaria para lá em vez de voltar ao MonAmie.
                Intent.FLAG_ACTIVITY_MULTIPLE_TASK or
                Intent.FLAG_ACTIVITY_NO_HISTORY or
                Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
        )
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    companion object {
        private const val BACKGROUND_RESTRICTION_CHANNEL = "monamie/background_restriction"

        // Ação não pública das Configurações do AOSP (Android 13+), tratada
        // por AdvancedPowerUsageDetailActivity.
        private const val ACTION_VIEW_ADVANCED_POWER_USAGE_DETAIL =
            "android.settings.VIEW_ADVANCED_POWER_USAGE_DETAIL"
    }
}
