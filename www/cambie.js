var exec = require('cordova/exec');
var noop = function() { };

// No idea if this is still necessary...
/** Polyfill for the HTMLElement click() method. */
if (typeof HTMLElement !== 'undefined' && !HTMLElement.prototype.click) {
    HTMLElement.prototype.click = function() {
        var evt = this.ownerDocument.createEvent('MouseEvents');
        evt.initMouseEvent('click', true, true, this.ownerDocument.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        this.dispatchEvent(evt);
    }
}


// Hijack pushState
if (window.history.pushState) {
    var push = window.history.pushState;
    window.history.pushState = function(state, title, url) {
        push.apply(window.history, arguments);

        exec(noop, noop, 'Cambie', 'pushStack', [title || window.document.title]);
    }
}


// Hijack replaceState
if (window.history.replaceState) {
    var replace = window.history.replaceState;
    window.history.replaceState = function(state, title, url) {
        replace.apply(window.history, arguments);

        exec(noop, noop, 'Cambie', 'replaceStack', [title || window.document.title]);
    }
}

// Hijack popstate event
// Workaround the initial popstate after a refresh
var popped = ('state' in window.history);
var initialURL = location.href;

window.addEventListener('popstate', function(e) {
    var initialPop = (!popped && e.state == null) && location.href == initialURL;
    popped = true;
    if (initialPop) {
        return;
    }

    exec(noop, noop, 'Cambie', 'popStack', []);
});



var toolbar_visible = true;
var toolbar = {};

Object.defineProperty(toolbar, 'visible', {
    get: function() { return toolbar_visible; },
    set: function(value) {
        toolbar_visible = value;

        if (toolbar_visible) {
            exec(noop, noop, 'Cambie', 'show', []);
        } else {
            exec(noop, noop, 'Cambie', 'hide', []);
        }
    }
});
window.toolbar = toolbar;


// This is NOT a good solution, to be reviewed
var locationbar_visible = true;
var locationbar = {};

Object.defineProperty(locationbar, 'visible', {
    get: function() { return locationbar_visible; },
    set: function(value) {
        locationbar_visible = value;

        if (locationbar_visible) {
            exec(noop, noop, 'Cambie', 'enableNavigationLinks', []);
        } else {
            exec(noop, noop, 'Cambie', 'disableNavigationLinks', []);
        }
    }
});
window.locationbar = locationbar;
// end of NOT good solution


var MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;

var elTitle = document.querySelector('title');
if (elTitle) {
    var cfTitle = { characterData: true, childList: true, subtree: true, attributes: true };
    var fnTitle = function() {
        exec(noop, noop, 'Cambie', 'setTitle', [elTitle.textContent]);
    };
    var obTitle = new MutationObserver(fnTitle);

    obTitle.observe(elTitle, cfTitle);
    fnTitle();
}


var elColor = document.querySelector('meta[name="theme-color"]');
if (elColor) {
    var cfColor = { attributes: true, attributeFilter: ['content'] };
    var fnColor = function() {
        exec(noop, noop, 'Cambie', 'setColor', [elColor.getAttribute('content')]);
    };
    var obColor = new MutationObserver(fnColor);

    obColor.observe(elColor, cfColor);
    fnColor();
}


var elToolbar = document.querySelector('menu[type="toolbar"]');
if (elToolbar) {
    var cfToolbar = { attributes: true, childList: true, subtree: true };
    var fnToolbar = function() {
        var items = [];

        var children = elToolbar.querySelectorAll('a, button, input[type="button"]');
        for (var i = 0, ii = children.length; i < ii; ++i) {
            var child = children[i];

            var callbackId = 'ActionClick' + cordova.callbackId++;
            cordova.callbacks[callbackId] = {
                success:    (function(target) {
                                return function() { target.click(); }
                            })(child),

                error:      function(e) {
                                console.log(e);
                            }
            };

            items.push({
                label:      child.value || child.textContent,
                icon:       child.getAttribute('data-icon'),
                disabled:   !!child.hasAttribute('disabled'),
                primary:    !!child.hasAttribute('data-primary'),
                callback:   callbackId
            });
        }

        exec(noop, noop, 'Cambie', 'setToolbarActions', [items]);
    };
    var obToolbar = new MutationObserver(fnToolbar);

    obToolbar.observe(elToolbar, cfToolbar);
    fnToolbar();
}


var elNavbar = document.querySelector('nav[data-cambie-drawer] ul');
if (elNavbar) {
    var cfNavbar = { attributes: true, childList: true, subtree: true };
    var fnNavbar = function() {
        var items = [];

        var children = elNavbar.querySelectorAll('a, button, input[type="button"]');
        for (var i = 0, ii = children.length; i < ii; ++i) {
            var child = children[i];

            var callbackId = 'NavigationClick' + cordova.callbackId++;
            cordova.callbacks[callbackId] = {
                success:    (function(target) {
                                return function() { target.click(); }
                            })(child),

                error:      function(e) {
                                console.log(e);
                            }
            };

            items.push({
                label:      child.value || child.textContent,
                icon:       child.getAttribute('data-icon'),
                disabled:   !!child.hasAttribute('disabled'),
                callback:   callbackId
            });
        }

        exec(noop, noop, 'Cambie', 'setNavigationLinks', [items]);
    };
    var obNavbar = new MutationObserver(fnNavbar);

    obNavbar.observe(elNavbar, cfNavbar);
    fnNavbar();
}
