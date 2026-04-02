(function () {
  var isAndroid = /Android/i.test(navigator.userAgent);
  var platformId = isAndroid ? 'android' : 'ios';
  var storageBridgeChannelName = 'FlutterManaLoomStorageBridge';
  var storagePersistDelayMs = 250;
  var storageBootstrapTimeoutMs = 500;
  var storagePersistTimer = null;
  var isApplyingStorageBootstrap = false;
  var resolveStorageBootstrap = null;
  var didResolveStorageBootstrap = false;
  var lotusRuntimeScriptPromise = null;

  window.cordova = window.cordova || {
    platformId: platformId,
    plugins: {},
  };
  window.plugins = window.plugins || {};
  window.cordova.plugins = window.cordova.plugins || {};
  window.cordova.plugins.AppReview =
    window.cordova.plugins.AppReview || {
      requestReview: function () {
        if (
          window.FlutterAppReviewBridge &&
          typeof window.FlutterAppReviewBridge.postMessage === 'function'
        ) {
          window.FlutterAppReviewBridge.postMessage('requestReview');
        }
      },
    };
  window.plugins.insomnia = window.plugins.insomnia || {
    keepAwake: function () {},
    allowSleepAgain: function () {},
  };
  window.device = window.device || {
    platform: isAndroid ? 'Android' : 'iOS',
  };
  window.StatusBar = window.StatusBar || {
    hide: function () {},
    styleDefault: function () {},
  };
  navigator.splashscreen = navigator.splashscreen || {
    hide: function () {},
  };
  var clipboardBridge = {
    writeText: function (text) {
      if (
        window.FlutterClipboardBridge &&
        typeof window.FlutterClipboardBridge.postMessage === 'function'
      ) {
        window.FlutterClipboardBridge.postMessage(String(text || ''));
      }
      return Promise.resolve();
    },
  };
  try {
    Object.defineProperty(navigator, 'clipboard', {
      value: clipboardBridge,
      configurable: true,
    });
  } catch (error) {
    navigator.clipboard = clipboardBridge;
  }

  function patchScreenDimension(key, fallbackGetter) {
    if (!window.screen) {
      return;
    }

    try {
      Object.defineProperty(window.screen, key, {
        configurable: true,
        get: fallbackGetter,
      });
    } catch (error) {}
  }

  function readViewportWidth() {
    return (
      window.innerWidth ||
      document.documentElement.clientWidth ||
      document.body.clientWidth ||
      0
    );
  }

  function readViewportHeight() {
    return (
      window.innerHeight ||
      document.documentElement.clientHeight ||
      document.body.clientHeight ||
      0
    );
  }

  function readEmbeddedWidth() {
    return readViewportWidth() || ((window.screen && window.screen.width) || 0);
  }

  function readEmbeddedHeight() {
    return (
      readViewportHeight() || ((window.screen && window.screen.height) || 0)
    );
  }

  function readScreenWidth() {
    return readEmbeddedWidth();
  }

  function readScreenHeight() {
    return readEmbeddedHeight();
  }

  function applyEmbeddedViewportFrame() {
    var width = readEmbeddedWidth();
    var height = readEmbeddedHeight();
    if (!width || !height) {
      return;
    }

    var targets = [document.documentElement, document.body];
    for (var i = 0; i < targets.length; i += 1) {
      var target = targets[i];
      if (!target) {
        continue;
      }

      target.style.width = width + 'px';
      target.style.minWidth = width + 'px';
      target.style.maxWidth = width + 'px';
      target.style.height = height + 'px';
      target.style.minHeight = height + 'px';
    }
  }

  patchScreenDimension('width', readViewportWidth);
  patchScreenDimension('height', readViewportHeight);
  patchScreenDimension('availWidth', readViewportWidth);
  patchScreenDimension('availHeight', readViewportHeight);

  function fireDeviceReady() {
    document.dispatchEvent(new Event('deviceready'));
    setTimeout(function () {
      queueStorageSnapshot('post_deviceready_sync');
    }, 1200);
  }

  function ensureLotusRuntimeScriptLoaded() {
    if (lotusRuntimeScriptPromise) {
      return lotusRuntimeScriptPromise;
    }

    lotusRuntimeScriptPromise = new Promise(function (resolve, reject) {
      var existingScript = document.querySelector(
        'script[data-manaloom-lotus-runtime="true"]'
      );
      if (existingScript) {
        resolve();
        return;
      }

      var runtimeScript = document.createElement('script');
      runtimeScript.src = 'js/app.min.js';
      runtimeScript.async = false;
      runtimeScript.dataset.manaloomLotusRuntime = 'true';
      runtimeScript.onload = function () {
        resolve();
      };
      runtimeScript.onerror = function (error) {
        lotusRuntimeScriptPromise = null;
        reject(error || new Error('Failed to load js/app.min.js'));
      };
      document.head.appendChild(runtimeScript);
    });

    return lotusRuntimeScriptPromise;
  }

  function getStorageBridgeChannel() {
    if (
      window[storageBridgeChannelName] &&
      typeof window[storageBridgeChannelName].postMessage === 'function'
    ) {
      return window[storageBridgeChannelName];
    }

    return null;
  }

  function postStorageBridgeMessage(payload) {
    var channel = getStorageBridgeChannel();
    if (!channel) {
      return false;
    }

    try {
      channel.postMessage(JSON.stringify(payload));
      return true;
    } catch (error) {
      return false;
    }
  }

  function snapshotLocalStorage() {
    var values = {};
    if (!window.localStorage) {
      return values;
    }

    try {
      for (var index = 0; index < window.localStorage.length; index += 1) {
        var key = window.localStorage.key(index);
        if (typeof key !== 'string') {
          continue;
        }

        var value = window.localStorage.getItem(key);
        if (value !== null) {
          values[key] = value;
        }
      }
    } catch (error) {}

    return values;
  }

  function queueStorageSnapshot(reason) {
    if (isApplyingStorageBootstrap) {
      return;
    }

    clearTimeout(storagePersistTimer);
    storagePersistTimer = setTimeout(function () {
      postStorageBridgeMessage({
        type: 'persist_snapshot',
        reason: reason || 'unknown',
        values: snapshotLocalStorage(),
      });
    }, storagePersistDelayMs);
  }

  function resolveStorageBootstrapHandshake() {
    if (didResolveStorageBootstrap) {
      return;
    }

    didResolveStorageBootstrap = true;
    if (typeof resolveStorageBootstrap === 'function') {
      resolveStorageBootstrap();
      resolveStorageBootstrap = null;
    }
  }

  function applyStorageBootstrapSnapshot(payload) {
    if (
      !payload ||
      payload.hasSnapshot !== true ||
      !payload.values ||
      !window.localStorage
    ) {
      return;
    }

    isApplyingStorageBootstrap = true;
    try {
      window.localStorage.clear();
      Object.keys(payload.values).forEach(function (key) {
        var value = payload.values[key];
        if (value === null || typeof value === 'undefined') {
          return;
        }

        window.localStorage.setItem(String(key), String(value));
      });
    } catch (error) {
    } finally {
      isApplyingStorageBootstrap = false;
    }
  }

  function applyStoragePatchSnapshot(payload) {
    if (!payload || !payload.values || !window.localStorage) {
      return { ok: false, reason: 'missing_values' };
    }

    isApplyingStorageBootstrap = true;
    try {
      Object.keys(payload.values).forEach(function (key) {
        var value = payload.values[key];
        if (value === null || typeof value === 'undefined') {
          window.localStorage.removeItem(String(key));
          return;
        }

        window.localStorage.setItem(String(key), String(value));
      });

      return { ok: true, patchedKeys: Object.keys(payload.values).length };
    } catch (error) {
      return {
        ok: false,
        reason: error && error.message ? String(error.message) : 'patch_failed',
      };
    } finally {
      isApplyingStorageBootstrap = false;
    }
  }

  function requestStorageBootstrapSnapshot() {
    return new Promise(function (resolve) {
      resolveStorageBootstrap = resolve;
      didResolveStorageBootstrap = false;

      if (
        !postStorageBridgeMessage({
          type: 'request_bootstrap',
        })
      ) {
        resolveStorageBootstrapHandshake();
        return;
      }

      setTimeout(resolveStorageBootstrapHandshake, storageBootstrapTimeoutMs);
    });
  }

  function patchStorageMutationMethods() {
    if (
      window.__ManaLoomLotusStoragePatched ||
      !window.Storage ||
      !window.Storage.prototype
    ) {
      return;
    }

    window.__ManaLoomLotusStoragePatched = true;
    ['setItem', 'removeItem', 'clear'].forEach(function (methodName) {
      var originalMethod = window.Storage.prototype[methodName];
      if (typeof originalMethod !== 'function') {
        return;
      }

      window.Storage.prototype[methodName] = function () {
        var result = originalMethod.apply(this, arguments);
        queueStorageSnapshot('local_storage_' + methodName);
        return result;
      };
    });
  }

  window.__ManaloomLotusStorageBridge =
    window.__ManaloomLotusStorageBridge || {
      receiveBootstrap: function (payload) {
        var decoded = payload;
        try {
          if (typeof payload === 'string') {
            decoded = JSON.parse(payload);
          }
        } catch (error) {
          decoded = null;
        }

        applyStorageBootstrapSnapshot(decoded);
        resolveStorageBootstrapHandshake();
      },
      receivePatch: function (payload) {
        var decoded = payload;
        try {
          if (typeof payload === 'string') {
            decoded = JSON.parse(payload);
          }
        } catch (error) {
          decoded = null;
        }

        return applyStoragePatchSnapshot(decoded);
      },
    };

  function prepareAppBoot() {
    applyEmbeddedViewportFrame();
    requestStorageBootstrapSnapshot().finally(function () {
      ensureLotusRuntimeScriptLoaded()
        .catch(function (error) {
          console.error('Failed to load Lotus runtime', error);
        })
        .finally(function () {
          requestAnimationFrame(function () {
            applyEmbeddedViewportFrame();
            setTimeout(fireDeviceReady, 0);
          });
        });
    });
  }

  patchStorageMutationMethods();

  if (document.readyState === 'loading') {
    document.addEventListener(
      'DOMContentLoaded',
      function () {
        prepareAppBoot();
      },
      { once: true }
    );
  } else {
    prepareAppBoot();
  }

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) {
      applyEmbeddedViewportFrame();
      document.dispatchEvent(new Event('resume'));
      return;
    }

    queueStorageSnapshot('document_hidden');
  });
  window.addEventListener('resize', applyEmbeddedViewportFrame);
  window.addEventListener('orientationchange', applyEmbeddedViewportFrame);
  window.addEventListener('pagehide', function () {
    queueStorageSnapshot('pagehide');
  });
  window.addEventListener('beforeunload', function () {
    queueStorageSnapshot('beforeunload');
  });
})();
