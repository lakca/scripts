/* eslint-disable indent */

const getStyle = id =>  `
#${id} ul {
  padding: 0;
  margin: 0;
  list-style-type: none;
}
#${id} li {
  padding: 5px 0;
}
#${id} li li {
  margin-left: 2em;
}
#${id} .host {
  font-weight: bold;
  font-style: italic;
}
#${id} button {
  padding: 5px 10px;
  margin: 5px 10px;
  border-radius: 2px;
  border: none;
  cursor: pointer;
  background-color: #eee;
}
#${id} button[data-like=link] {
  border: none;
  background: none;
  padding: 0;
  margin: 0 2px;
  color: #1967d2;
}
`


module.exports = function({g, randomId, deleteElement}) {
  return function popup(gelements, options = {}) {
    const {
      destroy = true,
      closable = true,
      confirmable = false,
      overlay = true,
      style = ''
    } = options
    const id = 's' + randomId()
    const overlayStyle = `
    position: fixed;
    width: 100%;
    padding: 100%;
    left: 0;
    top: 0;
    z-index: 9999;
    background: rgba(0,0,0,0.2);
    `
    const modalStyle = `
    position: fixed;
    z-index: 9999;
    width: 500px;
    padding: 20px;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    background: white;
    border-radius: 4px;
    box-shadow: 5px 5px 20px grey;
    `
    const instance = {
      get id() { return id },
      root: g('div').id(id),
      show(gelementsReplacement) {
        if (gelementsReplacement) {
          this.root.node('content').el.innerHTML = ''
        }
        this.root.style({display: 'block'})
      }
    }
    instance.root.style(overlay ? overlayStyle : modalStyle)
      .down('div')
        .if(overlay)
        .style(modalStyle)
        .class('overlay')
      .down('div').key('content').class('content')
        .down(gelements)
        .down()
      .next('div').if(closable || confirmable).class('footer').style('margin-top: 20px; text-align: center;')
        .down('button')
          .if(closable)
          .text('关闭')
          .data('action', 'close')
          .on('click', () => destroy ? deleteElement(instance.root.el) : instance.root.style({display: 'none'}))
        .next('button')
          .if(confirmable)
          .text('确认')
          .data('action', 'confirm')
          .on('click', () => {})
        .down()
      .next('style').text(getStyle(id)).text(style(id))
      .start
    document.body.appendChild(instance.root.el)
    return instance
  }
}

