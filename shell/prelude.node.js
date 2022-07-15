const vm = require('vm')

const FILTERS = {
  date(date) {
    if (!date) return date
    date = new Date(date)
    date.setHours(date.getHours() + 8)
    return date.toISOString().slice(0, -5)
  },
  trim(s) {
    return typeof s === 'string' ? s.trim() : s
  },
  red(s) {
    return '\033[31m' + s + '\033[0m'
  },
  green(s) {
    return '\033[32m' + s + '\033[0m'
  },
  blue(s) {
    return '\033[33m' + s + '\033[0m'
  },
  align(rows, colKey) {
    const colMaxLengthList = []
    for (const row of rows) {
      for (const [i, col] of row.entries()) {
        if (colMaxLengthList[i] == void 0) {
          colMaxLengthList[i] = 0
        }
        const c = `${colKey ? col[colKey] : col}`
        if (c.length > colMaxLengthList[i]) {
          colMaxLengthList[i] = c.length
        }
      }
    }
    return rows.map(row => {
      return row.map((col, i) => {
        const c = `${colKey ? col[colKey] : col}`
        if (colKey) {
          const align = colMaxLengthList[i] - c.length
          return {
            _aligned: c + ' '.repeat(align),
            _align: align,
            ...col,
          }
        } else {
          return c + ' '.repeat(colMaxLengthList[i] - c.length)
        }
      })
    })
  },
  array(v) {
    return Array.isArray(v) ? v : [v]
  },
  jsonp(v, name) {
    const args = []
    vm.runInContext(v, vm.createContext({
      [name]: function() {
        args.push(...arguments)
      }
    }))
    return args.length > 1 ? args : args[0]
  },
  postfix(v, postfix) {
    return `${postfix}${v}`
  },
  suffix(v, suffix) {
    return `${v}${suffix}`
  }
}

function useGet(obj, prop) {
  if (prop) {
    for (const e of prop.split('.')) {
      if (obj == void 0) {
        return
      }
      obj = obj[e]
    }
  }
  return obj
}

/**
 * @param {*} data
 * @param {Array<string|function|array>} filters - type of array is used to providing extra arguments (from the second) to the filter: `[<filterName>, <arg1>, <arg2>...]`.
 * @returns
 */
function useFilter(data, ...filters) {
  return filters.reduce((r, f) => {
    if (typeof f === 'function') {
      return f(r)
    } else if (Array.isArray(f)) {
      return FILTERS[f[0]](r, ...f.slice(1))
    } else {
      return FILTERS[f](r)
    }
  }, data)
}

/**
 * @param {object} config
 * @param {*} config.data
 * @param {string} config.cols - format: 'iterKey:/fromRootCol1,/fromRootCol2,col1,col2|filter1|filter2,col3'
 * @param {string} [config.jsonp] - jsonp function name
 * @param {string} [config.iterKey]
 * @param {'table'|'th'|'list'} [config.format=th]
 * @param {boolean} [config.aligned]
 * @param {boolean} [config.colorful]
 */
function useJsonf(config) {
  const data = config.jsonp ? useFilter(config.data, ['jsonp', config.jsonp]) : config.data
  const iterFactors = config.cols.split(':')
    .map(col => col.trim())
  const keyPart = iterFactors.length > 1 ? iterFactors[1] : iterFactors[0]
  const iterKey = config.iterKey ? config.iterKey : iterFactors.length > 1 ? iterFactors[0] : ''
  const cols = keyPart.split(',')
    .map(col => col.trim())
    .filter(col => col)
    .map(col => {
      const parts = col.split('|')
      const value = parts[0]
      return { value, text: config.colorful ? useFilter(value, 'green') : value, filters: parts.slice(1) }
    })
  const rows = useFilter(useGet(data, iterKey), 'array').map(row => {
    return cols.map(col => {
      const value = useFilter(col.value.startsWith('/') ? useGet(data, col.value.slice(1)) : useGet(row, col.value), ...col.filters)
      return { value, text: config.colorful ? useFilter(value, 'blue') : value }
    })
  })

  if (config.format === 'list') {
    return rows.map(row => {
      return cols.map((col, i) => {
        return col.text + '\t' + row[i].text
      }).join('\n')
    }).join('\n------------\n')
  } else {
    const items = (config.format === 'th') ? [cols, ...rows] : [...rows]
    if (config.aligned) {
      const alignedItems = useFilter(items, ['align', 'value'])
      return alignedItems.map(row => row.map(e => e.text + ' '.repeat(e._align)).join('\t')).join('\n')
    } else {
      return items.map(row => row.map(e => e.text).join('\t')).join('\n')
    }
  }
}

// console.log(useJsonf({
//   data: {
//     foo: 'foo',
//     bar: {
//       bar: 'bar'
//     },
//     items: [
//       { name: 'foo', age: 10, date: new Date },
//       { name: 'foo2', age: 10, date: new Date },
//     ]
//   },
//   cols: 'items:/foo,/bar.bar,name,date|date'
// }))
