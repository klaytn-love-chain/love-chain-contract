import dotenv from 'dotenv';
import { mint } from './mint.js';

dotenv.config();

try {
  mint();
} catch (e) {
  console.log(e);
}
