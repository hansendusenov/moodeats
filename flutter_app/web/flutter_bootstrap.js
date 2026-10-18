{{flutter_js}}
{{flutter_build_config}}

// Anti-Cache & Automatic Updates: Ensure browser never loads stale main.dart.js from disk cache
if (_flutter.buildConfig && _flutter.buildConfig.builds) {
  var cacheBuster = Date.now();
  _flutter.buildConfig.builds.forEach(function(b) {
    if (b.mainJsPath) {
      b.mainJsPath = b.mainJsPath + '?v=' + cacheBuster;
    }
  });
}

// Load Flutter without deprecated service worker caching
_flutter.loader.load({
  serviceWorkerSettings: null
});
