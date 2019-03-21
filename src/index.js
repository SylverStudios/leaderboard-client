'use strict';

require("./styles.scss");

// Get value from a hidden input (how we communicate startup values to the elm app)
const getInitialValue = () => {
    const gameIdInput = document.getElementById("gameId");

    return { gameId: gameIdInput.value }
}

const initialValue = getInitialValue();


const { Elm } = require('./Main');
var app = Elm.Main.init({ node: document.querySelector('#scoreboard'), flags: initialValue });



// PORTS
// When you want to interop, just call this thing
app.ports.newScore.send(8);
