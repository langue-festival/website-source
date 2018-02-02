'use strict';

var app = {};

app.pages = typeof pages === 'undefined' ? [] : pages;

app.verbose = false;

app.win = window;

app.doc = document;

app.root = app.doc.documentElement;

app.flags = {
    pages: app.pages,
    appVersion: '0.0.2',
    yScroll: app.root.scrollTop,
    underConstruction: app.doc.location.hostname === 'www.languefestival.it'
};

app.elm = Elm.App.fullscreen(app.flags);

app.querySelector = function (query) {
    return app.doc.querySelector(query);
};

app.getElementById = function (id) {
    return app.doc.getElementById(id);
};

app.log = function () {
    if (arguments.length === 0) {
        app.verbose = true;
    } else if (app.verbose === true) {
        console.log.apply(null, arguments);
    }
};

app.cacheFunctionResult = function (fn) {
    var result;

    var cachedFunction = function () {
        return result || (result = fn());
    };

    cachedFunction.update = function () {
        return result = fn();
    };

    return cachedFunction;
};

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

app.cache.update = function () {
    Object.keys(app.cache).forEach(function (key) {
        var update = app.cache[key].update;

        typeof update === 'function' && update();
    });
};

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


app.animate = {};

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

/* Scroll handlers */
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

app.doc.addEventListener('scroll', function(event) {
    app.elm.ports.notifyYScroll.send(app.root.scrollTop);
});

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

app.elm.ports.scrollToTop.subscribe(function () {
    app.log('Scrolling to top');

    app.root.scrollTop = 0;
});

/* Menu events handlers */
app.closeMenuListener = function (event) {
    var clickInsideMenu = app.cache.menu().contains(event.target);

    if ( ! clickInsideMenu) {
        app.log('Click outside menu, sending close message');

        app.elm.ports.notifyCloseMenu.send(null);
        app.doc.removeEventListener('click', app.closeMenuListener, false);
    }
};

app.elm.ports.startCloseMenuListener.subscribe(function () {
    app.doc.addEventListener('click', app.closeMenuListener, false);

    app.log('Opened responsive menu, locking root-node height');

    app.cache.elmRoot().style.height = app.cache.menu().offsetHeight + app.cache.headerContainer().offsetHeight + 'px';
});

app.elm.ports.stopCloseMenuListener.subscribe(function () {
    app.doc.removeEventListener('click', app.closeMenuListener, false);

    app.log('Closed responsive menu, unlocking root-node height');

    app.cache.elmRoot().style.height = 'auto';
});
