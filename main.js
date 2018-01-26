'use strict';

var rootNode

  , pages = pages || []

  , flags =
        { pages: pages
        , yScroll: document.documentElement.scrollTop
        }

  , app = Elm.App.fullscreen(flags);

// TODO bypass under-construction
var show = function () {
    flags.underConstruction = false;

    app = Elm.App.fullscreen(flags);
};

// TODO anchor handling
//var observer = new MutationObserver(function (mutations) {
//    mutations.forEach(function (mutation) {
//        var firstNode = mutation.addedNodes[0];
//        if (firstNode) {
//            console.log(mutation);
//        }
//    });
//});

//observer.observe(document.body, { childList : true });

/* Scroll handlers */
document.addEventListener('scroll', function(event) {
    app.ports.notifyYScroll.send(event.pageY); // TODO `document.documentElement.scrollTop` instead?
});

app.ports.scrollToTop.subscribe(function () {
    document.documentElement.scrollTop = 0;
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
});

app.ports.stopCloseMenuListener.subscribe(function () {
    document.removeEventListener('click', closeMenuListener, false);
});
