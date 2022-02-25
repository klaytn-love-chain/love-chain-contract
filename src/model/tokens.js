import mongoose from 'mongoose';

const ProfileImageSchema = new mongoose.Schema({
  onePerson: {
    type: String,
    default: null,
  },
  twoPerson: {
    type: String,
    default: null,
  },
});

const SocialProfileSchema = new mongoose.Schema({
  oneInstagram: {
    type: String,
    default: null,
  },
  twoInstagram: {
    type: String,
    default: null,
  },
  oneTwitter: {
    type: String,
    default: null,
  },
  twoTwitter: {
    type: String,
    default: null,
  },
  oneURL: {
    type: String,
    default: null,
  },
  twoURL: {
    type: String,
    default: null,
  },
});

const FeatureSchema = new mongoose.Schema({
  date: Boolean,
  oneLine: Boolean,
  coupleImage: Boolean,
  socialProfile: Boolean,
});

const OptionsSchema = new mongoose.Schema({
  date: {
    type: String,
    default: null,
  },
  oneLine: {
    type: String,
    default: null,
  },
  coupleImage: {
    type: String,
    default: null,
  },
  socialProfile: {
    type: SocialProfileSchema,
    default: null,
  },
});

const TokenSchema = new mongoose.Schema({
  tokenId: {
    type: String,
    unique: true,
    required: true,
  },
  lockImage: String,
  profileImage: {
    type: ProfileImageSchema,
  },
  feature: {
    type: FeatureSchema,
    required: true,
  },
  options: {
    type: OptionsSchema,
  },
  isPrivate: {
    type: Boolean,
    required: true,
  },
  metaData: {
    type: String,
    required: true,
  },
});

export default mongoose.model('tokens', TokenSchema);
