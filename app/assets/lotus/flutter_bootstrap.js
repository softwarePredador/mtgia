(function () {
  var isAndroid = /Android/i.test(navigator.userAgent);
  var platformId = isAndroid ? 'android' : 'ios';
  var storageBridgeChannelName = 'FlutterManaLoomStorageBridge';
  var storagePersistDelayMs = 250;
  var storageBootstrapRetryDelayMs = 500;
  var storageBootstrapMaxAttempts = 8;
  var storagePersistTimer = null;
  var storageBootstrapRetryTimer = null;
  var isApplyingStorageBootstrap = false;
  var resolveStorageBootstrap = null;
  var rejectStorageBootstrap = null;
  var didResolveStorageBootstrap = false;
  var didFailStorageBootstrap = false;
  var storageBridgeSessionId = createStorageBridgeId('session');
  var storageBootstrapRequestId = null;
  var storageBootstrapAttemptCount = 0;
  var storageRevision = 0;
  var storageSnapshotSequence = 0;
  var lotusRuntimeScriptPromise = null;

  window.cordova = window.cordova || {
    platformId: platformId,
    plugins: {},
  };
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

  function removeInactiveGameTimerState() {
    if (!window.localStorage) {
      return false;
    }

    try {
      var rawSettings = window.localStorage.getItem('gameSettings');
      if (!rawSettings) {
        return false;
      }

      var settings = JSON.parse(rawSettings);
      if (
        !settings ||
        settings.gameTimer !== false ||
        window.localStorage.getItem('gameTimerState') === null
      ) {
        return false;
      }

      // The preserved Lotus runtime creates gameTimerState unconditionally on
      // device-ready. Keep its internal boot behavior from leaking a hidden,
      // running timer when the feature is explicitly disabled.
      window.localStorage.removeItem('gameTimerState');
      return true;
    } catch (error) {
      return false;
    }
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
    removeInactiveGameTimerState();
    setTimeout(removeInactiveGameTimerState, 0);
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

  function createStorageBridgeId(prefix) {
    var randomPart = Math.random().toString(36).slice(2);
    return (
      String(prefix || 'bridge') +
      '-' +
      Date.now().toString(36) +
      '-' +
      randomPart
    );
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

  function flushStorageSnapshot(reason) {
    if (isApplyingStorageBootstrap || !didResolveStorageBootstrap) {
      return { ok: false, reason: 'bootstrap_pending' };
    }

    clearTimeout(storagePersistTimer);
    storagePersistTimer = null;
    storageSnapshotSequence += 1;
    var payload = {
      type: 'persist_snapshot',
      sessionId: storageBridgeSessionId,
      sequence: storageSnapshotSequence,
      baseRevision: storageRevision,
      reason: reason || 'unknown',
      values: snapshotLocalStorage(),
    };
    var didPost = postStorageBridgeMessage(payload);
    return {
      ok: didPost,
      reason: didPost ? null : 'storage_bridge_unavailable',
      payload: payload,
    };
  }

  function queueStorageSnapshot(reason) {
    if (isApplyingStorageBootstrap || !didResolveStorageBootstrap) {
      return;
    }

    clearTimeout(storagePersistTimer);
    storagePersistTimer = setTimeout(function () {
      flushStorageSnapshot(reason);
    }, storagePersistDelayMs);
  }

  function resolveStorageBootstrapHandshake() {
    if (didResolveStorageBootstrap) {
      return;
    }

    didResolveStorageBootstrap = true;
    clearTimeout(storageBootstrapRetryTimer);
    storageBootstrapRetryTimer = null;
    if (typeof resolveStorageBootstrap === 'function') {
      resolveStorageBootstrap();
      resolveStorageBootstrap = null;
    }
    rejectStorageBootstrap = null;
  }

  function failStorageBootstrapHandshake(reason) {
    if (didResolveStorageBootstrap || didFailStorageBootstrap) {
      return;
    }

    didFailStorageBootstrap = true;
    clearTimeout(storageBootstrapRetryTimer);
    storageBootstrapRetryTimer = null;
    postStorageBridgeMessage({
      type: 'bootstrap_failed',
      sessionId: storageBridgeSessionId,
      requestId: storageBootstrapRequestId,
      attempts: storageBootstrapAttemptCount,
      reason: reason || 'bootstrap_timeout',
    });
    if (typeof rejectStorageBootstrap === 'function') {
      rejectStorageBootstrap(
        new Error('Lotus storage bootstrap failed: ' + String(reason))
      );
      rejectStorageBootstrap = null;
    }
    resolveStorageBootstrap = null;
  }

  function isStorageRevision(value) {
    return (
      typeof value === 'number' &&
      isFinite(value) &&
      Math.floor(value) === value &&
      value >= 0
    );
  }

  function applyStorageBootstrapSnapshot(payload) {
    if (
      !payload ||
      !payload.values ||
      typeof payload.values !== 'object' ||
      !window.localStorage
    ) {
      return { ok: false, reason: 'missing_values' };
    }

    clearTimeout(storagePersistTimer);
    storagePersistTimer = null;
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
      return { ok: true, restoredKeys: Object.keys(payload.values).length };
    } catch (error) {
      return {
        ok: false,
        reason:
          error && error.message ? String(error.message) : 'bootstrap_failed',
      };
    } finally {
      isApplyingStorageBootstrap = false;
    }
  }

  function applyStoragePatchSnapshot(payload) {
    if (!payload || !payload.values || !window.localStorage) {
      return { ok: false, reason: 'missing_values' };
    }

    clearTimeout(storagePersistTimer);
    storagePersistTimer = null;
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

  function postStorageBootstrapRequest() {
    storageBootstrapAttemptCount += 1;
    return postStorageBridgeMessage({
      type: 'request_bootstrap',
      sessionId: storageBridgeSessionId,
      requestId: storageBootstrapRequestId,
    });
  }

  function scheduleStorageBootstrapRetry() {
    clearTimeout(storageBootstrapRetryTimer);
    storageBootstrapRetryTimer = setTimeout(function () {
      if (didResolveStorageBootstrap || didFailStorageBootstrap) {
        return;
      }
      if (storageBootstrapAttemptCount >= storageBootstrapMaxAttempts) {
        failStorageBootstrapHandshake('bootstrap_timeout');
        return;
      }

      postStorageBootstrapRequest();
      scheduleStorageBootstrapRetry();
    }, storageBootstrapRetryDelayMs);
  }

  function requestStorageBootstrapSnapshot() {
    return new Promise(function (resolve, reject) {
      resolveStorageBootstrap = resolve;
      rejectStorageBootstrap = reject;
      didResolveStorageBootstrap = false;
      didFailStorageBootstrap = false;
      storageBootstrapRequestId = createStorageBridgeId('bootstrap');
      storageBootstrapAttemptCount = 0;

      postStorageBootstrapRequest();
      scheduleStorageBootstrapRetry();
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

  function decodeStorageBridgePayload(payload) {
    var decoded = payload;
    try {
      if (typeof payload === 'string') {
        decoded = JSON.parse(payload);
      }
    } catch (error) {
      decoded = null;
    }
    return decoded;
  }

  window.__ManaloomLotusStorageBridge =
    window.__ManaloomLotusStorageBridge || {
      receiveBootstrap: function (payload) {
        var decoded = decodeStorageBridgePayload(payload);
        if (
          !decoded ||
          didResolveStorageBootstrap ||
          didFailStorageBootstrap ||
          decoded.sessionId !== storageBridgeSessionId ||
          decoded.requestId !== storageBootstrapRequestId ||
          !isStorageRevision(decoded.revision)
        ) {
          return { ok: false, reason: 'stale_bootstrap' };
        }

        var result = applyStorageBootstrapSnapshot(decoded);
        if (!result.ok) {
          return result;
        }

        storageRevision = decoded.revision;
        resolveStorageBootstrapHandshake();
        result.revision = storageRevision;
        return result;
      },
      receivePatch: function (payload) {
        if (!didResolveStorageBootstrap) {
          return { ok: false, reason: 'bootstrap_pending' };
        }

        var decoded = decodeStorageBridgePayload(payload);
        var result = applyStoragePatchSnapshot(decoded);
        if (!result.ok) {
          return result;
        }

        storageRevision += 1;
        result.revision = storageRevision;
        result.didNotifyHost = postStorageBridgeMessage({
          type: 'native_patch_applied',
          sessionId: storageBridgeSessionId,
          revision: storageRevision,
        });
        return result;
      },
      receiveRebase: function (payload) {
        var decoded = decodeStorageBridgePayload(payload);
        if (
          !decoded ||
          decoded.sessionId !== storageBridgeSessionId ||
          !isStorageRevision(decoded.revision)
        ) {
          return { ok: false, reason: 'stale_rebase' };
        }
        if (decoded.revision < storageRevision) {
          return { ok: false, reason: 'stale_rebase' };
        }

        var result = applyStorageBootstrapSnapshot(decoded);
        if (!result.ok) {
          return result;
        }

        storageRevision = decoded.revision;
        result.revision = storageRevision;
        if (decoded.reloadRuntime === true) {
          result.reloadScheduled = true;
          setTimeout(function () {
            window.location.reload();
          }, 0);
        }
        return result;
      },
      flushSnapshot: function (reason) {
        return flushStorageSnapshot(reason || 'host_flush');
      },
    };

  function prepareAppBoot() {
    applyEmbeddedViewportFrame();
    requestStorageBootstrapSnapshot()
      .then(function () {
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
      })
      .catch(function (error) {
        console.error('Failed to restore Lotus storage', error);
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

    flushStorageSnapshot('document_hidden');
  });
  window.addEventListener('resize', applyEmbeddedViewportFrame);
  window.addEventListener('orientationchange', applyEmbeddedViewportFrame);
  window.addEventListener('pagehide', function () {
    flushStorageSnapshot('pagehide');
  });
  window.addEventListener('beforeunload', function () {
    flushStorageSnapshot('beforeunload');
  });
})();
