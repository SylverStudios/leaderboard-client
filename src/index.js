'use strict';

require("./styles.scss");

// Get value from a hidden input (how we communicate startup values to the elm app)
const getInitialValue = () => {
  const gameIdInput = document.getElementById("gameId");

  return { gameId: gameIdInput.value, score: 80 }
}

const initialValue = getInitialValue();


const { Elm } = require('./Main');
var app = Elm.Main.init({ node: document.querySelector('#scoreboard'), flags: initialValue });

window.app = app;
// window.app.ports.show.send(false)

