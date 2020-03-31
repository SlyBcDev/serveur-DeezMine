const Web3 = require("web3");
const thorify = require("thorify").thorify;
const { contract } = require("./config_contract");
const web3 = thorify(new Web3(), "https://vethor-node-test.vechaindev.com");

exports.web3 = thorify(new Web3(), "https://vethor-node-test.vechaindev.com");

exports.DeezMine = new web3.eth.Contract(contract.abi, contract.address);
