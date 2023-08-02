const plugin = require('tailwindcss/plugin')
const Color = require('color')

const log = console.log
console.log = function (...args) {
  log.apply(this, ['\x1b[32m', ...args, '\x1b[0m'])
}

/**
 * @returns {any}
 */
function apply (...args) {
  const kv = {}
  let str = ''
  for (const arg of args) {
    if (typeof arg === 'object') {
      Object.assign(kv, arg)
    } else {
      str += ' ' + arg
    }
  }
  kv['@apply ' + str.replace(/\s+/g, ' ').trim()] = {}
  return kv
}

function useTheme (theme, parentPath, prop, defaultValue) {
  return (prop ? theme([`${parentPath}.${prop}`.replace(/-/g, '.')].join('.')) || prop : null) || defaultValue
}

function extractModifier (modifier, ...mapping) {
  return (modifier || '').split(',').map((e, i) => mapping[i] ? mapping[i](e) : e)
}

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['**/*.{html,js}'],
  prefix: 'twx-',
  corePlugins: {
    preflight: false
  },
  themes: {
    colors: {
      // primary: '#4338ca'
    }
  },
  plugins: [
    plugin(function ({ matchUtilities, theme }) {
      const useThemeLocal = useTheme.bind(null, theme)
      matchUtilities(
        {
          theme: (value, { modifier }) => {
            switch (value) {
              case 'button':
              case 'button-primary': {
                const [color] = extractModifier(modifier, v => useThemeLocal('colors', v))
                return apply(`
                twx-text-[${Color(color).luminosity() > 0.9 ? useThemeLocal('colors', 'gray-900') : 'white'}]
                twx-bg-[${color}]
                hover:twx-bg-[${Color(color).darken(0.1).hex()}]
                focus-visible:twx-outline-[${color}]
                `)
              }
              case 'button-handle': {
                const [color] = extractModifier(modifier, v => useThemeLocal('colors', v))
                return apply(`
                    twx-text-[${Color(color).luminosity() > 0.9 ? useThemeLocal('colors', 'gray-800') : 'white'}]
                    twx-bg-[${color}]
                    twx-border-[${color}]
                  `
                )
              }
            }
          }
        },
        {
          values: {
            button: 'button',
            'button-primary': 'button-primary',
            'button-handle': 'button-handle'
          },
          modifiers: {
            plain: '#ffffff',
            primary: '#007aff',
            close: '#FF605C',
            minimize: '#FFBD44',
            maximize: '#00CA4E'
          }
        }
      )
    })
  ]
}
