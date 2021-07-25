const DTRUST = artifacts.require("DTRUST");

module.exports = async function (deployer) {

    deployer.deploy(DTRUST, "", "", "", "0xc42a2CD1C3783a7438E774Cfb82048827b894e21").then(() => {
        console.log(DTRUST.address);
    });
};
