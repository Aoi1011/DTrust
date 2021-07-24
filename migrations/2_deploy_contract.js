const DTrust = artifacts.require("DTRUST");

module.exports = function (deployer) {

    deployer.deploy(DTrust, "DTRUST", "DT", "", "0x09F9436E7e554bbe4B8B3265707441050A008B9b");
};
