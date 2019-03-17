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

app.ports.toJs.subscribe(data => {
    console.log(data);
})
// Use ES2015 syntax and let Babel compile it for you
var testFn = (inp) => {
    let a = inp + 1;
    return a;
}
