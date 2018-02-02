'use strict';

var app = {};

/*
 * If `compiled_pages.js` is loaded the `pages`
 *  variable will hold pages contens
 */
app.pages = typeof pages === 'object' ? pages : [];

/*
 * Boolean flag, if set to `true` then `app.log`
 *  function will log its messages to the console
 */
app.verbose = false;

/*
 * Shortcuts to global objects and functions
 */
app.win = window;

app.doc = document;

app.root = app.doc.documentElement;

app.querySelector = function (query) {
    return app.doc.querySelector(query);
};

app.getElementById = function (id) {
    return app.doc.getElementById(id);
};

/*
 * Elm's app flags
 *
 * pages: contains page cache, if a page is not
 *  present here then Elm app will make a request
 *  to pages/page-name.md
 *
 * appVersion: for the moment this will just be used
 *  as query string in assets url to download latest versions
 *
 * yScroll: initial value of `document.documentElement.scrollTop`
 *
 * underConstruction: boolean flag, if `true` the website
 *  will not be shown
 */
app.flags = {
    pages: app.pages,
    appVersion: '0.0.2',
    yScroll: app.root.scrollTop,
    underConstruction: app.doc.location.hostname === 'www.languefestival.it'
};

/*
 * Start Elm app
 */
app.elm = Elm.App.fullscreen(app.flags);

/*
 * Will send messages to `console.log` if `app.verbose`
 *  is `true`
 * Calling `app.log()` will set the verbose flag to true
 */
app.log = function () {
    if (arguments.length === 0) {
        app.verbose = true;
    } else if (app.verbose === true) {
        console.log.apply(null, arguments);
    }
};

/*
 * Takes a function `fn1` as parameter and creates
 *  a new function `fn2`
 * The first time that fn2 gets called, fn1 will
 *  be called and its result is cached
 * If fn2 gets called again the last result will
 *  be returned without calling fn1
 * The function `fn2.update` will call fn1 again
 *  and caches the new result
 */
app.cacheFunctionResult = function (fn) {
    var result;

    var cachedFunction = function () {
        return typeof result === 'undefined' ? result = fn() : result;
    };

    cachedFunction.update = function () {
        return result = fn();
    };

    return cachedFunction;
};

/*
 * Some DOM nodes are created when Elm app is started
 *  and never removed
 * In order to not call `getElementById` every time
 *  one of these nodes are needed, we will use
 *  `app.cacheFunctionResult` to cache results
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
 *  in `app.cache`
 */
app.cache.update = function () {
    Object.keys(app.cache).forEach(function (key) {
        var update = app.cache[key].update;

        typeof update === 'function' && update();
    });
};

/*
 * Will set `app.underConstruction` flag to `false` and
 *  restart Elm app
 * At the moment Elm's ports will not be reattached so
 *  the website will not work correctly after this
 *  function gets called
 */
app.show = function () {
    var observer = new MutationObserver(function (mutations) {
        observer.disconnect();

        app.log('Updating app cached nodes');
        app.cache.update();
    });

    app.cache.elmRoot().remove();

    observer.observe(app.root, { childList: true, subtree: true });

    app.flags.underConstruction = false;
    app.elm = Elm.App.fullscreen(app.flags);
};

/*
 * References to animate functions
 */
app.animate = {};

/*
 * Scrolls the page to top with easing
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
 * Scrolls the page to the element
 * Then, if the page has not reached bottom,
 *  will scroll up as the header height
 */
app.scrollToElement = function (element) {
    if ( ! element) {
        return;
    }

    app.cache.elmRoot().style.height = 'auto';
    element.scrollIntoView(true);

    if (app.root.scrollTop + app.win.innerHeight < app.root.offsetHeight) {
        app.root.scrollTop -= app.cache.headerContainer().offsetHeight;
    }
};

/*
 * Listen to the scroll event and pass the new yScroll
 *  value to the Elm app
 */
app.doc.addEventListener('scroll', function(event) {
    app.elm.ports.notifyYScroll.send(app.root.scrollTop);
});

/*
 * Port through which Elm app will ask to scroll
 *  an element with a certain `id` into view
 * If the id doesn't exist when the port is called
 *  then an event listener will wait for any DOM
 *  mutation and then will try again
 */
app.elm.ports.scrollIntoView.subscribe(function (id) {
    var element = app.getElementById(id);

    var observer = new MutationObserver(function (mutations) {
        element = app.getElementById(id);

        app.log('DOM mutations:', mutations);
        app.log('Scrolling to id:', id, '- element:', element);

        app.scrollToElement(element);

        observer.disconnect();
    });

    if (element) {
        app.log('Scrolling to id:', id, ' - element:', element);

        app.scrollToElement(element);
    } else {
        app.log('Element with id', id, 'not found, waiting for DOM mutations...');

        observer.observe(app.cache.contentContainer(), { childList: true, subtree: true });
    }
});

/*
 * Port through which Elm app will ask to scroll
 *  to the top of the page
 */
app.elm.ports.scrollToTop.subscribe(function () {
    app.log('Scrolling to top');

    app.root.scrollTop = 0;
});

/*
 * Listen to clicks outside the menu area and send a message
 *  to Elm app through `notifyCloseMenu` port when happens
 */
app.closeMenuListener = function (event) {
    var clickInsideMenu = app.cache.menu().contains(event.target);

    if ( ! clickInsideMenu) {
        app.log('Click outside menu, sending close message');

        app.elm.ports.notifyCloseMenu.send(null);
        app.doc.removeEventListener('click', app.closeMenuListener, false);
    }
};

/*
 * Adds `app.closeMenuListener` to the event listener
 */
app.elm.ports.startCloseMenuListener.subscribe(function () {
    app.doc.addEventListener('click', app.closeMenuListener, false);

    app.log('Opened responsive menu, locking root-node height');

    // locks page's height
    app.cache.elmRoot().style.height = app.cache.menu().offsetHeight + app.cache.headerContainer().offsetHeight + 'px';
});

/*
 * Removes `app.closeMenuListener` from the event listener
 */
app.elm.ports.stopCloseMenuListener.subscribe(function () {
    app.doc.removeEventListener('click', app.closeMenuListener, false);

    app.log('Closed responsive menu, unlocking root-node height');

    /// unlocks page's height
    app.cache.elmRoot().style.height = 'auto';
});
