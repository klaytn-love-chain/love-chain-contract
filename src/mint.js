import mongoose from 'mongoose';
import dotenv from 'dotenv';
import FormData from 'form-data';
import fs from 'fs';

import lockJSON from './metadata.js';
import TokenModel from './model/tokens.js';
import { uploadAsset, uploadMetaData } from './kas.js';
import { mintWithTokenURI } from './caver.js';

dotenv.config();

export const mint = async () => {
  await mongoose.connect(process.env.DB_URL, { useNewUrlParser: true, dbName: 'LoveChain' });

  for await (const val of lockJSON) {
    const tokenId = val.edition;

    const formData = new FormData();
    formData.append('file', fs.createReadStream(`./build/images/${tokenId}.png`));
    const imgUrl = await uploadAsset(formData);
    if (!imgUrl) {
      console.log('이미지 업로드 실패');
      return;
    }

    const metadata = { ...val, image: imgUrl };
    const metadataURI = await uploadMetaData(JSON.stringify({ metadata }));
    if (!metadataURI) {
      console.log('메타데이터 업로드 실패');
      return;
    }

    const [background, oneLine, socialProfile, key, coupleImage, date] = val.attributes;

    const createTokenData = async () =>
      TokenModel.create({
        tokenId,
        lockImage: imgUrl,
        profileImage: {
          onePerson: null,
          twoPerson: null,
        },
        feature: {
          date: date.value !== 'null',
          oneLine: oneLine.value !== 'null',
          coupleImage: coupleImage.value !== 'null',
          socialProfile: socialProfile.value !== 'null',
        },
        options: {
          date: null,
          oneLine: null,
          coupleImage: null,
          socialProfile: {
            oneInstagram: null,
            twoInstagram: null,
            oneTwitter: null,
            twoTwitter: null,
            oneURL: null,
            twoURL: null,
          },
        },
        isPrivate: false,
        metaData: metadataURI,
      });

    const result = await Promise.all([createTokenData(), mintWithTokenURI(process.env.N_SEOUL_TOWER_MARKET_ADDRESS, tokenId, metadataURI)])
      .then(() => true)
      .catch(() => false);

    return result;
  }
};
