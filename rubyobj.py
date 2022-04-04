import requests
import types
from tools import object_map


class RubyBridge(object):
    @staticmethod
    def load(clazz):
        return BridgeClass().load(clazz)


class BridgeObject(object):
    def __init__(self, id_=None):
        self.id_ = id_ or id(self)
        self.isCalled = False
        self.session = requests.post

    def __getattr__(self, key):
        return BridgeDelayObject(self, key)

    def __setattr__(self, key, value):
        if key in ('id_', 'isCalled', 'session', 'value', 'class_name'):
            return object.__setattr__(self, key, value)
        change = {
            'action': 'instance_call',
            'key': f'{key}:',
            'args':  [encrypt_object(value)]
        }
        try:
            return decrypt_answer(self.call(change))
        except BridgeException as e:
            if e.class_name == 'MessageNotUnderstood':
                slot = getattr(self, "class").slotNamed(key)
                return slot.write(value, to=self)

    def __call__(self, *args, **kwargs):
        change = {
            'action': 'instance_call',
            'key': '__call__:',
            'args':  [encrypt_object(o) for o in args]
        }
        return decrypt_answer(self.call(change))

    def call(self, data):
        data["object_id"] = self.id_
        myid = self.id_
        answer = self.session(f"http://127.0.0.1:4567/{myid}", json=data)
        return answer.json()

    def __str__(self):
        change = {
            'action': 'instance_call',
            'key': 'to_s',
            'object_id': self.id_,
        }
        return decrypt_answer(self.call(change)).value

    def __del__(self):
        print("Object gc", self.id_)
        try:
            del object_map[self.id_]
        except Exception:
            pass
        delreq = {
            'action': 'instance_delete',
            'object_id': self.id_,
        }
        self.call(delreq)

    def resolve(self):
        return self

    def __add__(self, other):
        change = {
            'action': 'instance_call',
            'key': '+',
            'args': encrypt_object(other)
        }
        return decrypt_answer(self.call(change))

    def __getitem__(self, key):
        change = {
            'action': 'instance_call',
            'key': '[]',
            'args': encrypt_object(key)
        }
        return decrypt_answer(self.call(change))

    def __setitem__(self, key, value):
        change = {
            'action': 'instance_call',
            'key': '[]=',
            'args': [encrypt_object(key), encrypt_object(value)]
        }
        return decrypt_answer(self.call(change))


class BridgeClass(BridgeObject):
    def load(self, name):
        loadreq = {
            'action': 'get_class',
            'class_name': name,
        }
        clazz = self.call(loadreq)
        object_map[clazz["value"]["object_id"]] = self
        return self

    def __call__(self, *args, **kwargs):
        req = {
            'action': 'instance_call',
            'key': 'new',
        }
        return decrypt_answer(self.call(req))


