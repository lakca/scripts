const { EventEmitter } = require('events')

const storage = []

class Record {
  constructor(data) {
    this.key = data.key
    this.value = data.value
    this.scope = data.scope
    this.tag = data.tag
  }
}

class Store extends EventEmitter {
  constructor(opts = {}) {
    super()
    this._scope = opts.scope
    this._key = opts.key
    this._tag = opts.tag
    /** @type Record? */
    this._record = null
  }
  get record() {
    this._record = storage.find(e => {
      return ((this._scope == null && e.scope == null) || e.scope === this._scope) &&
        ((this._tag == null && e.tag == null) || e.tag === this._tag) &&
        ((this._key == null && e.key == null) || e.key === this._key)
    })
    return this._record
  }
  get records() {
    return storage.filter(e => {
      return (this._scope == null || e.scope === this._scope) &&
        (this._tag == null || e.tag === this._tag) &&
        (this._key == null || e.key === this._key)
    })
  }
  get value() {
    return this.record?.value
  }
  get values() {
    const value = this.value
    return value && Array.from(value) || []
  }
  _newRecord() {
    const record = new Record({ scope: this._scope, tag: this._tag, key: this._key })
    storage.push(record)
    return record
  }
  emitAsync(...args) {
    process.nextTick(() => {
      super.emit(...args)
    })
  }
  scope(name) {
    this._scope = name
    this._key = null
    this._tag = null
    return this
  }
  key(name) {
    this._key = name
    this._tag = null
    return this
  }
  tag(name) {
    this._tag = name
    return this
  }
  // k-set
  add(...value) {
    const record = this.record
    if (record) {
      for (const v of value) {
        if (record.value == null) {
          record.value = new Set()
        }
        const empty = !record.value.size
        record.value.add(v)
        empty && this.emitAsync('begin::record', record)
      }
    } else {
      const record = this._newRecord()
      this.add(...value)
      this.emitAsync('new::record', record)
    }
    return this
  }
  // k-v
  set(value) {
    const record = this.record
    if (record) {
      record.value = value
    } else {
      const record = this._newRecord()
      this.set(value)
      this.emitAsync('new::record', record)
    }
    return this
  }
  // k-set
  delete(...value) {
    const record = this.record
    if (record) {
      if (record.value != null) {
        for (const v of value) {
          record.value.delete(v)
        }
        if (!record.value.size) {
          this.emitAsync('empty::record', record)
        }
      }
    }
    return this
  }
  // k-v
  unset() {
    const record = this.record
    if (record) {
      record.value = null
      this.emitAsync('unset::record', record)
    }
    return this
  }
}

const store = new Store()

module.exports = store
