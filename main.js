var app = Elm.App.fullscreen(),

    rootNode;

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
                    node.addEventListener('animationend', function(event) {
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
    var clickInside = document.getElementById('menu').contains(event.target);

    if ( ! clickInside) {
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
