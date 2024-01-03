/**
 * 获取 s_v_web_id，生成后会存储在 cookie，作为 fp ，即指纹给登录api传递。
 * @returns
 */
function s_v_web_id() {
  const e = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('')
  const t = e.length
  const r = Date.now().toString(36)
  const n = []
  n[8] = n[13] = n[18] = n[23] = '_',
  n[14] = '4'
  for (let o = 0, i = void 0; o < 36; o++) {
    n[o] || (i = 0 | Math.random() * t,
    n[o] = e[o == 19 ? 3 & i | 8 : i])
  }
  return 'verify_' + r + '_' + n.join('')
}
