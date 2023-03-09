/**
 * @template T, P
 * @template {{page: number, size: number, _: number}} K
 * @param {T} params
 * @param {P} defaultParams
 * @return { 0 extends (1 & T) ? K & Record<string, unknown> & P : T & K & P }
 */
function getRequestParams(params, defaultParams = {}) {
  const param = params || {}
  Object.assign(param, defaultParams)
  param.page = param.page || defaultParams.page || 1
  param.size = param.size || defaultParams.size || 20
  param._ = param._ || defaultParams._ || Date.now()
  return param
}

module.exports = {
  getRequestParams,
}
