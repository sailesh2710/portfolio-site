import { APP_BASE_HREF } from '@angular/common';
import { CommonEngine } from '@angular/ssr';
import express from 'express';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import bootstrap from './dist/portfolio/server/main.server';

// Express app factory
export function app(): express.Express {
  const server = express();

  // Points to: dist/portfolio/server
  const serverDistFolder = dirname(fileURLToPath(import.meta.url));

  // Points to: dist/portfolio/browser
  const browserDistFolder = resolve(serverDistFolder, '../browser');

  // Location of the SSR template
  const indexHtml = join(serverDistFolder, 'index.server.html');

  const commonEngine = new CommonEngine();

  server.set('view engine', 'html');
  server.set('views', browserDistFolder);

  // Serve static Angular browser files
  server.get('*.*', express.static(browserDistFolder, {
    maxAge: '1y'
  }));

  // Handle all SSR-rendered routes
  server.get('*', (req, res, next) => {
    const { protocol, originalUrl, baseUrl, headers } = req;

    commonEngine
      .render({
        bootstrap,
        documentFilePath: indexHtml,
        url: `${protocol}://${headers.host}${originalUrl}`,
        publicPath: browserDistFolder,
        providers: [{ provide: APP_BASE_HREF, useValue: baseUrl }],
      })
      .then((html) => res.send(html))
      .catch((err) => next(err));
  });

  return server;
}

function run(): void {
  // Elastic Beanstalk MUST use port 8080
  const port = process.env.PORT || 8080;

  const server = app();
  server.listen(port, () => {
    console.log(`✔ Angular SSR server running on port ${port}`);
  });
}

// Only run when not in AWS Lambda/serverless
run();