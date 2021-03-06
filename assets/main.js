/* global MutationObserver, Elm, maybe */

'use strict';

var pages, assetsHash;

var app = {};

/*
 * If `compiled_pages.js` is loaded the `pages`
 *  variable will hold pages contens.
 */
app.pages = maybe(pages).getOrElse([]);

/*
 * If `assets_hash.js` is loaded, this will
 *  contain that hash.
 */
app.assetsHash = maybe.string(assetsHash).toString();

/*
 * Boolean flag, if set to `true` then `app.log`
 *  function will log its messages to the console.
 */
app.verbose = false;

/*
 * Menu state.
 */
app.menuOpened = false;

/*
 * Shortcuts to global objects and functions.
 */
app.win = window;

app.doc = document;

app.root = app.doc.documentElement;

app.hostname = app.win.location.hostname;

/*
 * Wrapper of global function results in `maybe` monad.
 */
app.querySelector = function (query) {
  return maybe(app.doc.querySelector(query));
};

app.getElementById = function (id) {
  return maybe(app.doc.getElementById(id));
};

/*
 * Elm's app flags.
 *
 * pages: contains page cache, if a page is not
 *  present here then Elm app will make a request
 *  to pages/page-name.md.
 *
 * assetsHash: an hash of the application assets
 *  to make sure that the right version is loaded.
 *
 * yScroll: initial value of `document.documentElement.scrollTop`.
 *
 * underConstruction: boolean flag, if `true` the website
 *  will not be shown.
 */
app.flags = {
  pages: app.pages,
  assetsHash: app.assetsHash,
  yScroll: app.root.scrollTop,
  underConstruction: false
};

/*
 * Start Elm app.
 */
app.elmMount = app.getElementById('elm-mount').get();

app.elm = Elm.App.init({
  node: app.elmMount,
  flags: app.flags
});

/*
 * Will send messages to `console.log` if `app.verbose`
 *  is `true`.
 *
 * Calling `app.log()` will toggle `app.verbose`.
 */
app.log = function () {
  if (arguments.length === 0) {
    app.verbose = ! app.verbose;
  } else if (app.verbose === true) {
    console.log.apply(null, arguments);
  }

  return arguments[0];
};

/*
 * Takes a function fn as an argument and creates
 *  a cached version of that function.
 *
 * The first time that the cached function gets called,
 *  fn will be called, its result cached and then returned.
 *
 * If cached function gets called again the cached value
 *  is returned, without calling fn.
 *
 * The cached function also has a property `update` that
 *  contains a function that will update the cached value.
 */
function cacheFunctionResult (fn) {
  var empty = {}, result = empty;

  function cached () {
    return result === empty ? cached.update() : result;
  }

  cached.update = function () {
    return (result = fn());
  };

  return cached;
}

/*
 * Some DOM nodes are created when Elm app is started
 *  and never removed.
 *
 * In order to not call `getElementById` or `querySelector`
 *  every time one of these nodes are needed, we will use
 *  `cacheFunctionResult` to cache results.
 */
app.cache = {};

app.elmRoot = cacheFunctionResult(function () {
  return app.getElementById('root-node');
});

app.cache.metaDescription = cacheFunctionResult(function () {
  return app.getElementById('meta-description');
});

app.cache.contentContainer = cacheFunctionResult(function () {
  return app.querySelector('.content-container');
});

app.cache.menu = cacheFunctionResult(function () {
  return app.getElementById('menu');
});

app.cache.menuToggle = cacheFunctionResult(function () {
  return app.querySelector('.menu-toggle');
});

app.cache.headerContainer = cacheFunctionResult(function () {
  return app.querySelector('.header-container');
});

/*
 * Will call the update function for each object
 *  in `app.cache`.
 */
app.cache.update = function () {
  Object.keys(app.cache).forEach(function (key) {
    var update = app.cache[key].update;

    typeof update === 'function' && update();
  });
};

/*
 * Default values are stored here.
 */
app.default = {};

app.default.description =
    app.cache.metaDescription()
      .map(function (el) { return el.getAttribute('content') })
      .toString();

app.default.title = app.doc.title;

/*
 * Will set `app.underConstruction` flag to `false` and
 *  restart Elm app.
 *
 * At the moment Elm's ports will not be reattached so
 *  the website will not work correctly after this
 *  function gets called.
 */
app.show = function () {
  var observer = new MutationObserver(function (mutations) {
    observer.disconnect();

    app.log('Updating app cached nodes');
    app.cache.update();
  });

  observer.observe(app.root, { childList: true, subtree: true });

  app.flags.underConstruction = false;
  app.elm = Elm.App.init({
    node: app.elmMount,
    flags: app.flags
  });
};

/*
 * References to animate functions.
 */
app.animate = {};

/*
 * Scrolls the page to top with easing.
 */
