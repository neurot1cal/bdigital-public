// Serve only the starter's public files on the local machine.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';

const files = new Map([
  ['/', ['index.html', 'text/html']],
  ['/app.mjs', ['app.mjs', 'text/javascript']],
  ['/temperature.mjs', ['temperature.mjs', 'text/javascript']],
]);
createServer(async (request, response) => {
  const file = files.get(request.url.split('?')[0]);
  if (!file) return response.writeHead(404).end();
  try {
    const bytes = await readFile(new URL('./public/' + file[0], import.meta.url));
    response.writeHead(200, { 'Content-Type': file[1] }).end(bytes);
  } catch {
    response.writeHead(500).end('Could not read the requested file.');
  }
}).listen(8080, '127.0.0.1', () => console.log('Open http://127.0.0.1:8080'));
