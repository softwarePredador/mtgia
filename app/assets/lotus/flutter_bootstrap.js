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
      var currentValue = window.screen[key];
      if (typeof currentValue === 'number' && currentValue > 0) {
        return;
      }

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

  function readScreenWidth() {
    return (window.screen && window.screen.width) || readViewportWidth();
  }

  function readScreenHeight() {
    return (window.screen && window.screen.height) || readViewportHeight();
  }

  function applyEmbeddedViewportFrame() {
    var width = readScreenWidth();
    var height = readScreenHeight();
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
    };

  function prepareAppBoot() {
    applyEmbeddedViewportFrame();
    requestStorageBootstrapSnapshot().finally(function () {
      requestAnimationFrame(function () {
        applyEmbeddedViewportFrame();
        setTimeout(fireDeviceReady, 0);
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
