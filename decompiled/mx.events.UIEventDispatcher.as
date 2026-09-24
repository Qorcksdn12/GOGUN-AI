if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.events) {
    _global.mx.events = new Object();
}
<UNDERFLOW>;
if (!_global.mx.events.UIEventDispatcher) {
    mx.events.UIEventDispatcher = _r1 = function () {
        super[undefined]();
    };
    mx.events.UIEventDispatcher.prototype = _r2 = new mx.events.EventDispatcher();
    _r1.addKeyEvents = function (obj) {
        if (obj.keyHandler == undefined) {
            obj.keyHandler = _r0 = new Object();
            _r1 = _r0;
            _r1.owner = obj;
            _r1.onKeyDown = mx.events.UIEventDispatcher._fEventDispatcher.onKeyDown;
            _r1.onKeyUp = mx.events.UIEventDispatcher._fEventDispatcher.onKeyUp;
        }
        Key.addListener(obj.keyHandler);
    };
    _r1.removeKeyEvents = function (obj) {
        Key.removeListener(obj.keyHandler);
    };
    _r1.addLoadEvents = function (obj) {
        if (obj.onLoad == undefined) {
            obj.onLoad = mx.events.UIEventDispatcher._fEventDispatcher.onLoad;
            obj.onUnload = mx.events.UIEventDispatcher._fEventDispatcher.onUnload;
            if (obj.getBytesTotal() == obj.getBytesLoaded()) {
                obj.doLater(obj, "onLoad");
            }
        }
    };
    _r1.removeLoadEvents = function (obj) {
        delete obj.onLoad;
        delete obj.onUnload;
    };
    _r1.initialize = function (obj) {
        if (mx.events.UIEventDispatcher._fEventDispatcher == undefined) {
            mx.events.UIEventDispatcher._fEventDispatcher = new mx.events.UIEventDispatcher();
        }
        obj.addEventListener = mx.events.UIEventDispatcher._fEventDispatcher.__addEventListener;
        obj.__origAddEventListener = mx.events.UIEventDispatcher._fEventDispatcher.addEventListener;
        obj.removeEventListener = mx.events.UIEventDispatcher._fEventDispatcher.removeEventListener;
        obj.dispatchEvent = mx.events.UIEventDispatcher._fEventDispatcher.dispatchEvent;
        obj.dispatchQueue = mx.events.UIEventDispatcher._fEventDispatcher.dispatchQueue;
    };
    _r2.dispatchEvent = function (eventObj) {
        if (eventObj.target == undefined) {
            eventObj.target = this;
        }
        this[eventObj.type + "Handler"](eventObj);
        this.dispatchQueue(mx.events.EventDispatcher, eventObj);
        this.dispatchQueue(this, eventObj);
    };
    _r2.onKeyDown = function (Void) {
        this.owner.dispatchEvent({type: "keyDown", code: Key.getCode(), ascii: Key.getAscii(), shiftKey: Key.isDown(16), ctrlKey: Key.isDown(17)});
    };
    _r2.onKeyUp = function (Void) {
        this.owner.dispatchEvent({type: "keyUp", code: Key.getCode(), ascii: Key.getAscii(), shiftKey: Key.isDown(16), ctrlKey: Key.isDown(17)});
    };
    _r2.onLoad = function (Void) {
        if (this.__sentLoadEvent != true) {
            this.dispatchEvent({type: "load"});
        }
        this.__sentLoadEvent = true;
    };
    _r2.onUnload = function (Void) {
        this.dispatchEvent({type: "unload"});
    };
    _r2.__addEventListener = function (event, handler) {
        this.__origAddEventListener(event, handler);
        _r3 = mx.events.UIEventDispatcher.lowLevelEvents;
        while ((_r0 = /*enum*/_r3) != null) {
            _r5 = _r0;
            if (mx.events.UIEventDispatcher[_r5][event] != undefined) {
                _r2 = _r3[_r5][0];
                mx.events.UIEventDispatcher[_r2](this);
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.removeEventListener = function (event, handler) {
        _r6 = "__q_" + event;
        mx.events.EventDispatcher._removeEventListener(this[_r6], event, handler);
        if (this[_r6].length == 0) {
            _r2 = mx.events.UIEventDispatcher.lowLevelEvents;
            while ((_r0 = /*enum*/_r2) != null) {
                _r5 = _r0;
                if (mx.events.UIEventDispatcher[_r5][event] != undefined) {
                    _r3 = _r2[_r5][1];
                    mx.events.UIEventDispatcher[_r2[_r5][1]](this);
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r1.keyEvents = {keyDown: 1, keyUp: 1};
    _r1.loadEvents = {load: 1, unload: 1};
    _r1.lowLevelEvents = {keyEvents: ["addKeyEvents", "removeKeyEvents"], loadEvents: ["addLoadEvents", "removeLoadEvents"]};
    _r1._fEventDispatcher = undefined;
}
ASSetPropFlags(mx.events.UIEventDispatcher.prototype, null, 1);