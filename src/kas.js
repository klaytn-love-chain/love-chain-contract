import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const option = {
  headers: {
    Authorization: 'Basic ' + Buffer.from(process.env.KAS_ACCESS_KEY_ID + ':' + process.env.KAS_SECRET_ACCESS_KEY).toString('base64'),
    'x-chain-id': process.env.MAIN_NET_CHAIN_ID,
    'Content-Type': 'application/json',
  },
};

export const uploadAsset = async (formData) => {
  try {
    const response = await axios.post('https://metadata-api.klaytnapi.com/v1/metadata/asset', formData, {
      headers: {
        Authorization: 'Basic ' + Buffer.from(process.env.KAS_ACCESS_KEY_ID + ':' + process.env.KAS_SECRET_ACCESS_KEY).toString('base64'),
        'x-chain-id': process.env.TEST_NET_CHAIN_ID,
        'Content-Type': 'multipart/form-data; boundary=' + formData.getBoundary(),
      },
    });
    return response.data.uri;
  } catch (e) {
    console.error(e);
    return false;
  }
};

export const uploadMetaData = async (metadataJSON) => {
  try {
    const response = await axios.post('https://metadata-api.klaytnapi.com/v1/metadata', metadataJSON, option);
    return response.data.uri;
  } catch (e) {
    console.error(e);
    return false;
  }
};