app.animate.scrollTop = function (duration) {
  var time = 0;
  var deltaTime = 20;

  var yEnd = 0;
  var yStart = app.root.scrollTop;
  var yGap = yStart - yEnd;

  var interval = setInterval(function () {
    var timePercent = time / duration;
    // var yPercent = (1 - Math.cos(Math.PI * timePercent)) / 2;
    var yPercent = Math.pow((1 - Math.cos(Math.PI * timePercent)) / 2, 2);

    if (yEnd === app.root.scrollTop) {
      clearInterval(interval);
    } else if (time >= duration) {
      app.root.scrollTop = yEnd;
      clearInterval(interval);
    } else {
      app.root.scrollTop = yStart - yGap * yPercent;
      time += deltaTime;
    }
  }, deltaTime);
};

/*
 * Scrolls the page to the element.
 *
 * Then, if the page has not reached bottom,
 *  will scroll up as the header height.
 */
app.scrollToElement = function (element) {
  var currentOffsetHeight, headerHeight;

  // unlocks page's height
  app.elmRoot().forEach(function (elmRoot) {
    elmRoot.style.height = 'auto';
  });
  element.scrollIntoView(true);

  currentOffsetHeight = app.root.scrollTop + app.win.innerHeight;

  headerHeight = app.cache.headerContainer()
    .map(function (header) { return header.offsetHeight })
    .getOrElse(0);

  if (currentOffsetHeight < app.root.offsetHeight) {
    app.root.scrollTop -= headerHeight;
  }
};

/*
 * Listen to the scroll event and pass the new yScroll
 *  value to the Elm app.
 */
app.doc.addEventListener('scroll', function (event) {
  app.elm.ports.notifyYScroll.send(app.root.scrollTop);
});

/*
 * Port for dynamic meta description update.
 */
app.elm.ports.setMetaDescription.subscribe(function (desc) {
  var updatedDesc = maybe.string(desc).getOrElse(app.default.description);

  app.cache.metaDescription().forEach(function (el) {
    el.setAttribute('content', updatedDesc);
  });
});

/*
 * Port through which Elm app will ask to scroll
 *  an element with a certain `id` into view.
 *
 * If the id doesn't exist when the port is called
 *  then an event listener will wait for any DOM
 *  mutation and then will try again.
 */
app.elm.ports.scrollIntoView.subscribe(function (id) {
  var element = app.getElementById(id);

  var observer = new MutationObserver(function (mutations) {
    element = app.getElementById(id);

    app.log('DOM mutations:', mutations);
    app.log('Scrolling to id:', id, '- element:', element.getOrElse('not found'));

    element.forEach(function (e) { app.scrollToElement(e) });

    observer.disconnect();
  });

  element.forEach(function (el) {
    app.log('Scrolling to id:', id, ' - element:', el);

    app.scrollToElement(el);
  }).orElse(function () {
    app.log('Element with id', id, 'not found, waiting for DOM mutations...');

    app.cache.contentContainer().forEach(function (container) {
      observer.observe(container, { childList: true, subtree: true });
    });
  });
});

/*
 * Port through which Elm app will ask to scroll
 *  to the top of the page.
 */
app.elm.ports.scrollToTop.subscribe(function () {
  app.log('Scrolling to top');

  app.root.scrollTop = 0;
});

/*
 * Called from Elm app when menu is opened.
 */
app.elm.ports.menuOpened.subscribe(function () {
  var menuHeight = app.cache.menu()
    .map(function (menu) { return menu.offsetHeight })
    .getOrElse(0);

  var headerHeight = app.cache.headerContainer()
    .map(function (header) { return header.offsetHeight })
    .getOrElse(0);

  // locks page's height
  app.log('Opened responsive menu, locking root-node height');

  app.elmRoot().forEach(function (elmRoot) {
    elmRoot.style.height = menuHeight + headerHeight + 'px';
  });

  app.doc.addEventListener('click', menuCloseNotifier, false);

  app.menuOpened = true;
});

/*
 * Called from Elm app when menu is closed.
 */
app.elm.ports.menuClosed.subscribe(function () {
  app.log('Closed responsive menu, unlocking root-node height');

  // unlocks page's height
  app.elmRoot().forEach(function (elmRoot) {
    elmRoot.style.height = 'auto';
  });

  app.doc.removeEventListener('click', menuCloseNotifier, false);

  app.menuOpened = false;
});

function menuCloseNotifier (event) {
  var target = event.target;

  var clickInsideMenu = app.cache.menu()
    .map(function (menu) { return menu.contains(target) })
    .getOrElse(false);

  var clickInsideMenuToggle = app.cache.menuToggle()
    .map(function (toggle) { return toggle.contains(target) })
    .getOrElse(false);

  if (clickInsideMenu || clickInsideMenuToggle) {
    return;
  }

  app.log('Click outside menu, sending close message');

  app.elm.ports.notifyCloseMenu.send(null);
}
