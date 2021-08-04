const express = require('express');
const path = require('path');
const app = express();
const { createPokedexHtml } = require('./populatePokedex')

// share only the folders and files you need!
// you could also share a 'js' folder 
app.use('/css', express.static(path.join(__dirname, 'css')))

app.get("/", async function(req, res) {
    const pokemonHtml = await createPokedexHtml()
    console.log('responding to /')
    res.send(pokemonHtml)
});

const activePort = 3000
app.listen(activePort, () => {
    console.log(`Node server is running on port ${activePort}...`);
});
