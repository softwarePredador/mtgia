(function () {
  var isAndroid = /Android/i.test(navigator.userAgent);
  var platformId = isAndroid ? 'android' : 'ios';

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
  }

  function prepareAppBoot() {
    applyEmbeddedViewportFrame();
    requestAnimationFrame(function () {
      applyEmbeddedViewportFrame();
      setTimeout(fireDeviceReady, 0);
    });
  }

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
    }
  });
  window.addEventListener('resize', applyEmbeddedViewportFrame);
  window.addEventListener('orientationchange', applyEmbeddedViewportFrame);
})();