class BridgeLiteral(BridgeObject):
    def __init__(self, value, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.value = value


class PharoLiteral(BridgeLiteral):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        req ={
            'action': 'register_literal',
            'value': self.value
        }
        object_map[self.id_] = self
        self.call(req)


class BridgeException(Exception, BridgeObject):
    def __init__(self, class_name, *args, **kwargs):
        Exception.__init__(self, *args, **kwargs)
        BridgeObject.__init__(self, *args, **kwargs)
        self.class_name = class_name
        print(self.id_)

class BridgeBlock(BridgeObject):
    def __call__(self, *args, **kwargs):
        if not args:
            req = {
                'action': 'instance_call',
                'key': 'value',
            }
            return decrypt_answer(self.call(req))
        req = {
            'action': 'instance_call',
            'key': 'valueWithArguments:',
            'args': [[encrypt_object(o) for o in args]]
        }
        return decrypt_answer(self.call(req))

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return types.MethodType(self, obj)


class BridgeDelayObject(object):
    def __init__(self, instance, key):
        self.instance = instance
        self.key = key

    # @property
    # def id_(self):
    #     return self.instance.id_

    @property
    def session(self):
        return self.instance.session

    def __setattr__(self, key, value):
        if key in ('instance', 'key', 'id_'):
            return object.__setattr__(self, key, value)
        left = self.resolve()
        return self(value)

    def __setitem__(self, key, value):
        change = {
            'action': 'instance_call',
            'key': 'at:put:',
            'args': [encrypt_object(key), encrypt_object(value)]
        }
        return decrypt_answer(self.instance.call(change))

    def perform_call(self, *args, **kwargs):
        change = {
            'action': 'instance_call',
            'key': self.key,
        }
        if args:
            args = {self.key + ':': encrypt_object(args[0])}
            for k, v in kwargs.items():
                args[k + ':'] = encrypt_object(v)
            change['args'] = args
            change['order'] = {(i + 1): k for i, k in enumerate(args.keys())}
        return decrypt_answer(self.instance.call(change))

    def call(self, *args, **kwargs):
        return self.instance.call(*args, **kwargs)

    def __call__(self, *args, **kwargs):
        return self.perform_call(*args, **kwargs)

    def resolve(self, delay_key=None):
        change = {
            'action': 'instance_call',
            'key': self.key
        }
        result = decrypt_answer(self.instance.call(change), delay_key)
        self.id_ = id(result)
        return result

    def __getattr__(self, key):
        return self.__class__(self.resolve(), key)

    def __add__(self, other):
        left = self.resolve()
        return left.__add__(other)

    def __str__(self):
        left = self.resolve()
        return left.__str__()

    # def __del__(self):
    #     print("Object gc", self.id_)
    #     try:
    #         del object_map[self.id_]
    #     except Exception:
    #         pass
    #     delreq = {
    #         'action': 'instance_delete',
    #         'object_id': self.id_,
    #     }
    #     self.call(delreq)


def decrypt_answer(d, delay_key=None):
    if isinstance(d, dict):
        return decrypt_map[d["kind"]](d, delay_key)
    return decrypt_literal({"value": d}, delay_key)

def decrypt_literal(d, delay_key):
    value = d["value"]
    o = BridgeLiteral(value=value)
    if delay_key:
        o = BridgeDelayObject(o, delay_key)
    object_map[o.id_] = o
    req ={
        'action': 'register_literal',
        'value': value
    }
    o.call(req)
    return o

def decrypt_object(d, delay_key):
    object_id = d["value"]["object_id"]
    if object_id not in object_map:
        o = BridgeObject()
        object_map[object_id] = o
        if delay_key:
            o = BridgeDelayObject(o, delay_key)
        req ={
            'python_id': object_id,
            'action': 'register_object',
        }
        o.call(req)
        return o
    return object_map[object_id]


def decrypt_class(d, delay_key):
    object_id = d["value"]["object_id"]
    if object_id not in object_map:
        o = BridgeClass()
        object_map[object_id] = o
        if delay_key:
            o = BridgeDelayObject(o, delay_key)
        req ={
            'python_id': object_id,
            'action': 'register_object',
        }
        o.call(req)
        return o
    return object_map[object_id]


def decrypt_block(d, delay_key):
    object_id = d["value"]["object_id"]
    if object_id not in object_map:
        o = BridgeBlock()
        object_map[object_id] = o
        if delay_key:
            o = BridgeDelayObject(o, delay_key)
        req ={
            'python_id': object_id,
            'action': 'register_object',
        }
        o.call(req)
        return o
    return object_map[object_id]


def decrypt_exception(d, delay_key):
    name = d['class']
    exception = BridgeException(name, "{}({})".format(name, d['args']))
    raise exception


decrypt_map = {
    "literal": decrypt_literal,
    "object": decrypt_object,
    "nil_object": lambda x, delay_key=None: None,
    "type": decrypt_class,
    "exception": decrypt_exception,
    "block": decrypt_block,
}

import server
from server import NIL_OBJECT, is_primitive

def encrypt_object(o):
    o = o.resolve() if isinstance(o, (BridgeObject, BridgeDelayObject)) else o
    response = {}
    if o is None:
        return NIL_OBJECT
    if isinstance(o, bytes):
        return o.decode('utf-8')
    if is_primitive(o):
        return o
    if o not in object_map:
        print('registering', o, id(o))
        object_map[id(o)] = o
    if isinstance(o, type):
        print('Its a type', object_map[o])
        return {"object_id": object_map[o]}
    return {"object_id": object_map[o]}




# Point = PharoBridge.load('Point')
# Smalltalk = PharoBridge.load('Smalltalk')
