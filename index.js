const Web3 = require('web3');

// Ganache-da çalışan Ethereum node'unuza qoşulun
const web3 = new Web3('http://127.0.0.1:7545'); // Ganache'nin default RPC URL'si

async function getAccounts() {
    const accounts = await web3.eth.getAccounts();
    console.log('Accounts:', accounts);
}

getAccounts();
