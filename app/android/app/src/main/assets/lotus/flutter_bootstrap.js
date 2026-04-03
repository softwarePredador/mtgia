(function () {
  var isAndroid = /Android/i.test(navigator.userAgent);
  var platformId = isAndroid ? 'android' : 'ios';

  window.cordova = window.cordova || {
    platformId: platformId,
    plugins: {},
  };
  window.plugins = window.plugins || {};
  window.cordova.plugins = window.cordova.plugins || {};
  var embeddedAppReviewBridge = {
    requestReview: function () {
      if (
        window.FlutterAppReviewBridge &&
        typeof window.FlutterAppReviewBridge.postMessage === 'function'
      ) {
        window.FlutterAppReviewBridge.postMessage('requestReview');
      }
      return false;
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
      (window.visualViewport && window.visualViewport.width) ||
      window.innerWidth ||
      document.documentElement.clientWidth ||
      document.body.clientWidth ||
      0
    );
  }

  function readViewportHeight() {
    return (
      (window.visualViewport && window.visualViewport.height) ||
      window.innerHeight ||
      document.documentElement.clientHeight ||
      document.body.clientHeight ||
      0
    );
  }

  function readEmbeddedWidth() {
    return readViewportWidth();
  }

  function readEmbeddedHeight() {
    return readViewportHeight();
  }

  function suppressEmbeddedReviewPrompt() {
    try {
      window.localStorage.setItem('reviewPrompt', 'true');
    } catch (error) {}
  }

  function installEmbeddedAppReviewGuard() {
    window.cordova = window.cordova || {
      platformId: platformId,
      plugins: {},
    };
    window.cordova.plugins = window.cordova.plugins || {};

    try {
      Object.defineProperty(window.cordova.plugins, 'AppReview', {
        configurable: true,
        get: function () {
          return embeddedAppReviewBridge;
        },
        set: function () {},
      });
    } catch (error) {
      window.cordova.plugins.AppReview = embeddedAppReviewBridge;
    }
  }

  function applyEmbeddedViewportFrame() {
    var width = readEmbeddedWidth();
    var height = readEmbeddedHeight();
    if (!width || !height) {
      return;
    }

    document.documentElement.style.setProperty('--vw', width + 'px');
    document.documentElement.style.setProperty('--vh', height + 'px');

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
      target.style.maxHeight = height + 'px';
    }
  }

  patchScreenDimension('width', readEmbeddedWidth);
  patchScreenDimension('height', readEmbeddedHeight);
  patchScreenDimension('availWidth', readEmbeddedWidth);
  patchScreenDimension('availHeight', readEmbeddedHeight);

  function fireDeviceReady() {
    document.dispatchEvent(new Event('deviceready'));
  }

  function prepareAppBoot() {
    installEmbeddedAppReviewGuard();
    suppressEmbeddedReviewPrompt();
    applyEmbeddedViewportFrame();
    requestAnimationFrame(function () {
      installEmbeddedAppReviewGuard();
      applyEmbeddedViewportFrame();
      setTimeout(fireDeviceReady, 0);
    });
    setTimeout(installEmbeddedAppReviewGuard, 300);
    setTimeout(installEmbeddedAppReviewGuard, 1200);
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
      installEmbeddedAppReviewGuard();
      suppressEmbeddedReviewPrompt();
      applyEmbeddedViewportFrame();
      document.dispatchEvent(new Event('resume'));
    }
  });
  window.addEventListener('resize', applyEmbeddedViewportFrame);
  window.addEventListener('orientationchange', applyEmbeddedViewportFrame);
})();
