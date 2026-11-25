import { fahrenheit } from './temperature.mjs';

const input = document.querySelector('#celsius');
const output = document.querySelector('#fahrenheit');
function update() {
  const value = input.valueAsNumber;
  output.value = Number.isFinite(value) ? String(fahrenheit(value)) : '';
}
input.addEventListener('input', update);
update();
