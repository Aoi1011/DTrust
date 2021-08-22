const Governance = artifacts.require("Governance");
const DTRUSTFactory = artifacts.require("DTRUSTFactory");
const ControlKey = artifacts.require("ControlKey");
const DTtoken = artifacts.require("DTtoken");
const PRtoken = artifacts.require("PRtoken");

module.exports = async function (deployer, network, accounts) {

    deployer.deploy(DTtoken).then(() => {
        console.log(DTtoken.address);
    });

    deployer.deploy(PRtoken).then(() => {
        console.log(PRtoken.address);
    })

    deployer.deploy(Governance).then(() => {
        console.log(Governance.address);
    });

    deployer.deploy(DTRUSTFactory).then(() => {
        console.log(DTRUSTFactory.address);
    });

    deployer.deploy(ControlKey).then(() => {
        console.log(ControlKey.address);
    });

};
