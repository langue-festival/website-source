'use strict';

var pages = pages || [],

    docElement = document.documentElement,

    flags = {
        pages: pages,
        yScroll: docElement.scrollTop,
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

var menu = cacheFunctionResult(function () {
   return document.getElementById('menu');
});

var headerContainer = cacheFunctionResult(function () {
   return document.querySelector('.header-container');
});

// TODO bypass under-construction
var show = function () {
    rootNode().remove();

    flags.underConstruction = false;
    app = Elm.App.fullscreen(flags);
};

/* Scroll handlers */
var animateScrollToTop = function (duration) {
    var time = 0,
        deltaTime = 20,

        yEnd = 0,
        yStart = docElement.scrollTop,
        yGap = yStart - yEnd,

        interval = setInterval(function() {
            var timePercent = time / duration,
                yPercent = (1 - Math.cos(Math.PI * timePercent)) / 2;

            if (yEnd == docElement.scrollTop) {
                clearInterval(interval);
            } else if (time >= duration) {
                docElement.scrollTop = yEnd;
                clearInterval(interval);
            } else {
                docElement.scrollTop = yStart - (yGap * yPercent);
                time += deltaTime;
            }

        }, deltaTime);
};

var scrollToElement = function (element) {
    if ( ! element) {
        return;
    }

    rootNode().style.height = 'auto';
    element.scrollIntoView(true);

    if (docElement.scrollTop + window.innerHeight < docElement.offsetHeight) {
        document.documentElement.scrollTop -= headerContainer().offsetHeight;
    }
};

document.addEventListener('scroll', function(event) {
    app.ports.notifyYScroll.send(document.documentElement.scrollTop);
});

app.ports.scrollIntoView.subscribe(function (id) {
    var element = document.getElementById(id),

        observer = new MutationObserver(function (mutations) {
            element = document.getElementById(id);
            scrollToElement(element);

            observer.disconnect();
        });

    if (element) {
        scrollToElement(element);
    } else {
        observer.observe(contentContainer(), { childList: true, subtree: true });
    }
});

app.ports.scrollToTop.subscribe(function () {
    docElement.scrollTop = 0;
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

    docElement.scrollTop = 0;
    setTimeout(function () {
        rootNode().style.height = menu().offsetHeight + headerContainer().offsetHeight + 'px';
    }, 500);
});

app.ports.stopCloseMenuListener.subscribe(function () {
    document.removeEventListener('click', closeMenuListener, false);

    rootNode().style.height = 'auto';
});
