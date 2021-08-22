const Governance = artifacts.require("Governance");
const DTRUSTFactory = artifacts.require("DTRUSTFactory");
const ControlKey = artifacts.require("ControlKey");
const DTtoken = artifacts.require("DTtoken");
const PRtoken = artifacts.require("PRtoken");

module.exports = async function (deployer, network, accounts) {

    const manager = "0x1Bb0ebE711a73347ae2F2A765A06AfAfB14c9A93";

    deployer.deploy(Governance)
        .then((result) => {
            deployer.deploy(DTtoken, manager, result.address);
            result.registerDTtoken(DTtoken.address)
            deployer.deploy(DTRUSTFactory, result.address);
        })
        .then(() => deployer.deploy(PRtoken, manager))
        .then(() => deployer.deploy(ControlKey));

};
