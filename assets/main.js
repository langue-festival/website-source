'use strict';

var pages = pages || [],

    flags = {
        pages: pages,
        yScroll: document.documentElement.scrollTop,
        underConstruction: document.location.hostname == 'www.languefestival.it'
    },

    app = Elm.App.fullscreen(flags);

var cacheFunctionResult = function (fn) {
    var result;

    return (function () {
        return result || (result = fn());
    });
};

var rootNode = cacheFunctionResult(function () {
    return document.getElementById('root-node');
});

var contentContainer = cacheFunctionResult(function () {
   return document.querySelector('.content-container');
});

var menuOffsetHeight = cacheFunctionResult(function () {
   return document.getElementById('menu').offsetHeight;
});

var headerContainerOffsetHeight = cacheFunctionResult(function () {
   return document.querySelector('.header-container').offsetHeight;
});

// TODO bypass under-construction
var show = function () {
    rootNode().remove();

    flags.underConstruction = false;
    app = Elm.App.fullscreen(flags);
};

/* Scroll handlers */
var scrollToTop = function (duration) {
    var time = 0,
        deltaTime = 20,

        yEnd = 0,
        yStart = document.documentElement.scrollTop,
        yGap = yStart - yEnd,

        interval = setInterval(function() {
            var timePercent = time / duration,
                yPercent = (1 - Math.cos(Math.PI * timePercent)) / 2;

            if (yEnd == document.documentElement.scrollTop) {
                clearInterval(interval);
            } else if (time >= duration) {
                document.documentElement.scrollTop = yEnd;
                clearInterval(interval);
            } else {
                document.documentElement.scrollTop = yStart - (yGap * yPercent);
                time += deltaTime;
            }

        }, deltaTime);
};

document.addEventListener('scroll', function(event) {
    app.ports.notifyYScroll.send(document.documentElement.scrollTop);
});

app.ports.scrollIntoView.subscribe(function (id) {
    var observer = new MutationObserver(function (mutations) {
        var element = document.getElementById(id);

        console.log(id, element);
        element && element.scrollIntoView(true);

        observer.disconnect();
    });

    observer.observe(contentContainer(), { childList: true });
});

app.ports.scrollToTop.subscribe(function () {
    scrollToTop(500);
});

/* Menu events handlers */
var closeMenuListener = function (event) {
    var clickInsideMenu = document.getElementById('menu').contains(event.target);

    if ( ! clickInsideMenu) {
        app.ports.notifyCloseMenu.send(null);
        document.removeEventListener('click', closeMenuListener, false);
    }
};

app.ports.startCloseMenuListener.subscribe(function () {
    document.addEventListener('click', closeMenuListener, false);

    scrollToTop(500);
    setTimeout(function () {
        rootNode().style.height = menuOffsetHeight() + headerContainerOffsetHeight() + 'px';
    }, 500);
});

app.ports.stopCloseMenuListener.subscribe(function () {
    document.removeEventListener('click', closeMenuListener, false);

    rootNode().style.height = 'auto';
});
