'use strict';

var pages = pages || [],

    app = Elm.App.fullscreen({ pages: pages, firstAnimation: false }),

    rootNode;

// TODO anchor handling
//var observer = new MutationObserver(function (mutations) {
//    mutations.forEach(function (mutation) {
//        var firstNode = mutation.addedNodes[0];
//        if (firstNode) {
//            console.log(mutation);
//        }
//    });
//});

observer.observe(document.body, { childList : true });

function scrollToTop (route) {
    /*
     * We have to wait that the node with `enter-transition`
     * class is removed.
     * `document.getElementById(route).parentNode.scrollTop = 0`
     * has no effect now.
     */
    var observer;

    rootNode = rootNode || document.getElementById('root-node');

    observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.removedNodes.forEach(function (node) {
                var contentContainer;

                if (node.className.indexOf('enter-transition') !== -1) {
                    /*
                     * Now we can check `scrollTop` property and set it to 0
                     */
                    contentContainer = document.getElementById(route).parentNode;
                    (contentContainer.scrollTop > 0) && (contentContainer.scrollTop = 0);

                    observer.disconnect();
                }
            });
        });
    });

    observer.observe(rootNode, { childList: true });
}

app.ports.waitForTransitionEnd.subscribe(function (route) {
    /*
     * When this function gets called the interested node
     * isn't added yet, so we wait that a node with
     * `enter-transition` class is added to `root-node`.
     */
    var observer;

    rootNode = rootNode || document.getElementById('root-node');

    observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (node) {
                if (node.className.indexOf('enter-transition') !== -1) {
                    /*
                     * Now we can add the event listener to the node
                     * to notify the application when the animation ended.
                     */
                    node.addEventListener('animationend', function (event) {
                        /*
                         * When the animation ends we have to scroll page to top.
                         */
                        scrollToTop(route);

                        app.ports.notifyTransitionEnd.send(null);
                    }, false);

                    observer.disconnect();
                }
            });
        });
    });

    /*
     * The node with `enter-transition` class is
     * direct child of `root-node`.
     */
    observer.observe(rootNode, { childList: true });
});

function closeMenuListener (event) {
    var clickInsideMenu = document.getElementById('menu').contains(event.target);

    if ( ! clickInsideMenu) {
        app.ports.notifyCloseMenu.send(null);
        document.removeEventListener('click', closeMenuListener, false);
    }
}

app.ports.startCloseMenuListener.subscribe(function () {
    document.addEventListener('click', closeMenuListener, false);
});

app.ports.stopCloseMenuListener.subscribe(function () {
    document.removeEventListener('click', closeMenuListener, false);
});
