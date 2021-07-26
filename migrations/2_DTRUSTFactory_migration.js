const DTRUSTFactory = artifacts.require("DTRUSTFactory");
const DTRUST = artifacts.require("DTRUST");

module.exports = async function (deployer) {

    deployer.deploy(DTRUSTFactory).then(() => {
        console.log(DTRUSTFactory.address);
    });
};
