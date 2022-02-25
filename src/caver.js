import Caver from 'caver-js';
import dotenv from 'dotenv';

dotenv.config();

const option = {
  headers: [
    {
      name: 'Authorization',
      value: 'Basic ' + Buffer.from(process.env.KAS_ACCESS_KEY_ID + ':' + process.env.KAS_SECRET_ACCESS_KEY).toString('base64'),
    },
    { name: 'x-chain-id', value: process.env.MAIN_NET_CHAIN_ID },
  ],
};

const caver = new Caver(new Caver.providers.HttpProvider('https://node-api.klaytnapi.com/v1/klaytn', option));

const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
const account = caver.klay.accounts.wallet.add(deployerPrivateKey);

export const mintWithTokenURI = async (to, tokenId, URI) => {
  try {
    await caver.klay.sendTransaction({
      type: 'SMART_CONTRACT_EXECUTION',
      from: account.address,
      to: process.env.LOVE_CHAIN_ADDRESS,
      data: caver.klay.abi.encodeFunctionCall(
        {
          constant: false,
          inputs: [
            {
              name: 'to',
              type: 'address',
            },
            {
              name: 'tokenId',
              type: 'uint256',
            },
            {
              name: 'URI',
              type: 'string',
            },
          ],
          name: 'mintWithTokenURI',
          outputs: [
            {
              name: '',
              type: 'bool',
            },
          ],
          payable: false,
          stateMutability: 'nonpayable',
          type: 'function',
        },
        [to, tokenId, URI]
      ),
      gas: '5000000',
    });

    return true;
  } catch (e) {
    console.log(e);

    return false;
  }
};
