const fs = require('fs').promises;
const fetch = require("node-fetch");

async function readPokemonTemplate() {
    console.log('readPokemonTemplate: loading template')
    let pokeHtml;

    try {
        pokeHtml = await fs.readFile('/app/pokedexTemplate.html', 'utf-8');
    } catch (err) {
        console.log(`Error loading template: err=${err}`);
    }

    return pokeHtml;
}

async function readPokemonList() {
    let pokeList = [];

    try {
        pokeList = JSON.parse(await fs.readFile('/app/pokemon.json', 'utf-8'));
    } catch (err) {
        console.log(err);
    }

    return pokeList;
}

async function getPokemonInformation(pokemon) {
    console.log(`getPokemonInformation: fetching pokemon=${pokemon}`)
    const res = await fetch(`https://pokeapi.co/api/v2/pokemon/${pokemon}`);
    const data = await res.json();

    const pokedexEntry = {
        name: pokemon,
        id: data.id,
        type: data.types.map((type) => type.type.name.charAt(0).toUpperCase() + type.type.name.slice(1)).join('/'),
    };
    return pokedexEntry;
}

async function retrieveAndSortPokemonInformation(pokemonList) {
    console.log('retrieveAndSortPokemonInformation: fetching pokemon list')
    const pokemonInformation = await Promise.all(
        pokemonList.map(
            (pokemon) => getPokemonInformation(pokemon),
        ),
    );
    pokemonInformation.sort((pokemon1, pokemon2) => pokemon1.id - pokemon2.id);

    console.log(`retrieveAndSortPokemonInformation: pokemonInformation=${pokemonInformation.toString()}`)
    return pokemonInformation;
}

function createPokemonHTML(pokeInfo) {
    console.log('createPokemonHTML: rendering pokemon html')
    const pokeHtml = pokeInfo.map((pokemon) => `<div id="pokemon-${pokemon.id}"><p><b>Name:</b> ${pokemon.name}</p><p><b>ID:</b> #${pokemon.id}</p><p><b>Type: </b>${pokemon.type}</p><img height=100px src=https://pokeres.bastionbot.org/images/pokemon/${pokemon.id}.png/></div><hr class=divider height=10px style='color:grey' />`).join('');
    return pokeHtml;
}

async function createPokedexHtml() {
    console.log('createPokedexHtml: reading pokemon list')
    const pokemonList = await readPokemonList();

    console.log('createPokedexHtml: fetching pokemon list')
    const pokemonData = await retrieveAndSortPokemonInformation(pokemonList);

    console.log('createPokedexHtml: render pokemon')
    const pokemonListTemplate = createPokemonHTML(pokemonData);

    console.log('createPokedexHtml: loading template')
    const pokemonPageTemplate = await readPokemonTemplate();

    console.log('createPokedexHtml: rendering template')
    const pokemonPage = pokemonPageTemplate.replace('${template}', pokemonListTemplate)

    return pokemonPage
}

module.exports = {
    createPokedexHtml
}
