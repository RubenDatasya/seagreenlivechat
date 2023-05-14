const getTimeStamp = (interval) => {
    const expirationTimeInSeconds = interval
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const privilegeExpired = currentTimestamp + expirationTimeInSeconds
    return privilegeExpired
}

const getCertificatesOptions = () => {
    var options = {
        token: {
          key: "./certs/AuthKey_K2B7NYR9XB.p8",
          keyId: "K2B7NYR9XB",
          teamId: "LVKN97J3GA"
        },
        production: false
      };
      return options;
}

module.exports =  {
    getTimeStamp,
    getCertificatesOptions
}