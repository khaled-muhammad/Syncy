package com.example.syncy

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val mediaExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingUpdateApk: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.syncy/media",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getVideoPaths") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val extensions = call.argument<List<String>>("extensions")
                ?.map { it.lowercase(Locale.ROOT) }
                ?.toSet()
                .orEmpty()

            mediaExecutor.execute {
                try {
                    val paths = queryVideoPaths(extensions)
                    mainHandler.post { result.success(paths) }
                } catch (error: Exception) {
                    mainHandler.post {
                        result.error("MEDIA_QUERY_FAILED", error.message, null)
                    }
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.syncy/update",
        ).setMethodCallHandler { call, result ->
            if (call.method != "installApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("INVALID_APK", "The update path is missing.", null)
                return@setMethodCallHandler
            }
            val apk = File(path)
            if (!apk.isFile || apk.extension.lowercase(Locale.ROOT) != "apk") {
                result.error("INVALID_APK", "The verified update is missing.", null)
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !packageManager.canRequestPackageInstalls()
            ) {
                pendingUpdateApk = apk.absolutePath
                runCatching {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                }.onSuccess {
                    result.success("permission_requested")
                }.onFailure { error ->
                    pendingUpdateApk = null
                    result.error("PERMISSION_SCREEN_FAILED", error.message, null)
                }
                return@setMethodCallHandler
            }

            runCatching { launchPackageInstaller(apk) }
                .onSuccess { result.success("launched") }
                .onFailure { error ->
                    result.error("INSTALLER_FAILED", error.message, null)
                }
        }
    }

    override fun onResume() {
        super.onResume()
        val path = pendingUpdateApk ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()
        ) {
            pendingUpdateApk = null
            val apk = File(path)
            if (apk.isFile) runCatching { launchPackageInstaller(apk) }
        }
    }

    private fun launchPackageInstaller(apk: File) {
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.update-files",
            apk,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun queryVideoPaths(supportedExtensions: Set<String>): List<String> {
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        }
        val projection = arrayOf(
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.DATE_ADDED,
        )
        val paths = LinkedHashSet<String>()
        val selection = "${MediaStore.Files.FileColumns.SIZE} > 0"

        contentResolver.query(
            uri,
            projection,
            selection,
            null,
            "${MediaStore.Files.FileColumns.DATE_ADDED} DESC",
        )?.use { cursor ->
            val pathColumn = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA)
            while (cursor.moveToNext()) {
                if (pathColumn < 0 || cursor.isNull(pathColumn)) continue
                val path = cursor.getString(pathColumn)
                val extension = path.substringAfterLast('.', "").lowercase(Locale.ROOT)
                if (!shouldSkipPath(path) &&
                    (supportedExtensions.isEmpty() || extension in supportedExtensions)
                ) {
                    paths.add(path)
                }
            }
        }

        return paths.toList()
    }

    private fun shouldSkipPath(path: String): Boolean {
        val normalized = path.replace('\\', '/').lowercase(Locale.ROOT)
        return listOf(
            "/android/data/",
            "/android/obb/",
            "/.thumbnails/",
            "/.cache/",
            "/.tmp/",
            "/node_modules/",
            "/.git/",
        ).any { normalized.contains(it) }
    }

    override fun onDestroy() {
        mediaExecutor.shutdownNow()
        super.onDestroy()
    }
}
