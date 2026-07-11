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
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Files.getContentUri("external")
        }
        val projection = arrayOf(
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.DATE_ADDED,
        )
        val paths = LinkedHashSet<String>()
        val extensionConditions = supportedExtensions.map {
            "${MediaStore.Files.FileColumns.DATA} LIKE ?"
        }
        val selection = buildString {
            append("${MediaStore.Files.FileColumns.SIZE} > 0 AND (")
            append("${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?")
            if (extensionConditions.isNotEmpty()) {
                append(" OR ")
                append(extensionConditions.joinToString(" OR "))
            }
            append(")")
        }
        val selectionArgs = buildList {
            add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            supportedExtensions.forEach { add("%.$it") }
        }.toTypedArray()

        contentResolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Files.FileColumns.DATE_ADDED} DESC",
        )?.use { cursor ->
            val pathColumn = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA)
            while (cursor.moveToNext()) {
                if (pathColumn < 0 || cursor.isNull(pathColumn)) continue
                val path = cursor.getString(pathColumn)
                val extension = path.substringAfterLast('.', "").lowercase(Locale.ROOT)
                if (supportedExtensions.isEmpty() || extension in supportedExtensions) {
                    paths.add(path)
                }
            }
        }

        return paths.toList()
    }

    override fun onDestroy() {
        mediaExecutor.shutdownNow()
        super.onDestroy()
    }
}
