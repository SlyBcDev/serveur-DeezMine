const express = require("express");
const { web3 } = require("./contract_instance");
const { contract } = require("./config_contract");
const { DeezMine } = require("./contract_instance");

const app = express();

const port = 3000;

app.get("/", (req, res) => {
  res.send("Hello world");
});

app.get("/contractAddress", (req, res) => {
  res.send(contract.address);
});

app.get("/instrumentAbi", (req, res) => {
  res.send(contract.abi[25]);
});

app.get("/instrument/:id", async (req, res) => {
  let result = await DeezMine.methods.instrument(`${req.params.id}`).call();
  res.send(result);
});

app.get("/block", async (req, res) => {
  let result = await web3.eth.getBlockRef();
  res.send(result);
});

app.listen(port, () => {
  console.log(`App listen on port ${port}`);
});
