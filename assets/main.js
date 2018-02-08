'use strict';

var pages, assetsHash,

    app = {};

/*
 * If `compiled_pages.js` is loaded the `pages`
 *  variable will hold pages contens.
 */
app.pages = maybe(pages).getOrElse([]);

/*
 * If `assets_hash.js` is loaded, this will
 *  contain that hash.
 */
app.assetsHash = maybe(assetsHash).toString();

/*
 * Boolean flag, if set to `true` then `app.log`
 *  function will log its messages to the console.
 */
app.verbose = false;

/*
 * Shortcuts to global objects and functions.
 */
app.win = window;

app.doc = document;

app.root = app.doc.documentElement;

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
    underConstruction: app.doc.location.hostname === 'www.languefestival.it'
};

/*
 * Start Elm app.
 */
app.elm = Elm.App.fullscreen(app.flags);

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
app.cacheFunctionResult = function (fn) {
    var cached = function () {
        return cached.hasOwnProperty('result') ? cached.result : cached.result = fn();
    };

    cached.update = function () {
        return cached.result = fn();
    };

    return cached;
};

/*
 * Some DOM nodes are created when Elm app is started
 *  and never removed.
 *
 * In order to not call `getElementById` or `querySelector`
 *  every time one of these nodes are needed, we will use
 *  `app.cacheFunctionResult` to cache results.
 */
app.cache = {};

app.cache.elmRoot = app.cacheFunctionResult(function () {
    return app.getElementById('root-node');
});

app.cache.contentContainer = app.cacheFunctionResult(function () {
    return app.querySelector('.content-container');
});

app.cache.menu = app.cacheFunctionResult(function () {
    return app.getElementById('menu');
});

app.cache.headerContainer = app.cacheFunctionResult(function () {
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

    app.cache.elmRoot().forEach(function (elmRoot) { elmRoot.remove(); });

    observer.observe(app.root, { childList: true, subtree: true });

    app.flags.underConstruction = false;
    app.elm = Elm.App.fullscreen(app.flags);
};

/*
 * References to animate functions.
 */
app.animate = {};

/*
 * Scrolls the page to top with easing.
 */
app.animate.scrollTop = function (duration) {
    var time = 0,
        deltaTime = 20,

        yEnd = 0,
        yStart = app.root.scrollTop,
        yGap = yStart - yEnd;

    var interval = setInterval(function() {
        var timePercent = time / duration,
            //yPercent = (1 - Math.cos(Math.PI * timePercent)) / 2;
            yPercent = Math.pow((1 - Math.cos(Math.PI * timePercent)) / 2, 2);

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
    app.cache.elmRoot().forEach(function (elmRoot) {
        elmRoot.style.height = 'auto';
    });
    element.scrollIntoView(true);

    currentOffsetHeight = app.root.scrollTop + app.win.innerHeight;

    headerHeight = app.cache.headerContainer()
        .map(function (header) { return header.offsetHeight; })
        .getOrElse(0);

    if (currentOffsetHeight < app.root.offsetHeight) {
        app.root.scrollTop -= headerHeight;
    }
};

/*
 * Listen to the scroll event and pass the new yScroll
 *  value to the Elm app.
 */
app.doc.addEventListener('scroll', function(event) {
    app.elm.ports.notifyYScroll.send(app.root.scrollTop);
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

        element.forEach(function (e) { app.scrollToElement(e); });

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
 * Listen to clicks outside the menu area and send a message
 *  to Elm app through `notifyCloseMenu` port when happens.
 */
app.closeMenuListener = function (event) {
    var clickInsideMenu = app.cache.menu()
            .map(function (menu) { return menu.contains(event.target); })
            .getOrElse(false);

    if ( ! clickInsideMenu) {
        app.log('Click outside menu, sending close message');

        app.elm.ports.notifyCloseMenu.send(null);
        app.doc.removeEventListener('click', app.closeMenuListener, false);
    }
};

/*
 * Adds `app.closeMenuListener` to the event listener.
 */
app.elm.ports.startCloseMenuListener.subscribe(function () {
    var menuHeight = app.cache.menu()
            .map(function (menu) { return menu.offsetHeight; })
            .getOrElse(0),

        headerHeight = app.cache.headerContainer()
            .map(function (header) { return header.offsetHeight; })
            .getOrElse(0);

    app.doc.addEventListener('click', app.closeMenuListener, false);

    app.log('Opened responsive menu, locking root-node height');

    // locks page's height
    app.cache.elmRoot().forEach(function (elmRoot) {
        elmRoot.style.height = menuHeight + headerHeight + 'px';
    });
});

/*
 * Removes `app.closeMenuListener` from the event listener.
 */
app.elm.ports.stopCloseMenuListener.subscribe(function () {
    app.doc.removeEventListener('click', app.closeMenuListener, false);

    app.log('Closed responsive menu, unlocking root-node height');

    // unlocks page's height
    app.cache.elmRoot().forEach(function (elmRoot) {
        elmRoot.style.height = 'auto';
    });
});
