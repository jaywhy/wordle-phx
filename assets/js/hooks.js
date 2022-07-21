let Hooks = {}

Hooks.BadWord = {
  mounted() {
    this.handleEvent("bad-word", ({ row }) => {
      const elm = document.getElementById(row)
      console.log("hello")
      console.log(elm.getAttribute("data-bad-word"))
      liveSocket.execJS(elm, elm.getAttribute("data-bad-word"))
    })
  }
}

export default Hooks
