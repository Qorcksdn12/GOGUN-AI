if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.events) {
    _global.mx.events = new Object();
}
<UNDERFLOW>;
if (!_global.mx.events.EventDispatcher) {
    mx.events.EventDispatcher = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1._removeEventListener = function (queue, event, handler) {
        if (queue != undefined) {
            _r4 = queue.length;
            _r1 = undefined;
            _r1 = 0;
            while (_r1 < _r4) {
                _r2 = queue[_r1];
                if (_r2 == handler) {
                    queue.splice(_r1, 1);
                    return undefined;
                }
                _r1 = _r1 + 1;
            }
        }
    };
    _r1.initialize = function (object) {
        if (mx.events.EventDispatcher._fEventDispatcher == undefined) {
            mx.events.EventDispatcher._fEventDispatcher = new mx.events.EventDispatcher();
        }
        object.addEventListener = mx.events.EventDispatcher._fEventDispatcher.addEventListener;
        object.removeEventListener = mx.events.EventDispatcher._fEventDispatcher.removeEventListener;
        object.dispatchEvent = mx.events.EventDispatcher._fEventDispatcher.dispatchEvent;
        object.dispatchQueue = mx.events.EventDispatcher._fEventDispatcher.dispatchQueue;
    };
    _r2.dispatchQueue = function (queueObj, eventObj) {
        _r7 = "__q_" + eventObj.type;
        _r4 = queueObj[_r7];
        if (_r4 != undefined) {
            _r5 = undefined;
            while ((_r0 = /*enum*/_r4) != null) {
                _r5 = _r0;
                _r1 = _r4[_r5];
                _r3 = typeof _r1;
                if (_r3 == "object" || _r3 == "movieclip") {
                    if (_r1.handleEvent != undefined) {
                        _r1.handleEvent(eventObj);
                    }
                    if (_r1[eventObj.type] != undefined) {
                        if (mx.events.EventDispatcher.exceptions[eventObj.type] == undefined) {
                            _r1[eventObj.type](eventObj);
                        }
                    }
                } else {
                    _r1.apply(queueObj, [eventObj]);
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.dispatchEvent = function (eventObj) {
        if (eventObj.target == undefined) {
            eventObj.target = this;
        }
        this[eventObj.type + "Handler"](eventObj);
        this.dispatchQueue(this, eventObj);
    };
    _r2.addEventListener = function (event, handler) {
        _r3 = "__q_" + event;
        if (this[_r3] == undefined) {
            this[_r3] = new Array();
        }
        _global.ASSetPropFlags(this, _r3, 1);
        mx.events.EventDispatcher._removeEventListener(this[_r3], event, handler);
        this[_r3].push(handler);
    };
    _r2.removeEventListener = function (event, handler) {
        _r2 = "__q_" + event;
        mx.events.EventDispatcher._removeEventListener(this[_r2], event, handler);
    };
    _r1._fEventDispatcher = undefined;
    _r1.exceptions = {move: 1, draw: 1, load: 1};
}
ASSetPropFlags(mx.events.EventDispatcher.prototype, null, 1);