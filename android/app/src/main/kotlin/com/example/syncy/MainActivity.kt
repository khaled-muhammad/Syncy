package com.example.syncy

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val mediaExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

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
