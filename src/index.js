import dotenv from 'dotenv';
import { mint } from './mint';

dotenv.config();

try {
  mint();
} catch (e) {
  console.log(e);
}
