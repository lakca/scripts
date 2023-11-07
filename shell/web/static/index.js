const { nextTick, ref: Ref } = Vue
const app = Vue.createApp({
  data() {
    return {
      ws: null,
      opacity: 100,
      loadingSearch: false,
      selectOptions: [],
      selection: null,
      message: 'naive',
      feature: {
        quote: true,
        highlight: true,
        highlightBK: true
      },
      symbols: ['sh000001', 'sh600352', 'sh603706', 'sz002671', 'sh512480'],
      alertRules: {},
      alertTypes: [
        { value: 'hc', label: '价格>=', suffix: '' },
        { value: 'lc', label: '价格<=', suffix: '' },
        { value: 'hp', label: '幅度>=', suffix: '%' },
        { value: 'lp', label: '幅度<=', suffix: '%' }
      ],
      shownEditAlertRulesModal: false,
      formEditAlertRulesModel: { symbol: null, name: null, items: [] },
      oldData: null,
      data: null,
      columns: [
        { key: 'symbol', className: 'symbol', title: '代码', width: 100, render(rowData) { return rowData.symbol?.toUpperCase() } },
        {
          key: 'name',
          className: 'name',
          title: '证券',
          width: 100,
          render(rowData) {
            return h('a', { href: `https://www.xueqiu.com/S/${rowData.symbol}`, target: '_blank' }, rowData.name)
          }
        },
        {
          key: 'percent_',
          className: 'percent_',
          align: 'center',
          title: '涨幅',
          width: 160,
          render: (rowData) => {
            return h('div', { class: 'flex flex-col items-center' }, [
              h('span', { class: 'high-percent opacity-75' }, rowData.highPercent),
              h('span', { class: 'flex items-center' }, [
                h('span', { class: 'open-percent opacity-50' }, rowData.openPercent),
                h('NDivider', { vertical: true }),
                h('span', { class: 'percent' }, rowData.percent)
              ]),
              h('span', { class: 'low-percent opacity-75' }, rowData.lowPercent)
            ])
          }
        },
        {
          key: 'price_',
          className: 'price_',
          align: 'center',
          title: '价格',
          width: 160,
          render: (rowData) => {
            return h('div', { class: 'flex flex-col items-center' }, [
              h('span', { class: 'high-price opacity-75' }, rowData.high),
              h('span', { class: 'flex items-center' }, [
                h('span', { class: 'open-price opacity-50' }, rowData.open),
                h('NDivider', { vertical: true }),
                h('span', { class: 'price' }, rowData.price)
              ]),
              h('span', { class: 'low-price opacity-75' }, rowData.low)
            ])
          }
        },
        { key: 'time', className: 'time', title: '时间', width: 88 },
        {
          key: 'alert',
          className: 'alert',
          title: '预警',
          render: rowData => {
            const rules = this.alertRules[rowData.symbol] || []
            return rules.map(rule => h('NTag', { class: 'm-1 cursor-pointer', bordered: false, round: true, type: rule.checked ? 'info' : 'default', onClick: () => rule.checked = !rule.checked },
              () => {
                const cfg = this.alertTypes.find(t => t.value === rule.type)
                return `${cfg?.label}${rule.value}${cfg.suffix}`
              }))
              .concat([h('NButton', { type: 'info', text: true, onClick: () => this.showEditAlertRulesModal(rowData.symbol, rowData.name) }, () => '编辑')])
          }
        },
        {
          key: 'action',
          className: 'action',
          title: '操作',
          render: (rowData) => {
            return h('NButton', { onClick: () => this.deleteSymbol(rowData.symbol), text: true, color: 'red' }, () => '删除')
          }
        }
      ],
      highlightData: [],
      highlightBKData: [],
      dropdownOptions: [
        { label: '编辑', key: 'edit' },
        { label: '删除', key: 'delete' }
      ],
      shownDropdown: false,
      cursor: [0, 0],
      row: null
    }
  },
  computed: {
    rows() {
      return this.symbols.map(symbol => this.data && this.data[symbol] || { symbol })
    },
    highlightDataList() {
      const list = [[], [], []]
      const num = Math.ceil(this.highlightData.length / list.length)
      return list.map((e, i) => this.highlightData.slice(num * i, num * i + num))
    }
  },
  methods: {
    makeSortable() {
      new Sortable(this.$refs.table.$el.querySelector('.n-data-table-tbody'), {
        draggable: '.n-data-table-tr',
        onEnd: e => {
          if (e.oldIndex !== e.newIndex) {
            const arr = this.symbols.splice(e.oldIndex, 1)
            this.symbols.splice(e.newIndex, 0, arr[0])
          }
        }
      })
    },
    toggleFeature(feature, checked) {
      this.feature[feature] = checked
      switch (feature) {
        case 'quote':
          checked ? this.send({ type: 'begin', action: 'quote', data: { symbol: this.symbols } }) : this.send({ type: 'end', action: 'quote', data: { symbol: this.symbols } })
          break
        case 'highlight':
          checked ? this.send({ type: 'begin', action: 'highlight' }) : this.send({ type: 'end', action: 'highlight' })
          break
        case 'highlightBK':
          checked ? this.send({ type: 'begin', action: 'highlightBK' }) : this.send({ type: 'end', action: 'highlightBK' })
          break
        default:
      }
    },
    deleteSymbol(symbol) {
      this.symbols = this.symbols.filter(e => e !== symbol)
      naive.useMessage().info('删除！')
    },
    editAlertRules() {
      const { symbol, items } = this.formEditAlertRulesModel
      this.alertRules[symbol] = items
    },
    showEditAlertRulesModal(symbol, name) {
      this.shownEditAlertRulesModal = true
      this.formEditAlertRulesModel.symbol = symbol
      this.formEditAlertRulesModel.name = name
      this.formEditAlertRulesModel.items = copy(this.alertRules[symbol] || [])
    },
    hideEditAlertRulesModal() {
      this.shownEditAlertRulesModal = false
    },
    addFormEditAlertRulesItem() {
      this.formEditAlertRulesModel.items.push({ type: 'lp', value: 0, checked: true })
    },
    removeFormEditAlertRulesItem(index) {
      this.formEditAlertRulesModel.items.splice(index, 1)
    },
    createWs() {
      const ws = window.ws = this.ws = new WebSocket((location.protocol === 'https:' ? 'wss' : 'ws') + `://${location.host}/ws`)
      ws.onclose = () => setTimeout(() => this.createWs(), 3000)
      ws.onmessage = (msg) => this.onmessage(msg)
      ws.onopen = () => {
        this.toggleFeature('quote', this.feature.quote)
        this.toggleFeature('highlight', this.feature.highlight)
        this.toggleFeature('highlightBK', this.feature.highlightBK)
      }
    },
    send(data) {
      this.ws && this.ws.readyState === this.ws.OPEN && this.ws.send(JSON.stringify(data))
    },
    onmessage(msg) {
      const data = JSON.parse(msg.data)
      switch (data.action) {
        case 'quote':
          data.data.forEach(e => {
            e.current = e.price
            e.ratio = (e.price - e.close) / e.price
            e.percent = percentText(e.ratio)
            e.openPercent = percentText(e.open, e.close)
            e.lowPercent = percentText(e.low, e.close)
            e.highPercent = percentText(e.high, e.close)
          })
          this.data = arr2obj(data.data, 'symbol')
          break
        case 'highlight':
          data.data?.forEach(e => {
            e.percent = percentText(e.ratio)
          })
          this.highlightData = data.data || []
          break
        case 'highlightBK':
          data.data?.forEach(e => {
            e.percent = percentText(e.ratio)
            e.inflowText = getFlowText(e.inflow, 1)
          })
          this.highlightBKData = data.data || []
          break
        default:
      }
      if (!isTrading()) {
        this.toggleFeature(data.action, false)
      }
    },
    getRowClassName(rowData) {
      const cls = ['row']
      cls.push(['high-down', 'high-equal', 'high-up'][compare(rowData.high, rowData.close) + 1])
      cls.push(['low-down', 'low-equal', 'low-up'][compare(rowData.low, rowData.close) + 1])
      cls.push(['open-down', 'open-equal', 'open-up'][compare(rowData.open, rowData.close) + 1])
      cls.push(['change-down', 'change-equal', 'change-up'][compare(rowData.price, rowData.close) + 1])
      cls.push(['price-down', 'price-equal', 'price-up'][compare(rowData.price, this.oldData?.[rowData.symbol]?.price) + 1])
      return cls.join(' ')
    },
    getItemClassName(rowData) {
      const cls = ['row']
      cls.push(['highlight-down', 'highlight-equal', 'highlight-up'][rowData.dir + 1])
      cls.push(['change-down', 'change-equal', 'change-up'][rowData.dir + 1])
      return cls.join(' ')
    },
    getBKItemClassName(rowData) {
      const cls = ['row']
      cls.push(['highlight-down', 'highlight-equal', 'highlight-up'][compare(rowData.ratio) + 1])
      cls.push(['change-down', 'change-equal', 'change-up'][compare(rowData.ratio) + 1])
      cls.push(['flow-down', 'flow-equal', 'flow-up'][compare(rowData.inflow) + 1])
      return cls.join(' ')
    },
    handleRowProps(row) {
      return {
        onContextmenu: e => {
          e.preventDefault()
          this.row = row
          this.shownDropdown = false
          nextTick().then(() => {
            this.shownDropdown = true
            this.cursor = [e.clientX, e.clientY]
          })
        }
      }
    },
    handleClickContextmenu(key) {
      if (key === 'delete' && this.row) this.deleteSymbol(this.row.symbol)
      this.shownDropdown = false
    },
    async handleSearch(q) {
      this.loadingSearch = true
      try {
        const res = await fetch(`/s/search?q=${q}`).then(res => res.json())
        this.selectOptions = res.map(e => ({
          label: e.name,
          value: e.symbol
        }))
      } finally {
        this.loadingSearch = false
      }
    }
  },
  watch: {
    opacity(val) {
      document.body.style.opacity = val / 100
    },
    selection(val, oldVal) {
      if (!this.symbols.includes(val)) {
        this.symbols.push(val)
      }
    },
    data(val, oldVal) {
      this.oldData = oldVal
      if (val) {
        for (const symbol of this.symbols) {
          alert(val[symbol], this.alertRules[symbol], oldVal && oldVal[symbol])
        }
      }
    },
    symbols: {
      deep: true,
      handler(val) {
        setStorage('quote:symbols', this.symbols)
        this.toggleFeature('quote', true)
      }
    },
    alertRules: {
      deep: true,
      handler(val) {
        setStorage('quote:alertRules', this.alertRules)
      }
    }
  },
  mounted() {
    this.createWs()
    this.makeSortable()
    const symbols = getStorage('quote:symbols')
    const alertRules = getStorage('quote:alertRules')
    if (symbols) {
      this.symbols = symbols
    } else if (this.symbols) {
      setStorage('quote:symbols', this.symbols)
    }
    if (alertRules) {
      this.alertRules = alertRules
    } else if (this.alertRules) {
      setStorage('quote:alertRules', this.alertRules)
    }
    window.addEventListener('storage', e => {
      if (e.key === 'quote:symbols') {
        this.symbols = getStorage('quote:symbols')
      }
    })
  }
})
app.use(naive)
const root = app.mount('#app')
